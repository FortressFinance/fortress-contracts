// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {Fortress2PoolOracle} from "src/shared/lending/oracles/Fortress2PoolOracle.sol";

import "test/arbitrum/lending/BaseTest.sol";

contract TestFortress2PoolOracle is BaseTest {

    Fortress2PoolOracle oracle;

    function setUp() public {
        _setUp();
        address fc2Pool = address(0xe16F15266cD00c418fB63e505361de32ce90Ac9f);
        oracle = new Fortress2PoolOracle(address(owner), fc2Pool);
        // (,int256 lastPrice,,,) = oracle.latestRoundData();
        // console.log('lastPrice:',uint256(lastPrice));
    }

    /********************************** Tests **********************************/

    function testVaultMaxSpread() public {
        
        uint256 _maxSpread = oracle.vaultMaxSpread();

        uint256 _spread = ERC4626(fc2Pool).convertToAssets(1e18);

        // add 10% to _spread
        uint256 _localMaxSpread = _spread * 110 / 100;

        assertEq(_maxSpread, _localMaxSpread, "testVaultMaxSpread: E1");
    }

    function testUpdateLastSharePrice() public {
        uint256 _lastSharePrice1 = oracle.lastSharePrice();
        
        (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();

        assertEq(_lastSharePrice1, uint256(_answer), "testUpdateLastSharePrice: E1");

        vm.startPrank(owner);
        oracle.updateLastSharePrice();
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        oracle.updateLastSharePrice();
        vm.stopPrank();

        uint256 _lastSharePrice2 = oracle.lastSharePrice();
        
        assertEq(_lastSharePrice2, uint256(_answer), "testUpdateLastSharePrice: E2");
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

    /********************************** Internal Functions **********************************/

    // mock - assumes 10% bounds
    function _checkPriceDeviation(uint256 _sharePrice, uint256 _lastSharePrice) internal pure {
        uint256 _lowerBound = (_lastSharePrice * (100 - 10)) / 100;
        uint256 _upperBound = (_lastSharePrice * (100 + 10)) / 100;

        if (_sharePrice < _lowerBound || _sharePrice > _upperBound) revert("priceDeviationTooHigh");

        // lastSharePrice = _sharePrice; 
    }

    
}