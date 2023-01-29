// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseTest} from "./BaseTest.sol";

contract TestFortGlpStrategy is BaseTest {
    
    function setUp() public {
        
        _setUp(USDC);
    }

    function testSanity() public {
        assertTrue(true);
        _testInitVault();
    }
}
