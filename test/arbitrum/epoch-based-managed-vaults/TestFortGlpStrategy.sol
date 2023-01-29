// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseTest} from "./BaseTest.sol";

contract TestFortGlpStrategy is BaseTest {
    
    function setUp() public {
        
        _setUp(USDC);
    }

    function testSanity() public {
        assertTrue(true);
        uint256 _timeLockDuration = 1000000;
        _initVault(_timeLockDuration);

        _addAssetVault(WETH);
        
        _startEpoch();
    }
}
