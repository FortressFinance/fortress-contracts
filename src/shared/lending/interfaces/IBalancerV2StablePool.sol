// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerV2StablePool {

    function getRate() external view returns (uint256 rate);

    function getVault() external view returns (address vault);

    function getPoolId() external view returns (bytes32 poolId);
}