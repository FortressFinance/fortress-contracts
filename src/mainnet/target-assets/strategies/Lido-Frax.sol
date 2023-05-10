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


// Github - https://github.com/FortressFinance

import {BaseStrategy} from "./BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ISTETH} from "../interfaces/ISTETH.sol";
import {IFraxETHMinter} from "../interfaces/IFraxEthMinter.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

contract LidoFraxStrategy is BaseStrategy  {

    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /// @notice The address of wstETH token.
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    /// @notice The address of stETH token.
    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    /// @notice The address of frxETH token.
    address internal constant FRXETH = 0x5E8422345238F34275888049021821E8E08CAa1f; 
    /// @notice The address of sfrxETH token.
    address internal constant SFRXETH = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    /// @notice The address of fraxETHMinter
    address internal constant FRAXETHMINTER = 0xbAFA44EFE7901E04E39Dad13167D089C559c1138;

    /// @notice The stETH weight 
    uint256 public stEthWeight; // 1e8 = 10%
    /// @notice The frxETH weight 
    uint256 public frxEthWeight; 
    /// @notice The fee denominator
    uint256 internal constant DENOMINATOR = 1e9;

    /// @notice The amount of stETH deposited
    uint256 stEthDeposited;
    /// @notice The amount of frxETH deposited
    uint256 frxEthDeposited;


    /********************************** Constructor **********************************/

    constructor(address _platform, address _fortEth, uint256 _stEthWeight, uint256 _frxEthWeight)
        BaseStrategy(_fortEth, _platform) {
            fortEth = _fortEth;
            stEthWeight = _stEthWeight;
            frxEthWeight = _frxEthWeight;
        }

    /********************************** View Functions **********************************/

    function getBalances() external view returns (uint256 _stEthBalance, uint256 _frxEthBalance) {
        _stEthBalance = IERC20(STETH).balanceOf(address(this));
        _frxEthBalance = IERC20(FRXETH).balanceOf(address(this));

        return (_stEthBalance, _frxEthBalance);
    }

    /********************************** Manager Functions **********************************/
    
    function execute() external onlyMetaVault nonReentrant override {
        _distributeAssets();
    }

    function terminateExecution() external onlyMetaVault nonReentrant override {
        _redeemToWeth();
        withdrawAll();
    }

    /// @dev Updates the fortressSwap address
    function updateWeights(uint256 _stEthWeight, uint256 _frxEthWeight) external onlyMetaVault {
        if ((_stEthWeight+_frxEthWeight) > 1e9) revert IncorrectWeight();

        stEthWeight = _stEthWeight;
        frxEthWeight = _frxEthWeight;

        _redeemToWeth();
        _distributeAssets();
    }
    /********************************** Mutated Functions **********************************/

    /// @notice TODO
    function harvest(address _receiver, uint256 _minBounty) external nonReentrant {}
    
    /********************************** Internal Functions **********************************/

    function _approve(address _asset, address _spender, uint256 _amount) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, _amount);
    }

    function _distributeAssets() internal nonReentrant returns (uint256 _amountInStEth, uint256 _amountInFrxEth) {

        uint256 balance = IERC20(WETH).balanceOf(address(this));
        if (!(balance > 0)) revert ZeroAmount();

        IWETH(WETH).withdraw(balance);

        uint256 _stEthShare = balance.mulDivDown(stEthWeight, DENOMINATOR);
        ISTETH(STETH).submit{ value: _stEthShare }(address(0));
        stEthDeposited += _stEthShare;

        uint256 _frxEthShare = balance.mulDivDown(frxEthWeight, DENOMINATOR);
        IFraxETHMinter(FRAXETHMINTER).submit{ value:_frxEthShare }();
        frxEthDeposited += _frxEthShare;
        
        return (_stEthShare, _frxEthShare);
    }
    
    function _redeemToWeth() internal nonReentrant returns (uint256 _amountOut) {

        uint256 stEthBalance = IERC20(STETH).balanceOf(address(this));
        if (stEthBalance > 0) {
            // stETH -> ETH logic here
        }
        uint256 frxEthBalance = IERC20(FRXETH).balanceOf(address(this));
        if (frxEthBalance > 0) {
            // frxETH -> ETH logic here
        }
        return _amountOut;
    }
}
