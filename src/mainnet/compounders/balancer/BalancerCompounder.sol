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
                                                                             
//  _____     _                     _____                             _         
// | __  |___| |___ ___ ___ ___ ___|     |___ _____ ___ ___ _ _ ___ _| |___ ___ 
// | __ -| .'| | .'|   |  _| -_|  _|   --| . |     | . | . | | |   | . | -_|  _|
// |_____|__,|_|__,|_|_|___|___|_| |_____|___|_|_|_|  _|___|___|_|_|___|___|_|  
//                                                 |_|                          

// Github - https://github.com/FortressFinance

import "src/shared/compounders/AMMCompounderBase.sol";
import "src/mainnet/utils/BalancerOperations.sol";

contract BalancerCompounder is BalancerOperations, AMMCompounderBase {
    
    using SafeERC20 for IERC20;

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
        address[] memory _underlyingAssets
        )
        AMMCompounderBase(
            _asset,
            _name,
            _symbol,
            _owner,
            _platform,
            _swap,
            address(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234), // Aura Booster
            IConvexBooster(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234).poolInfo(_boosterPoolId).crvRewards,
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets
        ) {}

    /********************************** Internal Functions **********************************/

    function _swapFromUnderlying(address _underlyingAsset, uint256 _underlyingAmount, uint256 _minAmount) internal override returns (uint256 _assets) {
        _assets = _addLiquidity(address(asset), _underlyingAsset, _underlyingAmount);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();
    }

    function _swapToUnderlying(address _underlyingAsset, uint256 _assets, uint256 _minAmount) internal override returns (uint256 _underlyingAmount) {
        _underlyingAmount = _removeLiquidity(address(asset), _underlyingAsset, _assets);
        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();
    }

    function _harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) internal override returns (uint256 _rewards) {
        
        IConvexBasicRewards(crvRewards).getReward();

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
            address _lpToken = address(asset);
            _rewards = _addLiquidity(_lpToken, _underlyingAsset, _rewards);
        
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
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

            IConvexBooster(booster).deposit(boosterPoolId, _rewards, true);

            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    receive() external payable {}
}