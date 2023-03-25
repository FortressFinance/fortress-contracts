// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IY2KVaultFactory {

    /// @dev Function the retrieve the addresses of the hedge and risk vaults, in an array, in the respective order
    /// @param _index - uint256 of the market index which to the vaults are associated to
    /// @return _vaults - Address array of two vaults addresses, [0] being the hedge vault, [1] being the risk vault
    function getVaults(uint256 _index) external returns (address[] memory _vaults);
}