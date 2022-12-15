// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

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

//  _____         _____         _____                     _           _           
// |     |_ _ _ _|     |___ _ _|     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___ 
// |   --| | |_'_|   --|  _| | |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _|
// |_____|\_/|_,_|_____|_|  \_/|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_|  

// Github - https://github.com/FortressFinance

import "src/mainnet/concentrators/AMMConcentratorBase.sol";
import "src/mainnet/utils/CurveOperations.sol";

contract CvxCrvConcentrator is CurveOperations, AMMConcentratorBase {

    using SafeERC20 for IERC20;

    /// @notice The address of the underlying Curve pool.
    address private immutable poolAddress;
    /// @notice The type of the pool, used in CurveOperations.
    uint256 private immutable poolType;
    /// @notice The address of CRV token.
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    /// @notice The address of cvxCRV token.
    address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    
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
        address _compounder,
        uint256 _poolType
        )
        AMMConcentratorBase(
            _asset,
            _name,
            _symbol,
            _owner,
            _platform,
            _swap,
            address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Booster
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets,
            _compounder
        ) {
            IERC20(CVXCRV).safeApprove(_compounder, type(uint256).max);

            poolType = _poolType;
            poolAddress = metaRegistry.get_pool_from_lp_token(address(_asset));
        }

    /********************************** Mutated Functions **********************************/

    /// @notice See {AMMConcentratorBase - depositSingleUnderlying}
    function depositSingleUnderlying(uint256 _underlyingAmount, address _underlyingAsset, address _receiver, uint256 _minAmount) external payable override nonReentrant returns (uint256 _shares) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (!(_underlyingAmount > 0)) revert ZeroAmount();

        _updateRewards(msg.sender);

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

        _afterDeposit(_assets, false);

        return _shares;
    }

    /// @notice See {AMMConcentratorBase - redeemSingleUnderlying}
    function redeemSingleUnderlying(uint256 _shares, address _underlyingAsset, address _receiver, address _owner, uint256 _minAmount) public override nonReentrant returns (uint256 _underlyingAmount) {
        if (!_isUnderlyingAsset(_underlyingAsset)) revert NotUnderlyingAsset();
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();
        
        _updateRewards(_owner);

        uint256 _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        _afterWithdraw(_assets, _receiver, false);

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

    function _harvest(address _receiver, uint256 _minBounty) internal override returns (uint256 _rewards) {
        
        IConvexBasicRewards(crvRewards).getReward();

        address _token;
        address _swap = swap;
        address _crv = CRV;
        address[] memory _rewardAssets = rewardAssets;
        for (uint256 i = 0; i < _rewardAssets.length; i++) {
            _token = _rewardAssets[i];
            if (_token != _crv) {
                if (_token == ETH && address(this).balance > 0) {
                    IFortressSwap(_swap).swap{ value: address(this).balance }(ETH, _crv, address(this).balance);
                } else {
                    uint256 _balance = IERC20(_token).balanceOf(address(this));
                    if (_balance > 0) {
                        IFortressSwap(_swap).swap(_token, _crv, _balance);
                    }
                }
            }
        }
        
        address _cvxcrv = CVXCRV;
        _rewards = IERC20(_crv).balanceOf(address(this));
        if (_rewards > 0) {
            _rewards = IFortressSwap(_swap).swap(_crv, _cvxcrv, _rewards);
        
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(_cvxcrv).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

                _rewards = _rewards - _harvestBounty;
                IERC20(_cvxcrv).safeTransfer(_receiver, _harvestBounty);
            }

            _rewards = ERC4626(compounder).deposit(_rewards, address(this));

            accRewardPerShare = accRewardPerShare + ((_rewards * PRECISION) / totalSupply);
            
            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    receive() external payable {}
}