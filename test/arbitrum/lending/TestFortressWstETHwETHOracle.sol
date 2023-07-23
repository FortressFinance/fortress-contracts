// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "src/shared/interfaces/IWETH.sol";
import {FortressWstETHwETHOracle} from "src/shared/lending/oracles/FortressWstETHwETHOracle.sol";
import "test/arbitrum/lending/BaseTest.sol";
import "test/arbitrum/lending/ReentrancyTestAttacker.sol";

contract TestFortressWstETHwETHOracle is BaseTest {

    FortressWstETHwETHOracle oracle;
    address fcWstETHwETH = address(0x79636559F70Ffe7429A965a59B884B0eE9b1391C);

    function setUp() public {
        _setUp();
        
        oracle = new FortressWstETHwETHOracle(address(owner), fcWstETHwETH);
        
        (,int256 lastPrice,,,) = oracle.latestRoundData();
        console.log('oraclePrice:',uint256(lastPrice)/1e18);
    }

    /********************************** Tests **********************************/

    function testReenterancy() public {

        ReentrancyTestAttacker attacker;
        attacker = new ReentrancyTestAttacker(address(oracle));
        uint256 _amount = 50 * 1e18;

        vm.startPrank(alice);
        // deal(address(WETH), address(alice), _amount);
        deal(address(WETH), address(attacker), _amount);
        attacker.execReentrancy{value : 1e18}(_amount);
        console.log('duringReentrancyPrice:',attacker.getLastPrice()/1e18);
        (,int256 lastPrice,,,) = oracle.latestRoundData();
        console.log('afterAttack:',uint256(lastPrice)/1e18);
        vm.stopPrank();
    }

    function testVaultMaxSpread() public {
        
        uint256 _maxSpread = oracle.vaultMaxSpread();

        uint256 _spread = ERC4626(fcWstETHwETH).convertToAssets(1e18);

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