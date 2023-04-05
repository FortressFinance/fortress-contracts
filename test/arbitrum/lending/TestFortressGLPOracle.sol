// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/BaseTest.sol";

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC4626} from "@solmate/mixins/ERC4626.sol";

import {FortressGLPOracle} from "src/shared/lending/oracles/FortressGLPOracle.sol";

contract TestFortressGLPOracle is BaseTest {

    FortressGLPOracle oracle;

    function setUp() public {
        _setUp();

        uint256 _maxSpread = 1.1 ether; // 10%
        oracle = new FortressGLPOracle(_maxSpread, address(owner));
    }

    function testMaxSpread() public {
        vm.startPrank(owner);
        
        uint256 _currentSpread = ERC4626(oracle.fcGLP()).convertToAssets(1e18);
        console.log("_currentSpread: ", _currentSpread);
        oracle.updateMaxSpread(_currentSpread - 1);

        vm.stopPrank();

        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();
        console.log("_answer: ", uint256(_answer));
        revert("stop");
    }
}