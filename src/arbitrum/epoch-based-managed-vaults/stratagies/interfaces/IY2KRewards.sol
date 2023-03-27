// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IY2KRewards {

    /// @dev Claims rewards from the rewards contract
    function getReward() external;

    /// @dev Stake the specified amount of tokens
    function stake(uint256 _amount) external;

    /// @dev Withdraw the specified amount of tokens
    function withdraw(uint256 _amount) external;
}