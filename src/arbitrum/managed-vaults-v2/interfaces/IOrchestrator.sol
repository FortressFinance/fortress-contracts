// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOrchestrator {

    // ============================================================================================
    // View Functions
    // ============================================================================================

    // ============================================================================================
    // Mutated Functions
    // ============================================================================================

    // Manager

    function registerVault(address _primaryToken, string calldata _description) external returns (bytes32 _vaultKey);

    function startEpoch(uint256 _epochDuration, bytes32 _vaultKey) external;

    function endEpoch(bytes32 _vaultKey) external;

    function manageVault(bytes32 _vaultKey) external;

    // Investor

    function deposit(uint256 _amount, bytes32 _vaultKey) external;

    function withdraw(uint256 _amount, bytes32 _vaultKey) external;

    function executePenalty(bytes32 _vaultKey) external; // penalty for manager not ending epoch on time

    // Owner

    function registerToken(address _token) external;

    function registerStrategy() external returns ();

    function rescueTokens(uint256 _amount, address _token, address _receiver) external;

    function rescueVaultTokens(uint256 _amount, address _token, address _receiver, bytes32 _vaultKey) external;

    function freezeVault(bytes32 _vaultKey, bool _freeze) external;
    
    function setVaultFactory(address _factory) external;

    function setTimelock(address _timelock) external; // timelock for starting an epoch

    function setRequiredCollateral(uint256 _requiredCollateral, bytes32 _vaultKey) external; // require manager to own x% of vault

    function setPrimaryTokens(address[] calldata _primaryTokens) external;

    function pause(bool _pause) external;

    // ============================================================================================
    // Events
    // ============================================================================================

    // ============================================================================================
    // Errors
    // ============================================================================================

}