// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IGlpRewardTracker {

    function claimable(address _account) external view returns (uint256);
}