// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategy {


    /********************************** Asset Vault Functions **********************************/

    /// @dev Executes the strategy
    function execute() external;

    /// @dev Stopes strategy and withdraws all funds into fortETH contract
    function terminateExecution() external;
    
    /// @dev Deposits assets into the strategy. 
    /// @param _amount The amount of assets to deposit
    function deposit(uint256 _amount) external;

    /// @dev Withdraws assets from the strategy. 
    /// @param _amount The amount of assets to withdraw
    function withdraw(uint256 _amount) external;

    /// @dev Withdraws all assets from the strategy. 
    function withdrawAll() external;

    /********************************** Platform Functions **********************************/

    /// @dev Rescues stuck ERC20 tokens. Can only be called by the platform
    function rescueERC20(uint256 _amount) external;

    /********************************** Events **********************************/

    /// @notice Emitted when a deposit is made
    /// @param _timestamp The timestamp of the deposit
    /// @param _amount The amount of assets deposited
    event Deposit(uint256 indexed _timestamp, uint256 _amount);

    /// @notice Emitted when a withdrawal is made
    /// @param _timestamp The timestamp of the withdrawal
    /// @param _amount The amount of assets withdrawn
    event Withdraw(uint256 indexed _timestamp, uint256 _amount);

    /// @notice Emitted when the active status of the strategy is overriden
    /// @param _timestamp The timestamp of the override
    /// @param _isStrategiesActive The new active status of the strategy
    event ActiveStatusOverriden(uint256 indexed _timestamp, bool _isStrategiesActive);

    /// @notice Emitted when Platform rescues stuck assets
    /// @param _amount The amount of assets rescued
    event Rescue(uint256 _amount);
    
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

    /********************************** Errors **********************************/

    error Unauthorized();
    error AmountMismatch();
    error StrategyActive();
    error NonExistent();
    error ZeroAmount();
    error IncorrectWeight();
}