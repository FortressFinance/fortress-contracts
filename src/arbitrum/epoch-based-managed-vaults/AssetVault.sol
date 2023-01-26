// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IStrategy} from "./interfaces/IStrategy.sol";
import {IFortressSwap} from "./interfaces/IFortressSwap.sol";
import {IMetaVault} from "./interfaces/IMetaVault.sol";
import {IAssetVault} from "./interfaces/IAssetVault.sol";

contract AssetVault is ReentrancyGuard, IAssetVault {

    using SafeERC20 for ERC20;

    /// @notice The asset managed by this vault
    address internal asset;
    /// @notice The metaVault that manages this vault
    address public metaVault;
    /// @notice The metaVault Primary Asset
    address public metaVaultAsset;
    /// @notice The platform address
    address public platform;
    /// @notice The vault manager address
    address public manager;
    /// @notice The timelock delay, in seconds
    uint256 public delay;
    /// @notice The timelock timestamp
    uint256 public timelock;
    /// @notice Indicates if the timelock was set
    bool public isTimelocked;
    /// @notice Enables Platform to override isStrategiesActive value
    bool public isStrategiesActiveOverride;

    /// @notice The address list of strategies
    address[] public strategyList;

    /// @notice The mapping of strategies
    mapping(address => bool) public strategies;

    /********************************** Constructor **********************************/
    
    constructor(address _asset, address _metaVault, address _metaVaultAsset, address _platform, address _manager) {
        asset = _asset;
        metaVault = _metaVault;
        platform = _platform;
        manager = _manager;
        metaVaultAsset = _metaVaultAsset;
        delay = 86400; // 86400 seconds, 1 day
        isStrategiesActiveOverride = false;
    }

    /********************************** Modifiers **********************************/

    modifier onlyPlatform() {
        if (msg.sender != platform) revert Unauthorized();
        _;
    }

    /// @notice Platform has admin access
    modifier onlyMetaVault {
        if (msg.sender != metaVault || msg.sender != platform) revert Unauthorized();
        _;
    }

    /// @notice Platform has admin access
    modifier onlyManager() {
        if (msg.sender != manager || msg.sender != platform) revert Unauthorized();
        _;
    }

    modifier unmanaged() {
        if (!IMetaVault(metaVault).isUnmanaged()) revert InvalidState();
        _;
    }

    /********************************** View Functions **********************************/

    /// @inheritdoc IAssetVault
    function isStrategyActive(address _strategy) public view returns (bool) {
        return IStrategy(_strategy).isActive();
    }

    /// @inheritdoc IAssetVault
    function isStrategiesActive() public view returns (bool) {
        if (isStrategiesActiveOverride) return false;

        address[] memory _strategyList = strategyList;
        for (uint256 i = 0; i < _strategyList.length; i++) {
            if (isStrategyActive(_strategyList[i])) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IAssetVault
    function getAsset() external view returns (address) {
        return asset;
    }

    /********************************** Meta Vault Functions **********************************/

    /// @inheritdoc IAssetVault
    function deposit(uint256 _amount) external onlyMetaVault nonReentrant returns (uint256 _amountIn) {
        address _asset = asset;
        address _metaVault = metaVault;
        address _metaVaultAsset = metaVaultAsset;
        uint256 _before = ERC20(_asset).balanceOf(address(this));

        ERC20(_metaVaultAsset).safeTransferFrom(_metaVault, address(this), _amount);
        if (_asset != _metaVaultAsset) {
            _amount = IFortressSwap(IMetaVault(_metaVault).getSwap()).swap(_metaVaultAsset, _asset, _amount);
        }
        
        _amountIn = ERC20(_asset).balanceOf(address(this)) - _before;
        if (_amountIn != _amount) revert AmountMismatch();

        emit Deposit(block.timestamp, _amount);

        return _amountIn;
    }

    /// @inheritdoc IAssetVault
    function withdraw(uint256 _amount) public onlyMetaVault nonReentrant returns (uint256 _amountOut) {
        address _asset = asset;
        address _metaVaultAsset = metaVaultAsset;
        address _metaVault = metaVault;
        uint256 _before = ERC20(_metaVaultAsset).balanceOf(_metaVault);

        if (_asset != _metaVaultAsset) {
            _amount = IFortressSwap(IMetaVault(metaVault).getSwap()).swap(_asset, _metaVaultAsset, _amount);
        }

        ERC20(_metaVaultAsset).safeTransfer(_metaVault, _amount);
        _amountOut = ERC20(_metaVaultAsset).balanceOf(_metaVault) - _before;
        if (_amountOut != _amount) revert AmountMismatch();

        emit Withdraw(block.timestamp, _amount);
        
        return _amountOut;
    }

    /********************************** Manager Functions **********************************/

    /// @inheritdoc IAssetVault
    function depositToStrategy(address _strategy, uint256 _amount) external onlyManager nonReentrant {
        if (!strategies[_strategy]) revert StrategyNotActive();

        address _asset = address(asset);
        _approve(_asset, _strategy, _amount);
        IStrategy(_strategy).deposit(_amount);

        emit DepositedToStrategy(block.timestamp, _strategy, _amount);
    }

    /// @inheritdoc IAssetVault
    function exitStrategy(address _strategy, uint256 _amount) external onlyManager nonReentrant {
        if (!strategies[_strategy]) revert StrategyNotActive();

        IStrategy(_strategy).withdraw(_amount);

        emit WithdrawnFromStrategy(block.timestamp, _strategy, _amount);
    }

    /// @inheritdoc IAssetVault
    function exitStratagies() external onlyManager {
        address[] memory _strategyList = strategyList;
        for (uint256 i = 0; i < _strategyList.length; i++) {
            IStrategy(_strategyList[i]).withdrawAll();
        }
        // TODO - add blacklist strategy

        emit EpochEnded(block.timestamp);
    }

    /// @inheritdoc IAssetVault
    function requestAddStrategy() public onlyManager unmanaged nonReentrant {
        timelock = block.timestamp;
        isTimelocked = true;

        emit AddStrategyRequested(block.timestamp);
    }

    /// @inheritdoc IAssetVault
    function addStrategy(address _strategy) external onlyManager unmanaged nonReentrant {
        if (isTimelocked == false) revert NotTimelocked();
        if (timelock + delay > block.timestamp) revert TimelockNotExpired();
        if (IStrategy(_strategy).isAssetEnabled(address(asset))) revert StrategyMismatch();

        strategies[_strategy] = true;
        strategyList.push(_strategy);

        isTimelocked = false;

        emit StrategyAdded(block.timestamp, _strategy);
    }

    /// @inheritdoc IAssetVault
    function setManager(address _manager) external onlyManager unmanaged {
        manager = _manager;
        // TODO - add event
    }

    /********************************** Platform Functions **********************************/

    /// @inheritdoc IAssetVault
    function setTimelockDelay(uint256 _delay) external onlyPlatform unmanaged {

        delay = _delay;

        emit TimelockDelaySet(block.timestamp, _delay);
    }

    /// @inheritdoc IAssetVault
    function platformAddStrategy(address _strategy) external onlyPlatform unmanaged {
        if (IStrategy(_strategy).isAssetEnabled(address(asset))) revert StrategyMismatch();

        strategies[_strategy] = true;
        strategyList.push(_strategy);

        emit StrategyAdded(block.timestamp, _strategy);
    }

    /// @inheritdoc IAssetVault
    function overrideActiveStatus(bool _isStrategiesActive) external onlyPlatform {
        isStrategiesActiveOverride = _isStrategiesActive;

        emit ActiveStatusOverriden(block.timestamp, _isStrategiesActive);
    }

    /********************************** Internal Functions **********************************/

    function _approve(address _asset, address _spender, uint256 _amount) internal {
        ERC20(_asset).safeApprove(_spender, 0);
        ERC20(_asset).safeApprove(_spender, _amount);
    }
}