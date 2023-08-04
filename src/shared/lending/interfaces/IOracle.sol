// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

interface IOracle {

  function latestRoundData()
    external
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}