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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ISTETH, IWSTETH} from "./interfaces/ISTETH.sol";
import {IMetaVault} from "./interfaces/IMetaVault.sol";
import {IAssetVault} from "./interfaces/IAssetVault.sol";

contract StETHAssetVault is ReentrancyGuard, IAssetVault {

    using SafeERC20 for ERC20;

    /// @notice The metaVault that manages this vault
    address public metaVault;
    /// @notice The platform address
    address public platform;
    /// @notice Enables Platform to override isStrategiesActive value
    bool public isActiveOverride = true;

    /// @notice The address of WETH token.
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /// @notice The address of WSTETH token.
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    /// @notice The address of STETH token.
    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    /********************************** Constructor **********************************/
    
    constructor(address _metaVault, address _platform) {
        metaVault = _metaVault;
        platform = _platform;
    }

    /********************************** Modifiers **********************************/

    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    /// @notice Platform has admin access
    modifier onlyMetaVault {
        if (msg.sender != metaVault && msg.sender != platform) revert Unauthorized();
        _;
    }

    /********************************** View Functions **********************************/

    /// @inheritdoc IAssetVault
    function isActive() external view returns (bool) {
        return ERC20(WSTETH).balanceOf(address(this)) > 0 || areStrategiesActive();
    }

    /// @inheritdoc IAssetVault
    function getPrimaryAsset() external view returns (address) {
        return WSTETH;
    }

    function getPrimaryAssetBalance() external view returns (uint256) {
        return ERC20(WSTETH).balanceOf(address(this));
    }

    function getEthBalance() external view returns (uint256) {
        return IWstETH(WSTETH).getStETHByWstETH(getPrimaryAssetBalance());
    }

    /********************************** Meta Vault Functions **********************************/

    /// @inheritdoc IAssetVault
    function deposit(uint256 _amount) external onlyMetaVault nonReentrant returns (uint256 _amountIn) {
        ERC20(WETH).safeTransferFrom(_metaVault, address(this), _amount);

        if (!(ERC20(WETH).balanceOf(address(this))>0)) revert ZeroAmount();

        uint256 ethBalance = IWETH(WETH).withdraw(wethBalance);

        uint256 amountStEthSharesOut = IStETH(STETH).submit{ value: ethBalance }(address(0));
        uint256 amountStETH = IStETH(STETH).getPooledEthByShares(amountStEthSharesOut);
        _amountIn = IWstETH(WSTETH).wrap(amountStETH);

        emit Deposited(block.timestamp, _amount, _amountIn);

        return _amountIn;
    }

    /// @inheritdoc IAssetVault
    /// @notice WIP
    function withdraw(uint256 _amount) public onlyMetaVault nonReentrant returns (uint256 _amountOut) {
        if (!(ERC20(WSTETH).balanceOf(address(this))>0)) revert ZeroAmount();

        uint256 _amountStEth = IWstETH(WSTETH).unwrap(amountStETH);
        
        // stETH -> WETH conversion logic here

        // ERC20(WETH).safeTransfer(_metaVault, _amountOut);
        // emit Withdrawn(block.timestamp, _amountOut);
        
        return _amountOut;
    }

    /********************************** Platform Functions **********************************/

    /// @inheritdoc IAssetVault
    function overrideActiveStatus(bool _isActive) external onlyPlatform {
        isActiveOverride = _isActive;

        emit ActiveStatusOverriden(block.timestamp, _isActive);
    }

}