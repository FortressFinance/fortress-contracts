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

//  _____                 _____ _     _____                     _           _           
// |     |_ _ ___ _ _ ___|   __| |___|     |___ ___ ___ ___ ___| |_ ___ ___| |_ ___ ___ 
// |   --| | |  _| | | -_|  |  | | . |   --| . |   |  _| -_|   |  _|  _| .'|  _| . |  _|
// |_____|___|_|  \_/|___|_____|_|  _|_____|___|_|_|___|___|_|_|_| |_| |__,|_| |___|_|  
//                               |_|                                                    

// Github - https://github.com/FortressFinance

import "src/shared/concentrators/AMMConcentratorBase.sol";
import "src/arbitrum/utils/CurveArbiOperations.sol";

import "src/arbitrum/interfaces/IConvexBoosterArbi.sol";
import "src/arbitrum/interfaces/IConvexBasicRewardsArbi.sol";
import "src/arbitrum/interfaces/IGlpMinter.sol";

contract CurveGlpConcentrator is CurveArbiOperations, AMMConcentratorBase {

    using SafeERC20 for IERC20;

    /// @notice The address of the underlying Curve pool.
    address private immutable poolAddress;
    /// @notice The type of the pool, used in CurveOperations.
    uint256 private immutable poolType;

    /// @notice The address of the contract that mints and stakes GLP.
    address public glpHandler;
    /// @notice The address of the contract that needs an approval before minting GLP.
    address public glpManager;

    /// @notice The address of sGLP token.
    address public constant sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    /// @notice The address of CRV token.
    address public constant CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;
    
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
            IConvexBoosterArbi(0xF403C135812408BFbE8713b5A23a04b3D48AAE31).poolInfo(_boosterPoolId).rewards,
            _boosterPoolId,
            _rewardAssets,
            _underlyingAssets,
            _compounder
        ) {
            IERC20(sGLP).safeApprove(_compounder, type(uint256).max);

            glpHandler = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
            glpManager = 0x3963FfC9dff443c2A94f21b129D429891E32ec18;
            
            poolType = _poolType;
            poolAddress = metaRegistry.get_pool_from_lp_token(address(_asset));
        }
    
    /********************************** View Functions **********************************/

    /// @notice See {AMMConcentratorBase - isPendingRewards}
    function isPendingRewards() external override view returns (bool) {
        return IConvexBasicRewardsArbi(crvRewards).claimable_reward(CRV, address(this)) > 0;
    }
    
    /********************************** Mutated Functions **********************************/

    /// @dev Adds the ability to choose the underlying asset to deposit to the base function.
    /// @dev Harvest the pending rewards and convert to underlying token, then stake.
    /// @param _receiver - The address of account to receive harvest bounty.
    /// @param _minBounty - The minimum amount of harvest bounty _receiver should get.
    function harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) external nonReentrant returns (uint256 _rewards) {
        if (block.number == lastHarvestBlock) revert HarvestAlreadyCalled();
        lastHarvestBlock = block.number;

        _rewards = _harvest(_receiver, _underlyingAsset, _minBounty);
        totalAUM += _rewards;

        return _rewards;
    }

    /********************************** Restricted Functions **********************************/

    function updateGlpContracts(address _glpHandler, address _glpManager) external {
        if (msg.sender != owner) revert Unauthorized();

        glpHandler = _glpHandler;
        glpManager = _glpManager;
    }

    /********************************** Internal Functions **********************************/

    function _depositStrategy(uint256 _assets, bool _transfer) internal override {
        if (_transfer) IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);
        IConvexBoosterArbi(booster).deposit(boosterPoolId, _assets);
    }

    function _withdrawStrategy(uint256 _assets, address _receiver, bool _transfer) internal override {
        IConvexBasicRewards(crvRewards).withdraw(_assets, false);
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

    function _harvest(address _receiver, uint256 _minBounty) internal override returns (uint256 _rewards) {
        return _harvest(_receiver, WETH, _minBounty);
    }

    function _harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) internal returns (uint256 _rewards) {
        
        IConvexBasicRewardsArbi(crvRewards).getReward(address(this));

        address _token;
        address _swap = swap;
        address[] memory _rewardAssets = rewardAssets;
        for (uint256 i = 0; i < _rewardAssets.length; i++) {
            _token = _rewardAssets[i];
            if (_token != _underlyingAsset) {
                uint256 _balance = IERC20(_token).balanceOf(address(this));
                if (_balance > 0) {
                    IFortressSwap(_swap).swap(_token, _underlyingAsset, _balance);
                }
            }
        }
        
        _rewards = IERC20(_underlyingAsset).balanceOf(address(this));

        address _sGLP = sGLP;
        uint256 _startBalance = IERC20(_sGLP).balanceOf(address(this));
        _approve(_underlyingAsset, glpManager, _rewards);
        IGlpMinter(glpHandler).mintAndStakeGlp(_underlyingAsset, _rewards, 0, 0);
        _rewards = IERC20(_sGLP).balanceOf(address(this)) - _startBalance;
        
        if (_rewards > 0) {
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(_sGLP).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();

                _rewards = _rewards - _harvestBounty;
                IERC20(_sGLP).safeTransfer(_receiver, _harvestBounty);
            }

            _rewards = ERC4626(compounder).deposit(_rewards, address(this));

            accRewardPerShare = accRewardPerShare + ((_rewards * PRECISION) / totalSupply);
            
            emit Harvest(msg.sender, _receiver, _rewards, _platformFee);

            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    function _approve(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    receive() external payable {}
}