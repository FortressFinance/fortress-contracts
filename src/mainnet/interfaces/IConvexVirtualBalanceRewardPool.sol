// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IConvexVirtualBalanceRewardPool {
  function earned(address account) external view returns (uint256);
}
