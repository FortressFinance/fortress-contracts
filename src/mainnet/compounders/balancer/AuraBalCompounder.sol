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

//  _____             _____     _ _____                             _         
// |  _  |_ _ ___ ___| __  |___| |     |___ _____ ___ ___ _ _ ___ _| |___ ___ 
// |     | | |  _| .'| __ -| .'| |   --| . |     | . | . | | |   | . | -_|  _|
// |__|__|___|_| |__,|_____|__,|_|_____|___|_|_|_|  _|___|___|_|_|___|___|_|  
//                                               |_|                          

import "src/shared/compounders/TokenCompounderBase.sol";
import "src/mainnet/utils/BalancerOperations.sol";

import "src/mainnet/fortress-interfaces/IFortressSwap.sol";
import "src/mainnet/interfaces/IAuraBALRewards.sol";
import "src/mainnet/interfaces/IAsset.sol";

contract AuraBalCompounder is BalancerOperations, TokenCompounderBase {

    using SafeERC20 for IERC20;

    /// @notice The address of AURA token.
    address private constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    /// @notice The address of BAL token.
    address private constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    /// @notice The address of BAL token.
    address private constant AURA_BAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
    /// @notice The address of ETH/BAL pool.
    address private constant BALANCER_WETHBAL = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    /// @notice The address of bb-a-USD token.
    address private constant BB_A_USD = 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2;
    /// @notice The address of bb-a-USDC token.
    address private constant BB_A_USDC = 0x9210F1204b5a24742Eba12f710636D76240dF3d0;
    /// @notice The address of USDC token.
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    /// @notice The address of Aura auraBAL staking contract. 
    address private constant auraBAL_STAKING = 0x5e5ea2048475854a5702F5B8468A51Ba1296EFcC;
    /// @notice The pool ID of Balancer bb-a-USD pool.
    bytes32 private constant BB_A_USD_POOL_ID = 0x7b50775383d3d6f0215a8f290f2c9e2eebbeceb20000000000000000000000fe;
    /// @notice The pool ID of Balancer bb-a-USDC pool.
    bytes32 private constant BB_A_USDC_POOL_ID = 0x9210f1204b5a24742eba12f710636d76240df3d00000000000000000000000fc;
    /// @notice The pool ID of Balancer USDC/WETH pool.
    bytes32 private constant USDC_WETH_POOL_ID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;
    /// @notice The pool ID of Balancer BAL/WETH pool.
    bytes32 private constant BAL_WETH_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    /// @notice The pool ID of Balancer BAL/WETH pool.
    bytes32 private constant AURA_WETH_POOL_ID = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
    
    /********************************** Constructor **********************************/
    
    constructor(address _owner, address _platform, address _swap) TokenCompounderBase(ERC20(AURA_BAL), "Fortress AuraBAL", "fort-auraBAL", _owner, _platform, _swap) {
        IERC20(AURA_BAL).safeApprove(auraBAL_STAKING, type(uint256).max);
        IERC20(AURA).safeApprove(BALANCER_VAULT, type(uint256).max);
        IERC20(BALANCER_WETHBAL).safeApprove(_swap, type(uint256).max);
        IERC20(AURA_BAL).safeApprove(_swap, type(uint256).max);
    }

    /********************************** View Functions **********************************/

    /// @notice See {TokenCompounderBase - isPendingRewards}
    function isPendingRewards() public view override returns (bool) {
        return (IAuraBALRewards(auraBAL_STAKING).earned(address(this)) > 0);
    }

    /********************************** Mutated Functions **********************************/

    /// @notice See {TokenCompounderBase - depositUnderlying}
    function depositUnderlying(uint256 _underlyingAmount, address _receiver, uint256 _minAmount) external override nonReentrant returns (uint256 _shares) {
        if (!(_underlyingAmount > 0)) revert ZeroAmount();

        IERC20(BAL).safeTransferFrom(msg.sender, address(this), _underlyingAmount);
        
        uint256 _assets = _swapBALToAuraBAL(_underlyingAmount);
        if (!(_assets >= _minAmount)) revert InsufficientAmountOut();

        _shares = previewDeposit(_assets);
        _deposit(msg.sender, _receiver, _assets, _shares);

        _depositStrategy(_assets, false);
        
        return _shares;
    }

    /// @notice See {TokenCompounderBase - redeemUnderlying}
    function redeemUnderlying(uint256 _shares, address _receiver, address _owner, uint256 _minAmount) public override nonReentrant returns (uint256 _underlyingAmount) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        uint256 _assets = previewRedeem(_shares);
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        _withdrawStrategy(_assets, _receiver, false);

        _underlyingAmount = _swapAuraBALToBAL(_assets);
        if (!(_underlyingAmount >= _minAmount)) revert InsufficientAmountOut();

        IERC20(BAL).safeTransfer(_receiver, _underlyingAmount);

        return _underlyingAmount;
    }

    /********************************** Internal Functions **********************************/

    function _depositStrategy(uint256 _assets, bool _transfer) internal override {
        if (_transfer) IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);
        IAuraBALRewards(auraBAL_STAKING).stake(_assets);
    }

    function _withdrawStrategy(uint256 _assets, address _receiver, bool _transfer) internal override {
        IAuraBALRewards(auraBAL_STAKING).withdraw(_assets, false);
        if (_transfer) IERC20(address(asset)).safeTransfer(_receiver, _assets);
    }

    function _harvest(address _receiver, uint256 _minBounty) internal override returns (uint256 _rewards) {
        
        IAuraBALRewards(auraBAL_STAKING).getReward();
        
        // bb-a-USD --> BAL
        uint256 _bbaUsdBalance = IERC20(BB_A_USD).balanceOf(address(this));
        if (_bbaUsdBalance > 0) {
            IAsset[] memory _assets = new IAsset[](5);
            _assets[0] = IAsset(address(BB_A_USD));
            _assets[1] = IAsset(address(BB_A_USDC));
            _assets[2] = IAsset(address(USDC));
            _assets[3] = IAsset(address(WETH));
            _assets[4] = IAsset(address(BAL));

            int256[] memory _limits = new int256[](5);
            _limits[0] = int256(_bbaUsdBalance);

            IBalancerVault.BatchSwapStep[] memory _swaps = new IBalancerVault.BatchSwapStep[](4);

            // BB_A_USD --> BB_A_USDC
            _swaps[0] = IBalancerVault.BatchSwapStep({
                poolId: BB_A_USD_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _bbaUsdBalance,
                userData: new bytes(0)
            });
            // BB_A_USDC --> USDC
            _swaps[1] = IBalancerVault.BatchSwapStep({
                poolId: BB_A_USDC_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0, // 0 means all from last step
                userData: new bytes(0)
            });
            // USDC --> WETH
            _swaps[2] = IBalancerVault.BatchSwapStep({
                poolId: USDC_WETH_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0, // 0 means all from last step
                userData: new bytes(0)
            });
            // WETH --> BAL
            _swaps[3] = IBalancerVault.BatchSwapStep({
                poolId: BAL_WETH_POOL_ID,
                assetInIndex: 3,
                assetOutIndex: 4,
                amount: 0, // 0 means all from last step
                userData: new bytes(0)
            });

            IBalancerVault.FundManagement memory _fundManagement = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            IBalancerVault(BALANCER_VAULT).batchSwap(
                IBalancerVault.SwapKind.GIVEN_IN,
                _swaps,
                _assets,
                _fundManagement,
                _limits,
                block.timestamp
            );
        }

        // AURA --> BAL
        uint256 _auraBalance = IERC20(AURA).balanceOf(address(this));
        if (_auraBalance > 0) {
            IAsset[] memory _assets = new IAsset[](3);
            _assets[0] = IAsset(address(AURA));
            _assets[1] = IAsset(address(WETH));
            _assets[2] = IAsset(address(BAL));

            int256[] memory _limits = new int256[](3);
            _limits[0] = int256(_auraBalance);

            IBalancerVault.BatchSwapStep[] memory _swaps = new IBalancerVault.BatchSwapStep[](2);

            // AURA --> WETH
            _swaps[0] = IBalancerVault.BatchSwapStep({
                poolId: AURA_WETH_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _auraBalance,
                userData: new bytes(0)
            });
            // WETH --> BAL
            _swaps[1] = IBalancerVault.BatchSwapStep({
                poolId: BAL_WETH_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0, // 0 means all from last step
                userData: new bytes(0)
            });

            IBalancerVault.FundManagement memory _fundManagement = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            IBalancerVault(BALANCER_VAULT).batchSwap(
                IBalancerVault.SwapKind.GIVEN_IN,
                _swaps,
                _assets,
                _fundManagement,
                _limits,
                block.timestamp
            );
        }
        
        // BAL --> auraBAL
        _rewards = IERC20(BAL).balanceOf(address(this));
        if (_rewards > 0) {
            _rewards = _swapBALToAuraBAL(_rewards);
            
            uint256 _platformFee = platformFeePercentage;
            uint256 _harvestBounty = harvestBountyPercentage;
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(AURA_BAL).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();
                
                _rewards = _rewards - _harvestBounty;
                IERC20(AURA_BAL).safeTransfer(_receiver, _harvestBounty);
            }
            
            IAuraBALRewards(auraBAL_STAKING).stake(_rewards);
            
            emit Harvest(_receiver, _rewards);
            return _rewards;
        } else {
            revert NoPendingRewards();
        }
    }

    /// @dev Swap BAL to auraBAL.
    /// @param _amount - The amount of BAL to swap.
    /// @return - The amount of auraBAL in return.
    function _swapBALToAuraBAL(uint256 _amount) internal returns (uint256) {
        address _balancerWETHBAL = BALANCER_WETHBAL;
        
        _amount = _addLiquidity(_balancerWETHBAL, BAL, _amount);
        
        return IFortressSwap(swap).swap(_balancerWETHBAL, AURA_BAL, _amount);
    }

    /// @dev Swap auraBAL to BAL.
    /// @param _amount - The amount of auraBAL to swap.
    /// @return - The amount of BAL in return.
    function _swapAuraBALToBAL(uint256 _amount) internal returns (uint256) {
        address _balancerWETHBAL = BALANCER_WETHBAL;
        address _aura_bal = AURA_BAL;

        _amount = IFortressSwap(swap).swap(_aura_bal, _balancerWETHBAL, _amount);

        return _removeLiquidity(_balancerWETHBAL, BAL, _amount);
    }
}