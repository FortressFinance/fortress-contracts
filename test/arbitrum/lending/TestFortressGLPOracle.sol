// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FortressGLPOracle} from "src/shared/lending/oracles/FortressGLPOracle.sol";

import "test/arbitrum/concentrators/BaseTest.sol";

contract TestFortressGLPOracle is BaseTest {

    FortressGLPOracle oracle;

    function setUp() public {
        _setUp();

        oracle = new FortressGLPOracle(address(owner));
    }

    function testDownSidePriceDeviation() public {
        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();

        uint256 _minPrice = uint256(_answer) * (100 - 10) / 100;

        vm.expectRevert("priceDeviationTooHigh");
        _checkPriceDeviation(_minPrice - 1, uint256(_answer));
    }

    function testUpSidePriceDeviation() public {
        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();

        uint256 _maxPrice = uint256(_answer) * (100 + 10) / 100;

        vm.expectRevert("priceDeviationTooHigh");
        _checkPriceDeviation(_maxPrice + 1, uint256(_answer));
    }

    // mock - assumes 10% bounds
    function _checkPriceDeviation(uint256 _sharePrice, uint256 _lastSharePrice) internal view {
        uint256 _lowerBound = (_lastSharePrice * (100 - 10)) / 100;
        uint256 _upperBound = (_lastSharePrice * (100 + 10)) / 100;

        if (_sharePrice < _lowerBound || _sharePrice > _upperBound) revert("priceDeviationTooHigh");

        // lastSharePrice = _sharePrice; 
    }
}