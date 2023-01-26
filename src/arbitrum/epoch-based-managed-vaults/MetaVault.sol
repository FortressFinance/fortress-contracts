// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ERC4626, ERC20, FixedPointMathLib} from "src/shared/interfaces/ERC4626.sol";
import {AssetVault} from "./AssetVault.sol";

import {IMetaVault} from "./interfaces/IMetaVault.sol";
import {IFortressSwap} from "./interfaces/IFortressSwap.sol";

contract MetaVault is ReentrancyGuard, ERC4626, IMetaVault {

    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /// @notice The current state of the vault
    State public state = State.INITIAL;

    /// @notice The platform address
    address public platform;
    /// @notice The vault manager address
    address public manager;
    /// @notice The swap contract address
    address internal swap;
    /// @notice The internal accounting of the deposit limit. Denominated in shares.
    uint256 public depositCap;

    /// @notice The internal accounting of AUM.
    uint256 internal totalAUM;
    /// @notice Snapshot of total shares supply from previous epoch
    uint256 public snapshotSharesSupply;
    /// @notice Snapshot of total asset supply from previous epoch
    uint256 public snapshotAssetBalance;
    
    /// @notice The percentage of managment fee to pay for platform on AUM.
    uint256 public platformFeePercentage;
    /// @notice The percentage of performance fee to for Vault Manager on Epoch ending.
    uint256 public managerFeePercentage;
    /// @notice The percentage of fee to keep in vault on withdraw (distrebuted among vault participants).
    uint256 public withdrawFeePercentage;
    
    /// @notice The timelock delay, in seconds
    uint256 public delay;
    /// @notice The time that the timelock started.
    uint256 public timelock;
    /// @notice The time that the Epoch should end.
    uint256 public epochEnd;
    /// @notice Indicates whether the timelock has been initiated.
    bool public isTimelocked;
    /// @notice Indicates whether to punish on not finishing an Epoch at the specified time.
    bool public punish;
    /// @notice Indicates whether to charge a performance fee for Vault Manager.
    bool public chargeManagerFee;
    
    /// @notice Whether deposit for the pool is paused.
    bool public pauseDeposit;
    /// @notice Whether withdraw for the pool is paused.
    bool public pauseWithdraw;

    /// @notice The mapping of addresses of assets to AssetVaults.
    /// @dev AssetVaults are standalone contracts that hold the assets and allow for the execution of Stratagies.
    mapping(address => address) public assetVaults;
    /// @notice The mapping of blacklisted assets
    mapping(address => bool) public assetBlacklist;

    /// @notice The list of addresses of assets to AssetVaults.
    address[] public assetVaultsList;

    /// @notice The fee denominator.
    uint256 internal constant FEE_DENOMINATOR = 1e9;

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
        
        platformFeePercentage = 600; // 2% annually
        managerFeePercentage = 20; // 5%
        withdrawFeePercentage = 2000000; // 0.2%
        
        pauseDeposit = false;
        pauseWithdraw = false;
        isTimelocked = false;
        punish = true;
        chargeManagerFee = true;
        
        platform = _platform;
        manager = _manager;
        swap = _swap;
        depositCap = 0;
        delay = 86400; // 86400 seconds, 1 day
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
        if (state != State.UNMANAGED) return 0;

        return convertToShares(_assets);
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewMint(uint256 _shares) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        return convertToAssets(_shares);
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        uint256 assets = convertToAssets(_shares);

        uint256 _totalSupply = totalSupply;

        // Calculate a fee - zero if user is the last to withdraw
        uint256 _fee = (_totalSupply == 0 || _totalSupply - _shares == 0) ? 0 : assets.mulDivDown(withdrawFeePercentage, FEE_DENOMINATOR);

        // Redeemable amount is the post-withdrawal-fee amount
        return assets - _fee;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        uint256 _shares = convertToShares(_assets);

        uint256 _totalSupply = totalSupply;

        // Factor in additional shares to fulfill withdrawal fee if user is not the last to withdraw
        return (_totalSupply == 0 || _totalSupply - _shares == 0) ? _shares : (_shares * FEE_DENOMINATOR) / (FEE_DENOMINATOR - withdrawFeePercentage);
    }

    /// @inheritdoc ERC4626
    /// @notice May return an inaccurate response when 'state' is 'MANAGED' or 'INITIAL'
    function totalAssets() public view override returns (uint256) {
        return totalAUM;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxDeposit(address) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        uint256 _assetCap = convertToAssets(depositCap);
        return _assetCap == 0 ? type(uint256).max : _assetCap - totalAUM;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxMint(address) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        return depositCap == 0 ? type(uint256).max : depositCap - totalSupply;
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxWithdraw(address owner) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        return convertToAssets(balanceOf[owner]);
    }

    /// @inheritdoc ERC4626
    /// @notice Returns "0" if the Vault is not in an "UNMANAGED" state
    function maxRedeem(address owner) public view override returns (uint256) {
        if (state != State.UNMANAGED) return 0;

        return balanceOf[owner];
    }

    /// @inheritdoc IMetaVault
    function getSwap() public view returns (address) {
        return swap;
    }

    /// @inheritdoc IMetaVault
    function isUnmanaged() public view returns (bool) {
        return state == State.UNMANAGED;
    }

    /********************************** Investor Functions **********************************/

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function deposit(uint256 _assets, address _receiver) external override nonReentrant returns (uint256 _shares) {
        if (_assets >= maxDeposit(msg.sender)) revert InsufficientDepositCap();

        _shares = previewDeposit(_assets);

        _deposit(msg.sender, _receiver, _assets, _shares);

        return _shares;
    }

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function mint(uint256 _shares, address _receiver) external override nonReentrant returns (uint256 _assets) {
        if (_shares >= maxMint(msg.sender)) revert InsufficientDepositCap();

        _assets = previewMint(_shares);
        
        _deposit(msg.sender, _receiver, _assets, _shares);

        return _assets;
    }

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function withdraw(uint256 _assets, address _receiver, address _owner) external override nonReentrant returns (uint256 _shares) {
        if (_assets > maxWithdraw(_owner)) revert InsufficientBalance();

        _shares = previewWithdraw(_assets);
        
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        return _shares;
    }

    /// @inheritdoc ERC4626
    /// @notice Can only be called by anyone while "state" is "UNMANAGED"
    function redeem(uint256 _shares, address _receiver, address _owner) external override nonReentrant returns (uint256 _assets) {
        if (_shares > maxRedeem(_owner)) revert InsufficientBalance();

        _assets = previewRedeem(_shares);
        
        _withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        return _assets;
    }

    /// @inheritdoc IMetaVault
    function punishLateness() external nonReentrant {
        if (punish == false) revert LatenessNotPunished();
        if (block.timestamp < epochEnd) revert EpochNotEnded();
        
        _onState(State.MANAGED);

        chargeManagerFee = false;

        emit LatenessPunished(block.timestamp);
    }

    /********************************** Manager Functions **********************************/

    /// @inheritdoc IMetaVault
    function initVault(uint256 _epochEnd, bool _punish, bool _chargeFee) external virtual onlyManager {
        _onState(State.INITIAL);

        state = State.UNMANAGED;
        requestStartEpoch(_epochEnd, _punish, _chargeFee);

        emit EpochEnded(block.timestamp, 0, 0);
    }

    /// @inheritdoc IMetaVault
    function requestStartEpoch(uint256 _epochEnd, bool _punish, bool _chargeFee) public onlyManager nonReentrant {
        _onState(State.UNMANAGED);

        timelock = block.timestamp;
        isTimelocked = true;
        epochEnd = _epochEnd;
        punish = _punish;
        chargeManagerFee = _chargeFee;

        emit EpochRequested(block.timestamp, _epochEnd, _punish, _chargeFee);
    }

    /// @inheritdoc IMetaVault
    function startEpoch() external onlyManager nonReentrant {
        if (isTimelocked == false) revert NotTimelocked();
        if (timelock + delay > block.timestamp) revert TimelockNotExpired();
        
        _onState(State.UNMANAGED);

        _beforeEpochStart();

        state = State.MANAGED;

        emit EpochStarted(block.timestamp, snapshotAssetBalance, snapshotSharesSupply);

        _afterEpochStart();
    }

    /// @inheritdoc IMetaVault
    function endEpoch() external onlyManager nonReentrant {
        _onState(State.MANAGED);

        _beforeEpochEnd();

        state = State.UNMANAGED;

        emit EpochEnded(block.timestamp, snapshotAssetBalance, snapshotSharesSupply);

        _afterEpochEnd();
    }

    /// @inheritdoc IMetaVault
    function addAssetVault(address _targetAsset) external onlyManager nonReentrant returns (address _assetVault) {
        if (!IFortressSwap(swap).routeExists(address(asset), _targetAsset)) revert SwapRouteNotFound();
        if (assetBlacklist[_targetAsset]) revert AssetBlacklisted();
        
        _onState(State.UNMANAGED);

        _assetVault = address(new AssetVault(_targetAsset, address(this), address(asset), platform, manager));
        
        assetVaults[_targetAsset] = _assetVault;
        assetVaultsList.push(_assetVault);

        emit AssetVaultAdded(_assetVault, _targetAsset);

        return _assetVault;
    }

    /// @inheritdoc IMetaVault
    function depositToAssetVault(address _asset, uint256 _amount, uint256 _minAmount) external onlyManager nonReentrant returns (uint256) {
        if (assetBlacklist[_asset]) revert AssetBlacklisted();
        
        _onState(State.MANAGED);

        address _assetVault = assetVaults[_asset];
        if (_assetVault == address(0)) revert AssetVaultNotFound();

        _approve(_asset, _assetVault, _amount);
        _amount = AssetVault(_assetVault).deposit(_amount);
        if (_amount < _minAmount) revert InsufficientAmountOut();

        emit DepositedToAssetVault(_assetVault, _asset, _amount);

        return _amount;
    }

    /// @inheritdoc IMetaVault
    function withdrawFromAssetVault(address _asset, uint256 _amount, uint256 _minAmount) external onlyManager nonReentrant returns (uint256) {
        _onState(State.MANAGED);

        address _assetVault = assetVaults[_asset];
        if (_assetVault == address(0)) revert AssetVaultNotFound();

        _amount = AssetVault(_assetVault).withdraw(_amount);
        if (_amount < _minAmount) revert InsufficientAmountOut();

        emit WithdrawnFromAssetVault(_assetVault, _asset, _amount);

        return _amount;
    }

    /// @inheritdoc IMetaVault
    function setPerformanceFee(uint256 _performanceFee) external onlyManager {
        _onState(State.UNMANAGED);

        managerFeePercentage = _performanceFee;

        emit SetPerformanceFee(_performanceFee);
    }

    /// @inheritdoc IMetaVault
    function setManager(address _manager) external onlyManager {
        _onState(State.UNMANAGED);

        manager = _manager;
    }

    /********************************** Platform Functions **********************************/

    /// @inheritdoc IMetaVault
    function setFees(uint256 _platformFeePercentage, uint256 _withdrawFeePercentage) external onlyPlatform {
        _onState(State.UNMANAGED);

        platformFeePercentage = _platformFeePercentage;
        withdrawFeePercentage = _withdrawFeePercentage;

        emit SetFees(_platformFeePercentage, _withdrawFeePercentage);
    }

    /// @inheritdoc IMetaVault
    function setPauseInteraction(bool _pauseDeposit, bool _pauseWithdraw) external onlyPlatform {
        pauseDeposit = _pauseDeposit;
        pauseWithdraw = _pauseWithdraw;

        emit PauseInteractions(_pauseDeposit, _pauseWithdraw);
    }

    /// @inheritdoc IMetaVault
    function setSettings(State _state, address _swap, uint256 _depositCap, uint256 _delay) external onlyPlatform {
        _onState(State.UNMANAGED);

        state = _state;
        swap = _swap;
        depositCap = _depositCap;
        delay = _delay;

        emit SetSettings(_state, _swap, _depositCap, _delay);
    }

    /// @inheritdoc IMetaVault
    function setBlacklistAsset(address _asset) external onlyPlatform {
        _onState(State.UNMANAGED);

        assetBlacklist[_asset] = true;

        emit SetBlacklistAsset(_asset);
    }

    /********************************** Internal Functions **********************************/

    function _deposit(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal override {
        if (pauseDeposit) revert DepositPaused();
        if (_receiver == address(0)) revert ZeroAddress();
        if (!(_assets > 0)) revert ZeroAmount();
        if (!(_shares > 0)) revert ZeroAmount();

        _onState(State.UNMANAGED);

        _mint(_receiver, _shares);
        totalAUM += _assets;

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    function _withdraw(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) internal override {
        if (pauseWithdraw) revert WithdrawPaused();
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

        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    function _beforeEpochStart() internal virtual {
        _executeSnapshot();
    }

    function _afterEpochStart() internal virtual {
        isTimelocked = false;
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
        if (_balance > _snapshotAssetBalance && chargeManagerFee == true) {
            // send performance fee to Vault Manager
            // 1 / 5 = 20 / 100  --> (use '5' to take 20% from profit)
            IERC20(_asset).safeTransfer(manager, (_balance - _snapshotAssetBalance) / managerFeePercentage);
        }

        // send management fee to platform
        // 1 / 600 = 2 / (100 * 12) --> (2% annually)
        IERC20(_asset).safeTransfer(platform, _snapshotAssetBalance / platformFeePercentage);
    }

    function _areAssetsBack() internal view returns (bool) {
        address[] memory _assetVaultsList = assetVaultsList;
        for (uint256 i = 0; i < _assetVaultsList.length; i++) {
            if (AssetVault(_assetVaultsList[i]).isStrategiesActive()) return false;
        }
        return true;
    }

    function _onState(State _expectedState) internal view virtual {
        if (state != _expectedState) revert InvalidState();
    }

    function _approve(address _asset, address _spender, uint256 _amount) internal {
        IERC20(_asset).safeApprove(_spender, 0);
        IERC20(_asset).safeApprove(_spender, _amount);
    }
}