// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMetaVault {

    /// @notice Enum to represent the current state of the vault
    /// @dev INITIAL = Right after deployment, can move to `UNMANAGED` by calling 'initVault'
    /// @dev UNMANAGED = Users are able to interact with the vault, can move to `MANAGED` by calling 'startEpoch'
    /// @dev MANAGED = Strategies will be able to borrow & repay, can move to `UNMANAGED` by calling 'endEpoch'
    enum State {
        INITIAL,
        UNMANAGED,
        MANAGED
    }

    /********************************** View Functions **********************************/
    
    /// @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    /// @param _assets - The amount of assets to deposit
    /// @return - The amount of shares to mint
    function previewDeposit(uint256 _assets) public view returns (uint256);

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    /// @param _shares - The amount of shares to mint
    /// @return - The amount of assets to deposit
    function previewMint(uint256 _shares) public view returns (uint256);

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    /// @param _shares - The amount of shares to redeem
    /// @return - The amount of assets in return, after subtracting a withdrawal fee
    function previewRedeem(uint256 _shares) public view returns (uint256);

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    /// @param _assets - The amount of assets to withdraw
    /// @return - The amount of shares to burn, after subtracting a fee
    function previewWithdraw(uint256 _assets) public view returns (uint256);

    /// @dev Returns the total AUM
    /// @dev 'totalAssets' may be inaccurate when 'state' is 'MANAGED' or 'INITIAL'
    /// @return - The total AUM
    function totalAssets() public view returns (uint256);

    /// @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    function maxDeposit(address) public view returns (uint256);

    /// @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    function maxMint(address) public view returns (uint256);

    /// @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a withdraw call
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    function maxWithdraw(address owner) public view returns (uint256);

    /// @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call
    /// @dev Returns "0" if the Vault is in an "MANAGED" state
    function maxRedeem(address owner) public view returns (uint256);

    /********************************** Investor Functions **********************************/

    /// @dev Mints vault shares to _receiver by depositing exact amount of assets. Can only be called by anyone while "state" is "UNMANAGED"
    /// @param _assets - The amount of assets to deposit
    /// @param _receiver - The receiver of minted shares
    /// @return _shares - The amount of shares minted
    function deposit(uint256 _assets, address _receiver) external returns (uint256 _shares);

    /// @dev Mints exact vault shares to _receiver by depositing assets. Can only be called by anyone while "state" is "UNMANAGED"
    /// @param _shares - The amount of shares to mint
    /// @param _receiver - The address of the receiver of shares
    /// @return _assets - The amount of assets deposited
    function mint(uint256 _shares, address _receiver) external returns (uint256 _assets);

    /// @dev Burns shares from owner and sends exact amount of assets to _receiver. Can only be called by anyone while "state" is "UNMANAGED"
    /// @param _assets - The amount of assets to receive
    /// @param _receiver - The address of the receiver of assets
    /// @param _owner - The owner of shares
    /// @return _shares - The amount of shares burned
    function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 _shares);

    /// @dev Burns exact amount of shares from owner and sends assets to _receiver. Can only be called by anyone while "state" is "UNMANAGED"
    /// @param _shares - The amount of shares to burn
    /// @param _receiver - The address of the receiver of assets
    /// @param _owner - The owner of shares
    /// @return _assets - The amount of assets sent to the _receiver
    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _assets);

    /// @dev Cancels the charging of a performance fee for Vault Manager. Used in order to incentivize Vault Managers to end the epoch in the specified time. Can only be called by anyone while "state" is "MANAGED"
    function punishLateness() external;

    /********************************** Manager Functions **********************************/

    /// @dev Opens vault for deposits and claims and requests to start an epoch. Can only be called by the Vault Manager while state is "INITIAL"
    /// @param _epochEnd - The expected end of the epoch
    /// @param _punish - Whether to punish the Vault Manager for lateness
    /// @param _chargeFee - Whether to charge a performance fee
    function initVault(uint256 _epochEnd, bool _punish, bool _chargeFee) external;

    /// @dev Requests the start of a new epoch. Can only be called by the Vault Manager while state is "UNMANAGED"
    /// @param _epochEnd - The expected end of the epoch
    /// @param _punish - Whether to punish the Vault Manager for lateness
    /// @param _chargeFee - Whether to charge a performance fee
    function requestStartEpoch(uint256 _epochEnd, bool _punish, bool _chargeFee) public;

    /// @dev Starts a new epoch. Can only be called by the Vault Manager while state is "UNMANAGED" and after the timelock has passed
    function startEpoch() external;

    /// @dev Ends the current epoch. Can only be called by the Vault Manager while state is "MANAGED" and if all assets are back
    function endEpoch() external;

    /// @dev Adds a new AssetVault. Can only be called by the Vault Manager while state is "UNMANAGED" and if FortressSwap supports the asset + asset is not blacklisted
    /// @param _asset - The address of the asset (ERC20 token)
    function addAssetVault(address _asset) external returns (address _assetVault);

    /// @dev Deposit assets to the AssetVault. Can only be called by the Vault Manager while state is "UNMANAGED" and if the asset is supported + not blacklisted
    /// @param _asset - The address of the asset
    /// @param _amount - The amount of assets to deposit
    /// @param _minAmount - The minimum amount of VaultAsset assets to deposit
    function depositToAssetVault(address _asset, uint256 _amount, uint256 _minAmount) external returns (uint256);

    /// @dev Withdraw assets from the AssetVault. Can only be called by the Vault Manager while state is "UNMANAGED" and if the asset is supported
    /// @param _asset - The address of the asset
    /// @param _amount - The amount of VaultAsset assets to withdraw
    /// @param _minAmount - The minimum amount of assets to withdraw
    function withdrawFromAssetVault(address _asset, uint256 _amount, uint256 _minAmount) external returns (uint256);

    /// @dev Sets a new performance fee. Can only be called by the Vault Manager while state is "UNMANAGED"
    /// @param _performanceFee - The new performance fee amount
    function setPerformanceFee(uint256 _performanceFee) external;

    /// @dev Sets a new Vault Manager. Can only be called by the Vault Manager while state is "UNMANAGED"
    /// @param _manager - The new Vault Manager
    function setManager(address _manager) external;

    /********************************** Platform Functions **********************************/

    /// @dev Sets platform and withdrawal fees. Can only be called by the Platform while "state" is "UNMANAGED"
    /// @param _platformFeePercentage - The new platform fee percentage
    /// @param _withdrawFeePercentage - The new withdraw fee percentage
    function setFees(uint256 _platformFeePercentage, uint256 _withdrawFeePercentage) external;

    /// @dev Sets the pauseDeposit and pauseWithdraw. Can only be called by the Platform
    /// @param _pauseDeposit - Whether to pause deposits
    /// @param _pauseWithdraw - Whether to pause withdrawals
    function setPauseInteraction(bool _pauseDeposit, bool _pauseWithdraw) external;

    /// @dev Sets some Vault settings. Can only be called by the Platform while "state" is "UNMANAGED"
    /// @param _state - The new Vault state
    /// @param _swap - The new FortressSwap address
    /// @param _depositCap - The new deposit cap
    /// @param _delay - The new timelock delay
    function setSettings(State _state, address _swap, uint256 _depositCap, uint256 _delay) external;

    /// @dev Blacklists an asset. Can only be called by the Platform while "state" is "UNMANAGED"
    /// @param _asset - The address of the asset to blacklist
    function setBlacklistAsset(address _asset) external;

    /********************************** Events **********************************/

    /// @notice emitted when a deposit is made
    /// @param _caller - The address of the depositor
    /// @param _receiver - The address of the receiver of shares
    /// @param _assets - The amount of assets deposited
    /// @param _shares - The amount of shares received
    event Deposit(address indexed _caller, address indexed _receiver, uint256 _assets, uint256 _shares);

    /// @notice emitted when a withdraw is made
    /// @param _caller - The address of the withdrawer
    /// @param _receiver - The address of the receiver of assets
    /// @param _owner - The address if the owner of shares
    /// @param _assets - The amount of assets withdrawn
    /// @param _shares - The amount of shares burned
    event Withdraw(address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares);

    /// @notice emitted when "setFees" function is called
    /// @param _platformFeePercentage - The new platform fee percentage
    /// @param _withdrawFeePercentage - The new withdraw fee percentage
    event SetFees(uint256 _platformFeePercentage, uint256 _withdrawFeePercentage);

    /// @notice emitted when "setPauseInteractions" function is called
    /// @param _pauseDeposit - Whether to pause deposits
    /// @param _pauseWithdraw - Whether to pause withdrawals
    event SetPauseInteractions(bool _pauseDeposit, bool _pauseWithdraw);

    /// @notice emitted when "setSettings" function is called
    /// @param _state - The new Vault state
    /// @param _swap - The new FortressSwap address
    /// @param _depositCap - The new deposit cap
    /// @param _delay - The new timelock delay
    event SetSettings(State _state, address _swap, uint256 _depositCap, uint256 _delay);

    /// @notice emitted when "setBlacklistAsset" function is called
    /// @param _asset - The address of the asset to blacklist
    event SetBlacklistAsset(address indexed _asset);

    /// @notice emitted when "setPerformanceFee" function is called
    /// @param _performanceFee - The new performance fee amount
    event SetPerformanceFee(uint256 _performanceFee);

    /// @notice emitted when "setManager" function is called
    /// @param _manager - The new Vault Manager
    event SetManager(address indexed _manager);

    /// @notice emitted when "punishLateness" function is called
    /// @param _timestamp - The timestamp at call time
    event LatenessPunished(uint256 indexed _timestamp);

    /// @notice emitted when "requestStartEpoch" function is called
    /// @param _timestamp - The timestamp at call time
    /// @param _epochEnd - The timestamp of the end of the epoch
    /// @param _punish - Whether to punish late epoch end
    /// @param _chargeFee - Whether to charge a performance fee
    event EpochRequested(uint256 indexed _timestamp, uint256 _epochEnd, bool _punish, bool _chargeFee);

    /// @notice emitted when an epoch has ended
    /// @param _timestamp The timestamp of epoch end (indexed)
    /// @param _assetBalance The asset balance at this time
    /// @param _shareSupply The share balance at this time
    event EpochEnded(uint256 indexed _timestamp, uint256 _assetBalance, uint256 _shareSupply);

    /// @notice emitted when an epoch has started
    /// @param _timestamp The timestamp of epoch start (indexed)
    /// @param _assetBalance The asset balance at this time
    /// @param _shareSupply The share balance at this time
    event EpochStarted(uint256 indexed _timestamp, uint256 _assetBalance, uint256 _shareSupply);

    /// @notice emitted when a new AssetVault is added
    /// @param _assetVault The address of the new AssetVault
    /// @param _asset The address of the asset
    event AssetVaultAdded(address indexed _assetVault, address indexed _asset);

    /// @notice emitted when a deposit is made to an AssetVault
    /// @param _assetVault The address of the AssetVault
    /// @param _asset The address of the asset
    /// @param _amount The amount of AssetVault assets deposited
    event DepositedToAssetVault(address indexed _assetVault, address indexed _asset, uint256 _amount);

    /// @notice emitted when a withdraw is made from an AssetVault
    /// @param _assetVault The address of the AssetVault
    /// @param _asset The address of the asset
    /// @param _amount The amount of assets withdrawn
    event WithdrawnFromAssetVault(address indexed _assetVault, address indexed _asset, uint256 _amount);

    /// @notice emitted when vault balance snapshot is taken
    /// @param _timestamp The snapshot timestamp (indexed)
    /// @param _assetBalance The asset balance at this time
    /// @param _shareSupply The share balance at this time
    event Snapshot(uint256 indexed _timestamp, uint256 _assetBalance, uint256 _shareSupply);

    /********************************** Errors **********************************/

    error InvalidState();
    error DepositPaused();
    error WithdrawPaused();
    error InsufficientDepositCap();
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error InsufficientAmountOut();
    error LatenessNotPunished();
    error EpochNotEnded();
    error SwapRouteNotFound();
    error AssetBlacklisted();
    error AssetVaultNotFound();
    error NotTimelocked();
    error TimelockNotExpired();
    error Unauthorized();
}