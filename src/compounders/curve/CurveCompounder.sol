// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/utils/CurveOperations.sol";
import "src/compounders/AMMCompounderBase.sol";

contract CurveCompounder is CurveOperations, AMMCompounderBase {
    
    using SafeERC20 for IERC20;

    /// @notice The address of the underlying Curve pool.
    address public poolAddress;
    /// @notice The type of the pool, used in CurveOperations.
    uint256 public poolType;
    
    /********************************** Constructor **********************************/

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
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
            _platform,
            _swap,
            address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Booster
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets
        ) {
            poolType = _poolType;
            poolAddress = metaRegistry.get_pool_from_lp_token(address(asset));
    }

    /********************************** Mutated Functions **********************************/

    /// @notice See {AMMCompounderBase - depositSingleUnderlying}
    function depositSingleUnderlying(uint256 _underlyingAmount, address _underlyingAsset, address _receiver, uint256 _minAmount) external payable override nonReentrant returns (uint256 _shares) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (!(_underlyingAmount > 0)) revert ZeroAmount();
        
        if (msg.value > 0) {
            if (msg.value != _underlyingAmount) revert InvalidAmount();
            if (_underlyingAsset != ETH) revert InvalidAsset();
        } else {
            IERC20(_underlyingAsset).safeTransferFrom(msg.sender, address(this), _underlyingAmount);
        }

        uint256 _assets = _addLiquidity(poolAddress, poolType, _underlyingAsset, _underlyingAmount);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();
        
        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);
        
        return _shares;
    }

    /// @notice See {AMMCompounderBase - redeemSingleUnderlying}
    function redeemSingleUnderlying(uint256 _shares, address _underlyingAsset, address _receiver, address _owner, uint256 _minAmount) external override nonReentrant returns (uint256 _underlyingAmount) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();

        uint256 _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);
        
        _underlyingAmount = _removeLiquidity(poolAddress, poolType, _underlyingAsset, _assets);
        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();
        
        if (_underlyingAsset == ETH) {
            (bool sent,) = msg.sender.call{value: _underlyingAmount}("");
            if (!sent) revert FailedToSendETH();
        } else {
            IERC20(_underlyingAsset).safeTransfer(msg.sender, _underlyingAmount);
        }

        return _underlyingAmount;
    }

    /********************************** Internal Functions **********************************/

    function _harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) internal override returns (uint256 _rewards) {
        PoolInfo memory _poolInfo = poolInfo;

        IConvexBasicRewards(_poolInfo.crvRewards).getReward();

        address[] memory _rewardAssets = _poolInfo.rewardAssets;
        address _rewardAsset;
        address _swap = swap;
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
        
            uint256 _platformFee = _poolInfo.platformFeePercentage;
            uint256 _harvestBounty = _poolInfo.harvestBountyPercentage;
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

            IConvexBooster(_poolInfo.booster).deposit(_poolInfo.boosterPoolId, _rewards, true);

            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    receive() external payable {}
}