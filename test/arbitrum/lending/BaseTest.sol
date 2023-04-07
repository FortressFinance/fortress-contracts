// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ERC4626, ERC20} from "@solmate/mixins/ERC4626.sol";

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {FortressArbiSwap} from "src/arbitrum/utils/FortressArbiSwap.sol";
import {AddressesArbi} from "script/arbitrum/utils/AddressesArbi.sol";

import {IWETH} from "src/shared/interfaces/IWETH.sol";

import {FortressLendingPair} from "src/shared/lending/FortressLendingPair.sol";
import {VariableInterestRate, IRateCalculator} from "src/shared/lending/VariableInterestRate.sol";

abstract contract BaseTest is Test, AddressesArbi {

    using SafeERC20 for IERC20;

    address owner;
    address alice;
    address bob;
    address charlie;
    address yossi;
    address platform;

    uint256 arbitrumFork;

    FortressArbiSwap fortressSwap;
    IRateCalculator rateCalculator;
    
    function _setUp() internal {
        
        // --------------------------------- set env ---------------------------------
        
        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        
        vm.selectFork(arbitrumFork);
        
        // --------------------------------- set accounts ---------------------------------

        owner = address(0x16cAD91E1928F994816EbC5e759d8562aAc65ab2);
        alice = address(0xFa0C696bC56AE0d256D34a307c447E80bf92Dd41);
        bob = address(0x864e4b0c28dF7E2f317FF339CebDB5224F47220e);
        charlie = address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc);
        yossi = address(0x77Ee01E3d0E05b4afF42105Fe004520421248261);
        platform = address(0x9cbD8440E5b8f116082a0F4B46802DB711592fAD);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(yossi, 100 ether);

        fortressSwap = new FortressArbiSwap(address(owner));
        vm.stopPrank();

        // --------------------------------- deploy interest rate contract ---------------------------------

        rateCalculator = new VariableInterestRate();
    }

    // --------------------------------- Tests ---------------------------------

    function _testInitialize(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        (uint64 _lastBlock, uint64 _feeToProtocolRate, uint64 _lastTimestamp, uint64 _ratePerSec) = _lendingPair.currentRateInfo();
        (,,,,, uint64 _DEFAULT_INT, uint16 _DEFAULT_PROTOCOL_FEE,) = _lendingPair.getConstants();
        (uint32 _lastTimestampRateInfo, uint224 _exchangeRate) = _lendingPair.exchangeRateInfo();

        assertEq(uint256(_lastTimestampRateInfo), 0, "_testInitialize: E0");
        assertEq(uint256(_exchangeRate), 0, "_testInitialize: E01");
        assertEq(uint256(_lastTimestamp), 0, "_testInitialize: E1");
        assertEq(uint256(_lastBlock), 0, "_testInitialize: E2");
        assertEq(uint256(_feeToProtocolRate), _DEFAULT_PROTOCOL_FEE, "_testInitialize: E3");
        assertEq(uint256(_lastTimestamp), 0, "_testInitialize: E4");

        vm.startPrank(owner);
        bytes memory _rateInitCallData;
        _lendingPair.initialize(_rateInitCallData);
        vm.stopPrank();

        (_lastBlock, _feeToProtocolRate, _lastTimestamp, _ratePerSec) = _lendingPair.currentRateInfo();
        (_lastTimestampRateInfo, _exchangeRate) = _lendingPair.exchangeRateInfo();
        console.log("_exchangeRate ", _exchangeRate);

        uint256 _hey = _lendingPair.updateExchangeRate();
        console.log("_hey ", _hey);
        revert("stop");
        assertEq(uint256(_lastTimestampRateInfo), block.timestamp, "_testInitialize: E05");
        assertEq(uint256(_exchangeRate), 1e18, "_testInitialize: E005"); // todo
        assertEq(uint256(_lastTimestamp), block.timestamp, "_testInitialize: E5");
        assertEq(uint256(_lastBlock), block.number, "_testInitialize: E6");
        assertEq(uint256(_feeToProtocolRate), _DEFAULT_PROTOCOL_FEE, "_testInitialize: E7");
        assertEq(uint256(_ratePerSec), _DEFAULT_INT, "_testInitialize: E8");
        assertEq(_lendingPair.totalAssets(), 0, "_testInitialize: E9");
        assertEq(_lendingPair.totalSupply(), 0, "_testInitialize: E10");
    }

    // function _updateExchangeRate() internal returns (uint256 _exchangeRate) {
    //     ExchangeRateInfo memory _exchangeRateInfo = exchangeRateInfo;
    //     if (_exchangeRateInfo.lastTimestamp == block.timestamp) {
    //         return _exchangeRate = _exchangeRateInfo.exchangeRate;
    //     }

    //     // -- Dual Oracle --
    //     // 
    //     // Asset MKR is 1e18
    //     // Collateral WBTC 1e8
    //     // exchange rate is given in Collateral/Asset ratio, essentialy how much collateral to buy 1e18 asset
    //     // ETH MKR Feed ==> ETH/MKR (returns ETH per MKR) --> MKR already at denomminator --> ETH/MKR will be oracleMultiply
    //     // ETH BTC Feed ==> ETH/WBTC (returns ETH per WBTC) --> WBTC also at denomminator, but we want it at numerator  --> ETH/WBTC will be oracleDivide
    //     // rate = ETHMKRFeed / ETHWBTCFeed --> WBTC/MKR
    //     // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)

    //     // -- single oracle --
    //     // 
    //     // Asset WETH is 1e18
    //     // Collateral FXS 1e18
    //     // exchange rate is given in Collateral/Asset ratio, essentialy how much collateral to buy 1e18 asset
    //     // ETH FXS Feed => ETH/FXS --> (returns ETH per FXS) --> FXS is at denomminator, but we want it at numerator --> ETH/FXS will be oracleDivide (oracleMultiply is address(0))
    //     // rate = 1 / ETHFXSFeed --> FXS/ETH 
    //     // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)

    //     uint256 _price = uint256(1e36);
    //     address _oracleMultiply = oracleMultiply;
    //     if (_oracleMultiply != address(0)) {
    //         (, int256 _answer, , , ) = AggregatorV3Interface(_oracleMultiply).latestRoundData();
    //         if (_answer <= 0) {
    //             revert OracleLTEZero(_oracleMultiply);
    //         }
    //         _price = _price * uint256(_answer);
    //     }

    //     address _oracleDivide = oracleDivide;
    //     if (_oracleDivide != address(0)) {
    //         (, int256 _answer, , , ) = AggregatorV3Interface(_oracleDivide).latestRoundData();
    //         if (_answer <= 0) {
    //             revert OracleLTEZero(_oracleDivide);
    //         }
    //         _price = _price / uint256(_answer);
    //     }

    //     _exchangeRate = _price / oracleNormalization;

    //     // write to storage, if no overflow
    //     if (_exchangeRate > type(uint224).max) revert PriceTooLarge();
    //     _exchangeRateInfo.exchangeRate = uint224(_exchangeRate);
    //     _exchangeRateInfo.lastTimestamp = uint32(block.timestamp);
    //     exchangeRateInfo = _exchangeRateInfo;
        
    //     emit UpdateExchangeRate(_exchangeRate);
    // }

    // function initialize(bytes calldata _rateInitCallData) external onlyOwner {
    //     // Reverts if init data is not valid
    //     IRateCalculator(rateContract).requireValidInitData(_rateInitCallData);

    //     // Set rate init Data
    //     rateInitCallData = _rateInitCallData;

    //     // Instantiate Interest
    //     _addInterest();

    //     // Instantiate Exchange Rate
    //     _updateExchangeRate();
    // }

    // --------------------------------- Internal functions ---------------------------------

    function _getAssetFromETH(address _owner, address _asset, uint256 _amount) internal returns (uint256 _assetOut) {
        vm.prank(_owner);

        if (_asset == WETH) {
            IWETH(WETH).deposit{ value: _amount }();
            _assetOut = _amount;
            require(_assetOut > 0, "BaseTest: E1");
            assertEq(IERC20(_asset).balanceOf(_owner), _assetOut, "BaseTest: E2");
        } else {
            _assetOut = fortressSwap.swap{ value: _amount }(ETH, _asset, _amount);
        }
        
        assertEq(IERC20(_asset).balanceOf(_owner), _assetOut, "_getAssetFromETH: E1");
    }
}