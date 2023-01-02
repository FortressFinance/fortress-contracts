// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
                             
//  _____                 _____     _   _ _____                             _         
// |     |_ _ ___ _ _ ___|  _  |___| |_|_|     |___ _____ ___ ___ _ _ ___ _| |___ ___ 
// |   --| | |  _| | | -_|     |  _| . | |   --| . |     | . | . | | |   | . | -_|  _|
// |_____|___|_|  \_/|___|__|__|_| |___|_|_____|___|_|_|_|  _|___|___|_|_|___|___|_|  
//                                                       |_|                          

// Github - https://github.com/FortressFinance

import "src/shared/compounders/AMMCompounderBase.sol";
import "src/arbitrum/utils/CurveArbiOperations.sol";

import "src/arbitrum/interfaces/IConvexBoosterArbi.sol";
import "src/arbitrum/interfaces/IConvexBasicRewardsArbi.sol";

contract CurveArbiCompounder is CurveArbiOperations, AMMCompounderBase {
    
    using SafeERC20 for IERC20;

    /// @notice The address of the vault's Curve pool.
    address private immutable poolAddress;
    /// @notice The internal type of pool, used in CurveOperations.
    uint256 private immutable poolType;
    /// @notice The address of CRV token.
    address private constant CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;

    /********************************** Constructor **********************************/

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _owner,
        address _platform,
        address _swap,
        uint256 _boosterPoolId,
        address[] memory _rewardAssets,
        address[] memory _underlyingAssets,
        uint256 _poolType
        )
        AMMCompounderBase(
            _asset,
            _name,
            _symbol,
            _owner,
            _platform,
            _swap,
            address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Booster
            IConvexBoosterArbi(0xF403C135812408BFbE8713b5A23a04b3D48AAE31).poolInfo(_boosterPoolId).rewards,
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets
        ) {
            poolType = _poolType;
            poolAddress = metaRegistry.get_pool_from_lp_token(address(_asset));
    }

    /********************************** View Functions **********************************/

    /// @notice See {AMMConcentratorBase - isPendingRewards}
    function isPendingRewards() external override view returns (bool) {
        return IConvexBasicRewardsArbi(crvRewards).claimable_reward(CRV, address(this)) > 0;
    }

    /********************************** Internal Functions **********************************/

    function _depositStrategy(uint256 _assets, bool _transfer) internal override {
        if (_transfer) IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);
        IConvexBoosterArbi(booster).deposit(boosterPoolId, _assets);
    }

    function _withdrawStrategy(uint256 _assets, address _receiver, bool _transfer) internal override {
        IConvexBasicRewardsArbi(crvRewards).withdraw(_assets, false);
        if (_transfer) IERC20(address(asset)).safeTransfer(_receiver, _assets);
    }

    function _swapFromUnderlying(address _underlyingAsset, uint256 _underlyingAmount, uint256 _minAmount) internal override returns (uint256 _assets) {
        _assets = _addLiquidity(poolAddress, poolType, _underlyingAsset, _underlyingAmount);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();
    }

    function _swapToUnderlying(address _underlyingAsset, uint256 _assets, uint256 _minAmount) internal override returns (uint256 _underlyingAmount) {
        _underlyingAmount = _removeLiquidity(poolAddress, poolType, _underlyingAsset, _assets);
        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();
    }

    function _harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) internal override returns (uint256 _rewards) {
        
        IConvexBasicRewardsArbi(crvRewards).getReward(address(this));
        
        address _rewardAsset;
        address _swap = swap;
        address[] memory _rewardAssets = rewardAssets;
        for (uint256 i = 0; i < _rewardAssets.length; i++) {
            _rewardAsset = _rewardAssets[i];
            
            if (_rewardAsset != _underlyingAsset) {
                if (_rewardAsset == ETH) {
                    // slither-disable-next-line arbitrary-send-eth
                    IFortressSwap(_swap).swap{ value: address(this).balance }(_rewardAsset, _underlyingAsset, address(this).balance);
                } else {
                    uint256 _balance = IERC20(_rewardAsset).balanceOf(address(this));
                    if (_balance > 0) {
                        IFortressSwap(_swap).swap(_rewardAsset, _underlyingAsset, _balance);
                    }
                }
            }
        }

        if (_underlyingAsset == ETH) {
            _rewards = address(this).balance;
        } else {
            _rewards = IERC20(_underlyingAsset).balanceOf(address(this));
        }

        if (_rewards > 0) {
            _rewards = _addLiquidity(poolAddress, poolType, _underlyingAsset, _rewards);
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
            address _lpToken = address(asset);
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(_lpToken).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();
                _rewards = _rewards - _harvestBounty;
                IERC20(_lpToken).safeTransfer(_receiver, _harvestBounty);
            }

            IConvexBoosterArbi(booster).deposit(boosterPoolId, _rewards);

            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    receive() external payable {}
}