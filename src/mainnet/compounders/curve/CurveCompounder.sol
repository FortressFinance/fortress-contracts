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

//  _____                 _____                             _         
// |     |_ _ ___ _ _ ___|     |___ _____ ___ ___ _ _ ___ _| |___ ___ 
// |   --| | |  _| | | -_|   --| . |     | . | . | | |   | . | -_|  _|
// |_____|___|_|  \_/|___|_____|___|_|_|_|  _|___|___|_|_|___|___|_|  
//                                       |_|                          

// Github - https://github.com/FortressFinance

import "src/shared/compounders/AMMCompounderBase.sol";
import "src/mainnet/utils/CurveOperations.sol";

contract CurveCompounder is CurveOperations, AMMCompounderBase {
    
    using SafeERC20 for IERC20;

    /// @notice The address of the vault's Curve pool.
    address private immutable poolAddress;
    /// @notice The internal type of pool, used in CurveOperations.
    uint256 private immutable poolType;
    
    /********************************** Constructor **********************************/

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        string memory _description,
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
            _description,
            _owner,
            _platform,
            _swap,
            address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Booster
            IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31).poolInfo(_boosterPoolId).crvRewards,
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets
        ) {
            poolType = _poolType;
            poolAddress = metaRegistry.get_pool_from_lp_token(address(_asset));
    }

    /********************************** Internal Functions **********************************/

    function _swapFromUnderlying(address _underlyingAsset, uint256 _underlyingAmount, uint256 _minAmount) internal override returns (uint256 _assets) {
        _assets = _addLiquidity(poolAddress, poolType, _underlyingAsset, _underlyingAmount);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();
    }

    function _swapToUnderlying(address _underlyingAsset, uint256 _assets, uint256 _minAmount) internal override returns (uint256 _underlyingAmount) {
        _underlyingAmount = _removeLiquidity(poolAddress, poolType, _underlyingAsset, _assets);
        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();
    }

    function _harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) internal override returns (uint256 _rewards) {
        Booster memory _boosterData = boosterData;

        IConvexBasicRewards(_boosterData.crvRewards).getReward();

        Settings memory _settings = settings;
        address _rewardAsset;
        address _swap = _settings.swap;
        address[] memory _rewardAssets = _boosterData.rewardAssets;
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

            Fees memory _fees = fees;
            uint256 _platformFee = _fees.platformFeePercentage;
            uint256 _harvestBounty = _fees.harvestBountyPercentage;
            address _lpToken = address(asset);
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(_lpToken).safeTransfer(_settings.platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();
                _rewards = _rewards - _harvestBounty;
                IERC20(_lpToken).safeTransfer(_receiver, _harvestBounty);
            }

            IConvexBooster(_boosterData.booster).deposit(_boosterData.boosterPoolId, _rewards, true);

            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    receive() external payable {}
}