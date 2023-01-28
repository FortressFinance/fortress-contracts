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

//  _____     _       _____         _ _   
// |     |___| |_ ___|  |  |___ _ _| | |_ 
// | | | | -_|  _| .'|  |  | .'| | | |  _|
// |_|_|_|___|_| |__,|\___/|__,|___|_|_|  

// Github - https://github.com/FortressFinance

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ERC20, ERC4626, FixedPointMathLib} from "src/shared/interfaces/ERC4626.sol";
import {AssetVault} from "./AssetVault.sol";

import {IMetaVault} from "./interfaces/IMetaVault.sol";
import {IFortressSwap} from "./interfaces/IFortressSwap.sol";

contract MetaVault is ReentrancyGuard, ERC4626, IMetaVault {

    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /// @notice The current state of the vault
    State public currentVaultState = State.INITIAL;

    // Vault owners
    
    /// @notice The platform address
    address public platform;
    /// @notice The vault manager address
    address public manager;
    
    // Manager settings

    /// @notice The percentage of performance fee to for Vault Manager
    uint256 public managerPerformanceFee;
    /// @notice The percentage of TVL that is the max performance fee. Used to disincentivize over risk taking
    uint256 public performanceFeeLimit;
    /// @notice The percentage of fee to keep in vault on withdraw (distrebuted among vault participants)
    uint256 public vaultWithdrawFee;
    /// @notice The percentage of TVL required in collateral by Vault Manager
    uint256 public collateralRequirement;
    /// @notice The time that the Epoch is expected to end
    uint256 public epochEndTimestamp;
    /// @notice Indicates whether to punish vault manager on not finishing an Epoch at the specified time
    bool public shouldPunishManager;
    /// @notice Indicates whether to charge a performance fee for Vault Manager
    bool public isPerformanceFeeEnabled;
    /// @notice Indicates whether to require collateral from the Vault Manager
    bool public isCollateralRequired;

    // Platform settings

    /// @notice The swap contract address
    address internal swap;
    /// @notice The deposit limit, denominated in shares
    uint256 public depositLimit;
    /// @notice The percentage of managment fee to pay for platform
    uint256 public platformManagementFee;
    /// @notice The timelock period, in seconds
    uint256 public timelockDuration;
    /// @notice Whether deposit for the pool is paused
    bool public isDepositPaused;
    /// @notice Whether withdraw for the pool is paused
    bool public isWithdrawPaused;
    
    // Accounting

    /// @notice The internal accounting of AUM
    uint256 internal totalAUM;
    /// @notice The snapshot of total shares supply from previous epoch
    uint256 public snapshotSharesSupply;
    /// @notice The snapshot of total asset supply from previous epoch
    uint256 public snapshotAssetBalance;

    // Utilitiy

    /// @notice The timestamp that the timelock has started
    uint256 public timelockStartTimestamp;
    /// @notice Indicates whether the timelock has been initiated
    bool public isTimelockInitiated;
    /// @notice The fee denominator
    uint256 internal constant FEE_DENOMINATOR = 1e9;

    /// @notice The mapping of addresses of assets to AssetVaults
    /// @dev AssetVaults are standalone contracts that hold the assets and allow for the execution of Stratagies
    mapping(address => address) public assetVaults;
    /// @notice The mapping of blacklisted assets
    mapping(address => bool) public blacklistedAssets;

    /// @notice The list of addresses of AssetVaults
    address[] public assetVaultList;

    /********************************** Constructor **********************************/

    constructor(
            ERC20 _asset,
            string memory _name,
            string memory _symbol,
            address _platform,
            address _manager,
            address _swap
        )
        ERC4626(_asset, _name, _symbol) {
        
        // Vault owners
        platform = _platform;
        manager = _manager;

        // Manager settings
        managerPerformanceFee = 5; // 20%
        vaultWithdrawFee = 2000000; // 0.2%
        performanceFeeLimit = 5; // limit performance fee to 20% of TVL
        collateralRequirement = 200; // require manager to hold 0.5% of outstanding shares

        shouldPunishManager = true;
        isPerformanceFeeEnabled = true;
        isCollateralRequired = true;
        
        // Platform settings
        swap = _swap;
        platformManagementFee = 600; // 2% annually
        depositLimit = 0;
        timelockDuration = 86400; // 86400 seconds, 1 day

        isDepositPaused = false;
        isWithdrawPaused = false;
        isTimelockInitiated = false;
    }

    /********************************* Modifiers **********************************/

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

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewDeposit(uint256 _assets) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;

        return convertToShares(_assets);
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewMint(uint256 _shares) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;

        return convertToAssets(_shares);
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;

        uint256 assets = convertToAssets(_shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a fee - zero if user is the last to withdraw
        uint256 _fee = (_totalSupply == 0 || _totalSupply - _shares == 0) ? 0 : assets.mulDivDown(vaultWithdrawFee, FEE_DENOMINATOR);

        // Redeemable amount is the post-withdrawal-fee amount
        return assets - _fee;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;

        uint256 _shares = convertToShares(_assets);

        uint256 _totalSupply = totalSupply;

        // Factor in additional shares to fulfill withdrawal fee if user is not the last to withdraw
        return (isCollateralRequired == true || _totalSupply - _shares == 0) ? _shares : (_shares * FEE_DENOMINATOR) / (FEE_DENOMINATOR - vaultWithdrawFee);
    }

    /// @inheritdoc ERC4626
    /// @notice May return an inaccurate response when 'state' is 'MANAGED' or 'INITIAL'
    function totalAssets() public view override returns (uint256) {
        return totalAUM;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxDeposit(address) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;
        
        uint256 _depositLimit = convertToAssets(depositLimit);
        uint256 _platformImposedLimit = _depositLimit == 0 ? type(uint256).max : _depositLimit - totalAUM;

        uint256 _collateralImposedLimit = convertToAssets(_getCollateralImposedLimit());

        return _platformImposedLimit < _collateralImposedLimit ? _platformImposedLimit : _collateralImposedLimit;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxMint(address) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;
        
        uint256 _platformImposedLimit = depositLimit == 0 ? type(uint256).max : depositLimit - totalSupply;

        uint256 _collateralImposedLimit = _getCollateralImposedLimit();

        return _platformImposedLimit < _collateralImposedLimit ? _platformImposedLimit : _collateralImposedLimit;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxWithdraw(address owner) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;

        return convertToAssets(balanceOf[owner]);
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxRedeem(address owner) public view override returns (uint256) {
        if (currentVaultState != State.UNMANAGED) return 0;

        return balanceOf[owner];
    }

    /// @inheritdoc IMetaVault
    function getSwap() public view returns (address) {
        return swap;
    }

    /// @inheritdoc IMetaVault
    function isUnmanaged() public view returns (bool) {
        return currentVaultState == State.UNMANAGED;
    }

    /********************************** Investor Functions **********************************/

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        if (_assets >= maxDeposit(msg.sender)) revert DepositLimitExceeded();

        _shares = previewDeposit(_assets);

        _deposit(msg.sender, _receiver, _assets, _shares);

        IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);

        return _shares;
    }

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 _assets) {
        if (_shares >= maxMint(msg.sender)) revert DepositLimitExceeded();

        _assets = previewMint(_shares);
        
        _deposit(msg.sender, _receiver, _assets, _shares);

        IERC20(address(asset)).safeTransferFrom(msg.sender, address(this), _assets);

        return _assets;
    }

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function withdraw(uint256 _assets, address _receiver, address _owner) external override nonReentrant returns (uint256 _shares) {
        if (_assets > maxWithdraw(_owner)) revert InsufficientBalance();

        _shares = previewWithdraw(_assets);
        
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        IERC20(address(asset)).safeTransfer(_receiver, _assets);

        return _shares;
    }

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function redeem(uint256 _shares, address _receiver, address _owner) external override nonReentrant returns (uint256 _assets) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        _assets = previewRedeem(_shares);
        
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        IERC20(address(asset)).safeTransfer(_receiver, _assets);

        return _assets;
    }

    /// @inheritdoc IMetaVault
    function executeLatenessPenalty() external nonReentrant {
        if (shouldPunishManager == false) revert LatenessNotPenalized();
        if (block.timestamp < epochEndTimestamp) revert EpochNotCompleted();
        
        _onState(State.MANAGED);

        isPerformanceFeeEnabled = false;
        _burn(address(this), balanceOf[address(this)]);
        
        emit LatenessPenalty(block.timestamp);
    }

    /********************************** Manager Functions **********************************/

    /// @inheritdoc IMetaVault
    function initiateVault(bytes memory _configData) external virtual onlyManager nonReentrant {
        _onState(State.INITIAL);

        currentVaultState = State.UNMANAGED;
        initiateEpoch(_configData);

        emit EpochCompleted(block.timestamp, 0, 0);
    }

    /// @inheritdoc IMetaVault
    function initiateEpoch(bytes memory _configData) public onlyManager nonReentrant {
        _onState(State.UNMANAGED);

        (epochEndTimestamp, managerPerformanceFee, vaultWithdrawFee, collateralRequirement, shouldPunishManager, isPerformanceFeeEnabled, isCollateralRequired)
         = abi.decode(_configData, (uint256, uint256, uint256, uint256, bool, bool, bool));
        
        // TODO - assert manager input values
        if (epochEndTimestamp <= block.timestamp) revert EpochEndTimestampInvalid();
        // if (managerPerformanceFee > 10000) revert ManagerPerformanceFeeInvalid();
        // if (vaultWithdrawFee > 10000) revert VaultWithdrawFeeInvalid();
        // if (collateralRequirement > 10000) revert CollateralRequirementInvalid();

        timelockStartTimestamp = block.timestamp;
        isTimelockInitiated = true;
        
        emit EpochInitiated(block.timestamp, _configData);
    }

    /// @inheritdoc IMetaVault
    function startEpoch() external onlyManager nonReentrant {
        if (isTimelockInitiated == false) revert NotTimelocked();
        if (timelockStartTimestamp + timelockDuration > block.timestamp) revert TimelockNotExpired();
        
        _onState(State.UNMANAGED);

        _beforeEpochStart();

        currentVaultState = State.MANAGED;

        emit EpochStarted(block.timestamp, snapshotAssetBalance, snapshotSharesSupply);

        _afterEpochStart();
    }

    /// @inheritdoc IMetaVault
    function endEpoch() external onlyManager nonReentrant {
        _onState(State.MANAGED);

        _beforeEpochEnd();

        currentVaultState = State.UNMANAGED;

        emit EpochCompleted(block.timestamp, snapshotAssetBalance, snapshotSharesSupply);

        _afterEpochEnd();
    }

    /// @inheritdoc IMetaVault
    function addAssetVault(address _targetAsset) external onlyManager nonReentrant returns (address _assetVault) {
        if (!IFortressSwap(swap).routeExists(address(asset), _targetAsset)) revert InvalidSwapRoute();
        if (!IFortressSwap(swap).routeExists(_targetAsset, address(asset))) revert InvalidSwapRoute();
        if (blacklistedAssets[_targetAsset]) revert BlacklistedAsset();
        
        _onState(State.UNMANAGED);

        _assetVault = address(new AssetVault(_targetAsset, address(this), address(asset), platform, manager));
        
        assetVaults[_targetAsset] = _assetVault;
        assetVaultList.push(_assetVault);

        emit AssetVaultAdded(_assetVault, _targetAsset);

        return _assetVault;
    }

    /// @inheritdoc IMetaVault
    function depositAsset(address _asset, uint256 _amount, uint256 _minAmount) external onlyManager nonReentrant returns (uint256) {
        if (blacklistedAssets[_asset]) revert BlacklistedAsset();
        
        _onState(State.MANAGED);

        address _assetVault = assetVaults[_asset];
        if (_assetVault == address(0)) revert AssetVaultNotAvailable();

        _approve(_asset, _assetVault, _amount);
        _amount = AssetVault(_assetVault).deposit(_amount);
        if (_amount < _minAmount) revert InsufficientAmountOut();

        emit AssetDeposited(_assetVault, _asset, _amount);

        return _amount;
    }

    /// @inheritdoc IMetaVault
    function withdrawAsset(address _asset, uint256 _amount, uint256 _minAmount) external onlyManager nonReentrant returns (uint256) {
        _onState(State.MANAGED);

        address _assetVault = assetVaults[_asset];
        if (_assetVault == address(0)) revert AssetVaultNotAvailable();

        _amount = AssetVault(_assetVault).withdraw(_amount);
        if (_amount < _minAmount) revert InsufficientAmountOut();

        emit AssetWithdrawn(_assetVault, _asset, _amount);

        return _amount;
    }

    /// @inheritdoc IMetaVault
    function updateManager(address _manager) external onlyManager {
        _onState(State.UNMANAGED);

        manager = _manager;

        emit ManagerUpdated(_manager);
    }

    /********************************** Platform Functions **********************************/

    /// @inheritdoc IMetaVault
    function setManagementFees(uint256 _platformManagementFee) external onlyPlatform {
        _onState(State.UNMANAGED);

        platformManagementFee = _platformManagementFee;

        emit ManagementFeeUpdated(_platformManagementFee);
    }

    /// @inheritdoc IMetaVault
    function updatePauseInteractions(bool _isDepositPaused, bool _isWithdrawPaused) external onlyPlatform {
        isDepositPaused = _isDepositPaused;
        isWithdrawPaused = _isWithdrawPaused;

        emit PauseInteractionsUpdated(_isDepositPaused, _isWithdrawPaused);
    }

    /// @inheritdoc IMetaVault
    function updateSettings(State _currentVaultState, address _swap, uint256 _depositLimit, uint256 _timelockDuration) external onlyPlatform {
        if (_depositLimit <= totalSupply) revert DepositLimitExceeded();
        
        _onState(State.UNMANAGED);

        currentVaultState = _currentVaultState;
        swap = _swap;
        depositLimit = _depositLimit;
        timelockDuration = _timelockDuration;

        emit SettingsUpdated(_currentVaultState, _swap, _depositLimit, _timelockDuration);
    }

    /// @inheritdoc IMetaVault
    function blacklistAsset(address _asset) external onlyPlatform {
        _onState(State.UNMANAGED);

        blacklistedAssets[_asset] = true;

        emit AssetBlacklisted(_asset);
    }

    /********************************** Internal Functions **********************************/

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        if (isDepositPaused) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _onState(State.UNMANAGED);

        _mint(_receiver, _shares);
        totalAUM += _assets;

        emit Deposited(_caller, _receiver, _assets, _shares);
    }

    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) internal override {
        if (isWithdrawPaused) revert WithdrawPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (_owner == address(0)) revert ZeroAddress();
        if (!(_shares > 0)) revert ZeroAmount();
        if (!(_assets > 0)) revert ZeroAmount();

        _onState(State.UNMANAGED);
        
        if (_caller != _owner) {
            uint256 _allowed = allowance[_owner][_caller];
            if (_allowed < _shares) revert InsufficientAllowance();
            if (_allowed != type(uint256).max) allowance[_owner][_caller] = _allowed - _shares;
        }
        
        _burn(_owner, _shares);
        totalAUM -= _assets;

        emit Withdrawn(_caller, _receiver, _owner, _assets, _shares);
    }

    function _beforeEpochStart() internal virtual {
        _executeSnapshot();
    }

    function _afterEpochStart() internal virtual {
        isTimelockInitiated = false;
    }

    function _beforeEpochEnd() internal virtual {
        if(!_areAssetsBack()) revert AssetsNotBack();

        _chargeFees();

        _executeSnapshot();
    }

    function _afterEpochEnd() internal virtual {
        totalAUM = asset.balanceOf(address(this));
    }

    function _executeSnapshot() internal virtual {
        snapshotSharesSupply = totalSupply;
        snapshotAssetBalance = totalAssets();

        emit Snapshot(block.timestamp,  snapshotAssetBalance, snapshotSharesSupply);
    }

    function _chargeFees() internal virtual {
        uint256 _snapshotAssetBalance = snapshotAssetBalance;
        address _asset = address(asset);
        uint256 _balance = IERC20(_asset).balanceOf(address(this));
        if (_balance > _snapshotAssetBalance && isPerformanceFeeEnabled == true) {
            uint256 _delta = _balance - _snapshotAssetBalance;
            
            // 1 / 5 = 20 / 100  --> (set 'managerPerformanceFee' to '5' to take 20% from profit)
            uint256 _managerFee = _delta / managerPerformanceFee;
            
            // cap performance fee by a % of TVL to disincentivize over risk taking
            // 1 / 5 = 20 / 100  --> (set 'performanceFeeLimit' to '5' to cap performance fee to 20% of TVL)
            if (_managerFee > _snapshotAssetBalance / performanceFeeLimit) {
                _managerFee = _snapshotAssetBalance / performanceFeeLimit;
            }
            
            // send performance fee to Vault Manager
            IERC20(_asset).safeTransfer(manager, _managerFee);
        }

        // send management fee to platform
        // 1 / 600 = 2 / (100 * 12) --> (set 'platformManagementFee' to '600' to charge 2% annually)
        IERC20(_asset).safeTransfer(platform, _snapshotAssetBalance / platformManagementFee);
    }

    function _areAssetsBack() internal view returns (bool) {
        address[] memory _assetVaultList = assetVaultList;
        for (uint256 i = 0; i < _assetVaultList.length; i++) {
            if (AssetVault(_assetVaultList[i]).areStrategiesActive()) return false;
        }
        return true;
    }

    function _onState(State _expectedState) internal view virtual {
        if (currentVaultState != _expectedState) revert InvalidState();
    }

    function _getCollateralImposedLimit() internal view returns (uint256) {
        if (isCollateralRequired) {
            if (balanceOf[address(this)] <= totalSupply / collateralRequirement) {
                return 0;
            } else {
                return  balanceOf[address(this)] * collateralRequirement - totalSupply;
            }
        } else {
            return type(uint256).max;
        }
    }

    function _approve(address _asset, address _spender, uint256 _amount) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, _amount);
    }
}