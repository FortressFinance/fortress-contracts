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

//  _____             _____ _           _               
// | __  |___ ___ ___|   __| |_ ___ ___| |_ ___ ___ _ _ 
// | __ -| .'|_ -| -_|__   |  _|  _| .'|  _| -_| . | | |
// |_____|__,|___|___|_____|_| |_| |__,|_| |___|_  |_  |
//                                             |___|___|

// Github - https://github.com/FortressFinance

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

abstract contract BaseStrategy is ReentrancyGuard, IStrategy {

    using SafeERC20 for IERC20;
    
    /// @notice The fortETH address
    address public fortEth;
    /// @notice The platform address
    address public platform;

    /// @notice The address of WETH token.
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /********************************** Constructor **********************************/
    
    constructor(address _fortETH, address _platform) {
        fortEth = _fortETH;
        platform = _platform;
    }

    /********************************* Modifiers **********************************/

    /// @notice Platform has admin access
    modifier onlyMetaVault() {
        if (msg.sender != fortEth && msg.sender != platform) revert Unauthorized();
        _;
    }

    /********************************** Asset Vault Functions **********************************/

    /// @inheritdoc IStrategy
    function deposit(uint256 _amount) external virtual onlyMetaVault nonReentrant {
        uint256 _before = IERC20(WETH).balanceOf(address(this));
        IERC20(WETH).safeTransferFrom(fortEth, address(this), _amount);
        uint256 _amountIn = IERC20(WETH).balanceOf(address(this)) - _before;
        if (_amountIn != _amount) revert AmountMismatch();

        emit Deposit(block.timestamp, _amountIn);
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 _amount) public virtual onlyMetaVault nonReentrant {
        uint256 _before = IERC20(WETH).balanceOf(fortEth);
        IERC20(WETH).safeTransfer(fortEth, _amount);
        uint256 _amountOut = IERC20(WETH).balanceOf(fortEth) - _before;
        if (_amountOut != _amount) revert AmountMismatch();

        emit Withdraw(block.timestamp, _amountOut);
    }

    /// @inheritdoc IStrategy
    function withdrawAll() public virtual onlyMetaVault {
        uint256 balance = IERC20(WETH).balanceOf(address(this));
        if (!(balance > 0)) revert ZeroAmount();

        withdraw(balance); 
    }

    /********************************** Manager Functions **********************************/

    function execute() external virtual onlyMetaVault {}

    function terminateExecution() external virtual onlyMetaVault  {}

    /********************************** Platform Functions **********************************/

    /// @inheritdoc IStrategy
    function rescueERC20(uint256 _amount) external onlyMetaVault {
        IERC20(WETH).safeTransfer(platform, _amount);

        emit Rescue(_amount);
    }
}