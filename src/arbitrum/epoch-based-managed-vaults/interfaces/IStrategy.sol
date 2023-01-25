// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategy {

    /********************************** View Functions **********************************/

    /// @dev Indicates whether the strategy has deployed assets
    /// @return True if the strategy has deployed assets, false otherwise
    function isActive() public view returns (bool);

    /// @dev Indicates whether an asset is enabled for the strategy
    /// @param _asset The address of the asset to check
    /// @return True if the asset is enabled, false otherwise
    function isAssetEnabled(address _asset) public view returns (bool);

    /********************************** Asset Vault Functions **********************************/

    /// @dev Deposits assets into the strategy. Can only be called by the AssetVault
    /// @param _amount The amount of assets to deposit
    function deposit(uint256 _amount) external;

    /// @dev Withdraws assets from the strategy. Can only be called by the AssetVault
    /// @param _amount The amount of assets to withdraw
    function withdraw(uint256 _amount) public;

    /// @dev Withdraws all assets from the strategy. Can only be called by the AssetVault. Fails if the strategy is not ready to exit
    function withdrawAll() public;

    /********************************** Platform Functions **********************************/

    /// @dev Overrides the active status of the strategy. Can only be called by the platform
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

    /// @notice Emitted when the active status of the strategy is overriden
    /// @param _timestamp The timestamp of the override
    /// @param _isStrategiesActive The new active status of the strategy
    event ActiveStatusOverriden(uint256 indexed _timestamp, bool _isStrategiesActive);

    /********************************** Errors **********************************/

    error StrategyActive();
    error Unauthorized();
    error AmountMismatch();
    error StrategyActive();
}