// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IY2KVault {

    /// @dev See {IERC1155-balanceOf}
    /// @dev Returns the amount of tokens of token type `id` owned by `account`
    /// @param account - address of the account to check the balance of
    /// @param id - uint256 of the token type to check the balance of
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /// @dev Mints Vault shares to receiver by depositing exact amount of assets
    /// @param _assets - uint256 representing how many assets the user wants to deposit, a fee will be taken from this value
    /// @param _receiver - address of the receiver of the assets provided by this function, that represent the ownership of the deposited asset
    /// @param _id - uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    function deposit(uint256 _id, uint256 _assets, address _receiver) external;

    /// @dev Withdraw entitled deposited assets, checking if a depeg event
    /// @param _id - uint256 in UNIX timestamp, representing the end date of the epoch. Example: Epoch ends in 30th June 2022 at 00h 00min 00sec: 1654038000
    /// @param _assets - uint256 of how many assets you want to withdraw, this value will be used to calculate how many assets you are entitle to according to the events
    /// @param _receiver - Address of the receiver of the assets provided by this function, that represent the ownership of the transfered asset
    /// @param _owner - Address of the owner of these said assets
    /// @return _shares - How many shares the owner is entitled to, according to the conditions
    function withdraw(uint256 _id, uint256 _assets, address _receiver, address _owner) external returns (uint256 _shares);
}