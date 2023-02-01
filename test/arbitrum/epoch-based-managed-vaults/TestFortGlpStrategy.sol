// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseTest} from "./BaseTest.sol";

contract TestFortGlpStrategy is BaseTest {
    
    function setUp() public {
        
        _setUp(USDC);
    }

    function testSanity(uint256 _epochDuration, uint256 _investorDepositAmount) public {
        vm.assume(_epochDuration < (type(uint256).max - block.timestamp));
        vm.assume(_epochDuration > 0);
        vm.assume(_investorDepositAmount > 1 ether && _investorDepositAmount < 10 ether);

        _initVault(_epochDuration);

        _addAssetVault(WETH);

        _letInvestorsDepositOnCollateralRequired(_investorDepositAmount);
        
        _startEpoch();

        // _manageAssetsVaults();
    }
}
