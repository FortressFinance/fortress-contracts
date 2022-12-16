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

//  _____         _____         _____                             _         
// |     |_ _ _ _|     |___ _ _|     |___ _____ ___ ___ _ _ ___ _| |___ ___ 
// |   --| | |_'_|   --|  _| | |   --| . |     | . | . | | |   | . | -_|  _|
// |_____|\_/|_,_|_____|_|  \_/|_____|___|_|_|_|  _|___|___|_|_|___|___|_|  
//                                             |_|                          

import "src/shared/compounders/TokenCompounderBase.sol";

import "src/mainnet/fortress-interfaces/IFortressSwap.sol";
import "src/mainnet/interfaces/IConvexBasicRewards.sol";
import "src/mainnet/interfaces/IConvexVirtualBalanceRewardPool.sol";
import "src/mainnet/interfaces/ICVXMining.sol";
import "src/mainnet/interfaces/ICurveBase3Pool.sol";

contract CvxCrvCompounder is TokenCompounderBase {

    using SafeERC20 for IERC20;

    /// @notice The address of cvxCRV token.
    address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    /// @notice The address of CRV token.
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    /// @notice The address of CVX token.
    address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    /// @notice The address representing native ETH.
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice The address of USDT token.
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    /// @notice The address of 3CRV token.
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    /// @notice The address of 3CRV pool.
    address private constant THREE_CRV_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    /// @notice The address of Convex cvxCRV Staking Contract.
    address private constant CVXCRV_STAKING = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    /// @notice The address of Convex CVX Mining Contract.
    address private constant CVX_MINING = 0x3c75BFe6FbfDa3A94E7E7E8c2216AFc684dE5343;
    /// @notice The address of Convex 3CRV Rewards Contract.
    address private constant THREE_CRV_REWARDS = 0x7091dbb7fcbA54569eF1387Ac89Eb2a5C9F6d2EA;
    
    /********************************** Constructor **********************************/
    
    constructor(address _owner, address _platform, address _swap) TokenCompounderBase(ERC20(CVXCRV), "Fortress cvxCRV", "fort-cvxCRV", _owner, _platform, _swap) {
        IERC20(CVXCRV).safeApprove(CVXCRV_STAKING, type(uint256).max);
        IERC20(THREE_CRV).safeApprove(THREE_CRV_POOL, type(uint256).max);
        IERC20(CVXCRV).safeApprove(_swap, type(uint256).max);
        IERC20(CRV).safeApprove(_swap, type(uint256).max);
        IERC20(CVX).safeApprove(_swap, type(uint256).max);
        IERC20(USDT).safeApprove(_swap, type(uint256).max);
    }

    /********************************** View Functions **********************************/

    /// @notice See {TokenCompounderBase - isPendingRewards}
    function isPendingRewards() public view override returns (bool) {
        return (pendingCRVRewards() > 0 || pendingCVXRewards() > 0 || pending3CRVRewards() > 0);
    }

    /// @dev Return the amount of pending CRV rewards.
    function pendingCRVRewards() public view returns (uint256) {
        return IConvexBasicRewards(CVXCRV_STAKING).earned(address(this));
    }

    /// @dev Return the amount of pending CVX rewards.
    function pendingCVXRewards() public view returns (uint256) {
        return ICVXMining(CVX_MINING).ConvertCrvToCvx(pendingCRVRewards());
    }

    /// @dev Return the amount of pending 3CRV rewards.
    function pending3CRVRewards() public view returns (uint256) {
        return IConvexVirtualBalanceRewardPool(THREE_CRV_REWARDS).earned(address(this));
    }

    /********************************** Mutated Functions **********************************/

    /// @notice See {TokenCompounderBase - depositUnderlying}
    function depositUnderlying(uint256 _underlyingAssets, address _receiver, uint256 _minAmount) external override nonReentrant returns (uint256 _shares) {
        if (!(_underlyingAssets > 0)) revert ZeroAmount();

        address _CRV = CRV;
        IERC20(_CRV).safeTransferFrom(msg.sender, address(this), _underlyingAssets);
        
        uint256 _assets = IFortressSwap(swap).swap(_CRV, CVXCRV, _underlyingAssets);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();

        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);

        _depositStrategy(_assets, false);
        
        return _shares;
    }

    /// @notice See {TokenCompounderBase - redeemUnderlying}
    function redeemUnderlying(uint256 _shares, address _receiver, address _owner, uint256 _minAmount) public override nonReentrant returns (uint256 _underlyingAssets) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        uint256 _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        _withdrawStrategy(_assets, _receiver, false);

        _underlyingAssets = IFortressSwap(swap).swap(CVXCRV, CRV, _assets);
        if (!(_underlyingAssets >= _minAmount)) revert InsufficientAmountOut();

        IERC20(CRV).safeTransfer(_receiver, _underlyingAssets);

        return _underlyingAssets;
    }

    /********************************** Internal Functions **********************************/

    function _depositStrategy(uint256 _assets, bool _transfer) internal override {
        if (_transfer) IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);
        IConvexBasicRewards(CVXCRV_STAKING).stake(_assets);
    }

    function _withdrawStrategy(uint256 _assets, address _receiver, bool _transfer) internal override {
        IConvexBasicRewards(CVXCRV_STAKING).withdraw(_assets, false);
        if (_transfer) IERC20(address(asset)).safeTransfer(_receiver, _assets);
    }

    function _harvest(address _receiver, uint256 _minBounty) internal override returns (uint256 _rewards) {
        
        IConvexBasicRewards(CVXCRV_STAKING).getReward();

        IFortressSwap _swap = IFortressSwap(swap);

        // 1. CVX => ETH
        _swap.swap(CVX, ETH, IERC20(CVX).balanceOf(address(this)));

        // 2. 3CRV => USDT
        ICurveBase3Pool(THREE_CRV_POOL).remove_liquidity_one_coin(IERC20(THREE_CRV).balanceOf(address(this)), 2, 0);
        
        // 3. USDT => ETH
        _swap.swap(USDT, ETH, IERC20(USDT).balanceOf(address(this)));

        // 4. ETH => CRV
        _swap.swap{ value: address(this).balance }(ETH, CRV, address(this).balance);
        
        // CRV --> cvxCRV
        _rewards = IERC20(CRV).balanceOf(address(this));
        if (_rewards > 0) {
            _rewards = _swap.swap(CRV, CVXCRV, _rewards);
            
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(CVXCRV).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();
                
                _rewards = _rewards - _harvestBounty;
                IERC20(CVXCRV).safeTransfer(_receiver, _harvestBounty);
            }
            
            IConvexBasicRewards(CVXCRV_STAKING).stake(_rewards);
            
            emit Harvest(_receiver, _rewards);
            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    receive() external payable {
        if (msg.sender != address(swap)) revert Unauthorized();
    }
}