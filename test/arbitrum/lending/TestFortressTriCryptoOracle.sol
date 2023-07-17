// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FortressTriCryptoOracle} from "src/shared/lending/oracles/FortressTriCryptoOracle.sol";

import "test/arbitrum/lending/BaseTest.sol";

contract TestFortressTriCryptoOracle is BaseTest {

    FortressTriCryptoOracle oracle;

    function setUp() public {
        _setUp();
        address _fcTriCrypto = address(0x32ED4f40ce345Eca65F24735Ad9D35c7fF3460E5);
        oracle = new FortressTriCryptoOracle(address(owner), _fcTriCrypto);
        (,int256 lastPrice,,,) = oracle.latestRoundData();
        console.log('lastPrice:',uint256(lastPrice)/1e18);
    }

    /********************************** Tests **********************************/

    function testVaultMaxSpread() public {
        
        uint256 _maxSpread = oracle.vaultMaxSpread();


        uint256 _spread = ERC4626(fcTriCrypto).convertToAssets(1e18);

        // add 10% to _spread
        uint256 _localMaxSpread = _spread * 110 / 100;

        assertEq(_maxSpread, _localMaxSpread, "testVaultMaxSpread: E1");
    }

    function testUpdateLastSharePrice() public {
        uint256 _lastSharePrice1 = oracle.lastSharePrice();
        
        // (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();

        // assertEq(_lastSharePrice1, uint256(_answer), "testUpdateLastSharePrice: E1");
        console.log('lastPrice:',_lastSharePrice1);

        vm.startPrank(owner);
        oracle.updateLastSharePrice();
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        oracle.updateLastSharePrice();
        vm.stopPrank();

        uint256 _lastSharePrice2 = oracle.lastSharePrice();
        console.log('lastPrice:',_lastSharePrice2);
        // assertEq(_lastSharePrice2, uint256(_answer), "testUpdateLastSharePrice: E2");
    }

    function testDownSidePriceDeviation() public {
        // (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();
        uint256 _lastSharePrice = oracle.lastSharePrice();
        uint256 _minPrice = _lastSharePrice * (100 - 10) / 100;

        vm.expectRevert("priceDeviationTooHigh");
        _checkPriceDeviation(_minPrice - 1, _lastSharePrice);
    }

    function testUpSidePriceDeviation() public {
        // (, int256 _answer,,,) = AggregatorV3Interface(address(oracle)).latestRoundData();
        uint256 _lastSharePrice = oracle.lastSharePrice();
        uint256 _maxPrice = _lastSharePrice * (100 + 10) / 100;

        vm.expectRevert("priceDeviationTooHigh");
        _checkPriceDeviation(_maxPrice + 1, _lastSharePrice);
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