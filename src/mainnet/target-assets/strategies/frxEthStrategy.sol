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
import {IFraxETHMinter} from "../interfaces/IFraxEthMinter.sol";
import {IFortressSwap} from "../interfaces/IFortressSwap.sol";

contract FrxEthStrategy is BaseStrategy  {

    using SafeERC20 for IERC20;
    
    struct Fees {
        /// @notice The performance fee percentage to take for platform on harvest
        uint256 platformFeePercentage;
        /// @notice The percentage of fee to pay for caller on harvest
        uint256 harvestBountyPercentage;
        /// @notice The fee percentage to take on withdrawal. Fee stays in the vault, and is therefore distributed to vault participants. Used as a mechanism to protect against mercenary capital
        uint256 withdrawFeePercentage;
    }

    /// @notice The address of frxETH token.
    address internal constant FRXETH = 0x5E8422345238F34275888049021821E8E08CAa1f; 
    /// @notice The address of sfrxETH token.
    address internal constant SFRXETH = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    /// @notice The address of fraxETHMinter
    address internal constant FRAXETHMINTER = 0xbAFA44EFE7901E04E39Dad13167D089C559c1138;

    /// @notice The fee denominator
    uint256 internal constant FEE_DENOMINATOR = 1e9;
    /// @notice The maximum withdrawal fee
    uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%
    /// @notice The maximum platform fee
    uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%
    /// @notice The maximum harvest fee
    uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%

    /// @notice The fees settings
    Fees public fees;
    /// @notice The amount of frxETH deposited
    uint256 deposited;
    /// @notice The address of FortressSwap
    address public swap;


    /********************************** Constructor **********************************/

    constructor(address _platform, address _fortEth, address _swap)
        BaseStrategy(_fortEth, _platform) {
            {
            Fees storage _fees = fees;
            _fees.platformFeePercentage = 50000000; // 5%
            _fees.harvestBountyPercentage = 25000000; // 2.5%
            _fees.withdrawFeePercentage = 2000000; // 0.2%
            }
            fortEth = _fortEth;
            swap = _swap;
        }
    /********************************* Modifiers **********************************/

    /// @notice Platform has admin access
    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    /********************************** View Functions **********************************/

    function getBalance() external view returns (uint256 _balance) {
        return IERC20(FRXETH).balanceOf(address(this));
    }

    /********************************** Platform Functions **********************************/
    
    function execute() public nonReentrant override {
        uint256 _balance = IERC20(WETH).balanceOf(address(this));
        if (!(_balance > 0)) revert ZeroAmount();

        IWETH(WETH).withdraw(_balance);

        IFraxETHMinter(FRAXETHMINTER).submit{ value:_balance }();
        deposited += _balance;

        emit Executed(block.timestamp, _balance);
    }

    function terminateExecution() external onlyMetaVault nonReentrant override {
        uint256 _balance = IERC20(FRXETH).balanceOf(address(this));
        _redeemToWeth(_balance);
        withdrawAll();
    }

    /// @dev Updates the fortressSwap address
    function updateSwap(address _swap) external onlyPlatform {
        swap = _swap;
    }
    /********************************** Mutated Functions **********************************/

    /// @dev Harvest rewarded frxETH and deposit them back into strategy
    function harvest(address _receiver, uint256 _minBounty) external nonReentrant {
        uint256 _rewards = IERC20(FRXETH).balanceOf(address(this)) - deposited;

        if (_rewards > 0) {

        Fees memory _fees = fees;
            uint256 _platformFee = _fees.platformFeePercentage;
            uint256 _harvestBounty = _fees.harvestBountyPercentage;
            if (_platformFee > 0) {
                _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
                _rewards = _rewards - _platformFee;
                IERC20(FRXETH).safeTransfer(platform, _platformFee);
            }
            if (_harvestBounty > 0) {
                _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
                if (!(_harvestBounty >= _minBounty)) revert InsufficientAmountOut();
                
                _rewards = _rewards - _harvestBounty;
                IERC20(FRXETH).safeTransfer(_receiver, _harvestBounty);
            }
        }
        _redeemToWeth(_rewards);
        execute(); 
    }
    
    
    /********************************** Internal Functions **********************************/

    function _approve(address _asset, address _spender, uint256 _amount) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, _amount);
    }
    
    function _redeemToWeth(uint256 _amount) internal nonReentrant returns (uint256 _amountOut) {
        if (_amount > 0) {
            _approve(FRXETH, swap, _amount);
            _amountOut = IFortressSwap(swap).swap(FRXETH, WETH, _amount);
        }
        return _amountOut;
    }

     /********************************** Events **********************************/

    /// @notice Emitted when a strategy executed
    /// @param _timestamp The timestamp of the strategy execution
    /// @param _amount The amount of frxETH added to strategy
    event Executed(uint256 indexed _timestamp, uint256 _amount);
}
