// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/BaseTest.sol";

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC4626} from "@solmate/mixins/ERC4626.sol";

import {FortressGLPOracle} from "src/shared/lending/oracles/FortressGLPOracle.sol";

contract TestFortressGLPOracle is BaseTest {

    FortressGLPOracle oracle;

    uint256 maxPriceDeviationPercentage = 11; // 10%
    uint256 lastGlpPrice;

    function setUp() public {
        _setUp();

        uint256 _maxSpread = 1.1 ether; // 10%
        // uint256 _maxPriceDeviationPercentage = 20; // 20%
        oracle = new FortressGLPOracle(_maxSpread, address(owner));

        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();
        lastGlpPrice = uint256(_answer);
    }

    function testMaxSpread() public {
        vm.startPrank(owner);
        
        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();

        uint256 _currentSpread = ERC4626(oracle.fcGLP()).convertToAssets(1e18);
        oracle.updateMaxSpread(_currentSpread - 1);

        vm.expectRevert("vault spread too big");
        (, _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();

        vm.stopPrank();
    }

    function testMaxPriceDeviation() public {
        vm.startPrank(owner);

        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();
        revert("TODO");
        // vm.expectRevert("glp price too big");
        // _checkGlpPrice(uint256(_answer) * (maxPriceDeviationPercentage + 1) / 10);

        // // vm.expectRevert("glp price too small");
        // _checkGlpPrice(uint256(_answer) * 10 / (maxPriceDeviationPercentage + 1));

        // vm.stopPrank();
    }

    // mock
    // function _checkGlpPrice(uint256 _glpPrice) internal view {
    //     if (_glpPrice > (lastGlpPrice * maxPriceDeviationPercentage / 10)) revert("glp price too big");
    //     if (_glpPrice < (lastGlpPrice * 10 / (10 - (11 - 10)) maxPriceDeviationPercentage)) revert("glp price too small");
    // }
}