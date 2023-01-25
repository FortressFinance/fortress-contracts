// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IAssetVault} from "../interfaces/IAssetVault.sol";
import {IFortressSwap} from "../interfaces/IFortressSwap.sol";
import {IMetaVault} from "../interfaces/IMetaVault.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

abstract contract BaseStrategy is ReentrancyGuard, IStrategy {

    using SafeERC20 for IERC20;
    
    /// @notice The assetVault that manages this vault
    address public assetVault;
    /// @notice The assetVault Primary Asset
    address public assetVaultAsset;
    /// @notice The platform address
    address public platform;
    /// @notice The vault manager address
    address public manager;
    /// @notice Enables Platform to override isStrategiesActive value
    bool public isStrategiesActiveOverride;

    /// @notice The address list of enabled assets
    address[] public assets;
    

    /********************************** Constructor **********************************/
    
    constructor(address[] _assets, address _assetVault, address _platform, address _manager, address _swap) {
        assets = _assets;
        assetVault = _assetVault;
        platform = _platform;
        manager = _manager;
        swap = _swap;
        assetVaultAsset = address(IAssetVault(_assetVault).asset());
        isStrategiesActiveOverride = false;
    }

    /********************************* Modifiers **********************************/

    /// @notice Platform has admin access
    modifier onlyAssetVault() {
        if (msg.sender != assetVault || msg.sender != platform) revert Unauthorized();
        _;
    }

    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    /// @notice Platform has admin access
    modifier onlyManager() {
        if (msg.sender != manager || msg.sender != platform) revert Unauthorized();
        _;
    }

    /********************************** View Functions **********************************/

    /// @inheritdoc IStrategy
    function isActive() public view virtual returns (bool) {
        if (isStrategiesActiveOverride) return false;
    }

    /// @inheritdoc IStrategy
    function isAssetEnabled(address _asset) public view virtual returns (bool) {
        address[] memory _assets = assets;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] == _asset) {
                return true;
            }
        }
        return false;
    }

    /********************************** Asset Vault Functions **********************************/

    /// @inheritdoc IStrategy
    function deposit(uint256 _amount) external virtual onlyAssetVault nonReentrant {
        address _assetVaultAsset = assetVaultAsset;
        uint256 _before = ERC20(_assetVaultAsset).balanceOf(address(this));
        ERC20(_assetVaultAsset).safeTransferFrom(assetVault, address(this), _amount);
        _amountIn = ERC20(_assetVaultAsset).balanceOf(address(this)) - _before;
        if (_amountIn != _amount) revert AmountMismatch();

        emit Deposit(block.timestamp, _amountIn);
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 _amount) public virtual onlyAssetVault nonReentrant {
        address _assetVaultAsset = assetVaultAsset;
        uint256 _before = ERC20(_assetVaultAsset).balanceOf(_assetVault);
        ERC20(_assetVaultAsset).safeTransfer(_assetVault, _amount);
        _amountOut = ERC20(_assetVaultAsset).balanceOf(_assetVault) - _before;
        if (_amountOut != _amount) revert AmountMismatch();

        emit Withdraw(block.timestamp, _amountOut);
    }

    /// @inheritdoc IStrategy
    function withdrawAll() public virtual onlyAssetVault {
        if (isActive()) revert StrategyActive();

        withdraw(ERC20(assetVaultAsset).balanceOf(address(this)));
    }

    /********************************** Platform Functions **********************************/

    /// @inheritdoc IStrategy
    function overrideActiveStatus(bool _isStrategiesActive) external onlyPlatform {
        isStrategiesActiveOverride = _isStrategiesActive;

        emit ActiveStatusOverriden(block.timestamp, _isStrategiesActive);
    }
}