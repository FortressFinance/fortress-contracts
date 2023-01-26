// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAssetVault {

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

    /// @dev Indicates whether assets are deployed in a specific strategy
    /// @param _strategy The address of the strategy
    /// @return True if assets are deployed in the strategy, false otherwise
    function isStrategyActive(address _strategy) external view returns (bool);

    /// @dev Indicates whether assets are deployed in any strategy
    /// @return True if assets are deployed in any strategy, false otherwise
    function isStrategiesActive() external view returns (bool);

    /// @dev Returns the address of the VaultAsset asset
    function getAsset() external view returns (address);

    /********************************** Meta Vault Functions **********************************/

    /// @dev Deposits assets into the AssetVault
    /// @param _amount The amount of assets to deposit, in metaVaultAsset
    /// @return _amountIn The amount of assets deposited, in asset
    function deposit(uint256 _amount) external returns (uint256 _amountIn);

    /// @dev Withdraws assets from the AssetVault
    /// @param _amount The amount of assets to withdraw, in asset
    /// @return _amountOut amount of assets withdrawn, in metaVaultAsset
    function withdraw(uint256 _amount) external returns (uint256 _amountOut);

    /********************************** Manager Functions **********************************/

    /// @dev Deposits assets into a strategy. Can only be called by the manager
    /// @param _strategy The address of the strategy
    /// @param _amount The amount of assets to deposit
    function depositToStrategy(address _strategy, uint256 _amount) external;

    /// @dev Withdraws assets from a strategy. Can only be called by the manager
    /// @param _strategy The address of the strategy
    /// @param _amount The amount of assets to withdraw
    function exitStrategy(address _strategy, uint256 _amount) external;

    /// @dev Withdraws all assets from all strategy. Fails if any strategy is not ready to exit. Can only be called by the manager
    function exitStratagies() external;

    /// @dev Initiate the timelock to add a new strategy contract. Can only be called by the manager
    function requestAddStrategy() external;

    /// @dev Add a new strategy contract. Can only be called by the manager and after the timelock has expired
    function addStrategy(address _strategy) external;

    /// @dev Sets a new Vault Manager. Can only be called by the Vault Manager while state is "UNMANAGED"
    /// @param _manager - The new Vault Manager
    function setManager(address _manager) external;

    /********************************** Platform Functions **********************************/

    /// @dev Set the timelock delay period. Can only be called by the platform
    function setTimelockDelay(uint256 _delay) external;

    /// @dev Add a new strategy contract. Can only be called by the platform
    function platformAddStrategy(address _strategy) external;

    /// @dev Override the stratagies status of the AssetVault. Can only be called by the platform
    function overrideActiveStatus(bool _isStrategiesActive) external;

    /********************************** Events **********************************/

    /// @notice Emitted when a deposit is made
    /// @param _timestamp The timestamp of the deposit
    /// @param _amount The amount of assets deposited
    event Deposit(uint256 indexed _timestamp, uint256 _amount);

    /// @notice Emitted when a withdrawal is made
    /// @param _timestamp The timestamp of the withdrawal
    /// @param _amount The amount of assets withdrawn
    event Withdraw(uint256 indexed _timestamp, uint256 _amount);

    /// @notice Emitted when assets are deposited into a strategy
    /// @param _timestamp The timestamp of the deposit
    /// @param _strategy The address of the strategy
    /// @param _amount The amount of assets deposited
    event DepositedToStrategy(uint256 indexed _timestamp, address _strategy, uint256 _amount);

    /// @notice Emitted when assets are withdrawn from a strategy
    /// @param _timestamp The timestamp of the withdrawal
    /// @param _strategy The address of the strategy
    /// @param _amount The amount of assets withdrawn
    event WithdrawnFromStrategy(uint256 indexed _timestamp, address _strategy, uint256 _amount);
    
    /// @notice Emitted when an epoch is ended
    /// @param _timestamp The timestamp of the epoch end
    event EpochEnded(uint256 indexed _timestamp);

    /// @notice Emitted when a timelock is initiated to add a new strategy
    /// @param _timestamp The timestamp of the timelock initiation
    event AddStrategyRequested(uint256 indexed _timestamp);

    /// @notice Emitted when a new strategy is added
    /// @param _timestamp The timestamp of the strategy addition
    /// @param _strategy The address of the strategy
    event StrategyAdded(uint256 indexed _timestamp, address _strategy);

    /// @notice Emitted when the timelock delay is set
    /// @param _timestamp The timestamp of the timelock delay set
    /// @param _delay The timelock delay
    event TimelockDelaySet(uint256 indexed _timestamp, uint256 _delay);

    /// @notice Emitted when platform overrides the active status of the AssetVault
    /// @param _timestamp The timestamp of the active status override
    /// @param _isStrategiesActive The new active status of the AssetVault
    event ActiveStatusOverriden(uint256 indexed _timestamp, bool _isStrategiesActive);

    /********************************** Errors **********************************/

    error InvalidState();
    error StrategyNotActive();
    error StrategyMismatch();
    error AmountMismatch();
    error NotTimelocked();
    error TimelockNotExpired();
    error Unauthorized();
}