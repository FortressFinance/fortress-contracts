// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
    using SafeMath for uint256;

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

    // --------------------------------- Init ---------------------------------

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
        
        uint256 _updatedExchangeRate = _lendingPair.updateExchangeRate();
        
        assertEq(uint256(_lastTimestampRateInfo), block.timestamp, "_testInitialize: E05");
        assertEq(uint256(_exchangeRate), _updatedExchangeRate, "_testInitialize: E005");
        assertTrue(uint256(_exchangeRate) > 0, "_testInitialize: E0005");
        assertEq(uint256(_lastTimestamp), block.timestamp, "_testInitialize: E5");
        assertEq(uint256(_lastBlock), block.number, "_testInitialize: E6");
        assertEq(uint256(_feeToProtocolRate), _DEFAULT_PROTOCOL_FEE, "_testInitialize: E7");
        assertEq(uint256(_ratePerSec), _DEFAULT_INT, "_testInitialize: E8");
        assertEq(_lendingPair.totalAssets(), 0, "_testInitialize: E9");
        assertEq(_lendingPair.totalSupply(), 0, "_testInitialize: E10");
    }

    // --------------------------------- Lending ---------------------------------

    function _testDepositLiquidity(address _pair, uint256 _amount) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        uint256 _totalAssetsBefore = _lendingPair.totalAssets();
        uint256 _totalSupplyBefore = _lendingPair.totalSupply();

        {
            (,,,,, uint64 _DEFAULT_INT, uint16 _DEFAULT_PROTOCOL_FEE,) = _lendingPair.getConstants();
            (uint64 _lastBlock, uint64 _feeToProtocolRate, uint64 _lastTimestamp, uint64 _ratePerSec) = _lendingPair.currentRateInfo();
            assertEq(uint256(_ratePerSec), _DEFAULT_INT, "_testDepositLiquidity: E0");
            assertEq(uint256(_lastTimestamp), block.timestamp, "_testDepositLiquidity: E01");
            assertEq(uint256(_lastBlock), block.number, "_testDepositLiquidity: E02");
            assertEq(uint256(_feeToProtocolRate), _DEFAULT_PROTOCOL_FEE, "_testDepositLiquidity: E03");
        }

        vm.startPrank(alice);
        _dealERC20(address(_lendingPair.asset()), alice, _amount);
        IERC20(address(_lendingPair.asset())).approve(address(_lendingPair), _amount);
        uint256 _aliceShares = _lendingPair.deposit(_amount, address(alice));
        vm.stopPrank();

        uint256 _totalAssetsAfter = _lendingPair.totalAssets();
        uint256 _totalSupplyAfter = _lendingPair.totalSupply();

        assertEq(_totalAssetsAfter, _totalAssetsBefore + _amount, "_testDepositLiquidity: E1");
        assertEq(_totalSupplyAfter, _totalSupplyBefore + _aliceShares, "_testDepositLiquidity: E2");
        assertEq(_lendingPair.balanceOf(address(alice)), _aliceShares, "_testDepositLiquidity: E3");
        assertEq(IERC20(address(_lendingPair.asset())).balanceOf(address(_lendingPair)), _totalAssetsBefore + _amount, "_testDepositLiquidity: E4");

        vm.startPrank(bob);
        _dealERC20(address(_lendingPair.asset()), bob, _amount);
        IERC20(address(_lendingPair.asset())).approve(address(_lendingPair), _amount);
        uint256 _bobShares = _lendingPair.deposit(_amount, address(bob));
        vm.stopPrank();

        _totalAssetsAfter = _lendingPair.totalAssets();
        _totalSupplyAfter = _lendingPair.totalSupply();

        assertEq(_totalAssetsAfter, _totalAssetsBefore + _amount * 2, "_testDepositLiquidity: E5");
        assertEq(_totalSupplyAfter, _totalSupplyBefore + _aliceShares + _bobShares, "_testDepositLiquidity: E6");
        assertEq(_lendingPair.balanceOf(address(bob)), _bobShares, "_testDepositLiquidity: E7");
        assertEq(IERC20(address(_lendingPair.asset())).balanceOf(address(_lendingPair)), _totalAssetsBefore + _amount * 2, "_testDepositLiquidity: E8");

        vm.startPrank(charlie);
        _dealERC20(address(_lendingPair.asset()), charlie, _amount);
        IERC20(address(_lendingPair.asset())).approve(address(_lendingPair), _amount);
        uint256 _charlieShares = _lendingPair.deposit(_amount, address(charlie));
        vm.stopPrank();

        _totalAssetsAfter = _lendingPair.totalAssets();
        _totalSupplyAfter = _lendingPair.totalSupply();

        assertEq(_totalAssetsAfter, _totalAssetsBefore + _amount * 3, "_testDepositLiquidity: E9");
        assertEq(_totalSupplyAfter, _totalSupplyBefore + _aliceShares + _bobShares + _charlieShares, "_testDepositLiquidity: E10");
        assertEq(_lendingPair.balanceOf(address(charlie)), _charlieShares, "_testDepositLiquidity: E11");
        assertEq(IERC20(address(_lendingPair.asset())).balanceOf(address(_lendingPair)), _totalAssetsBefore + _amount * 3, "_testDepositLiquidity: E12");

        {
            (,,,,, uint64 _DEFAULT_INT, uint16 _DEFAULT_PROTOCOL_FEE,) = _lendingPair.getConstants();
            (uint64 _lastBlock, uint64 _feeToProtocolRate, uint64 _lastTimestamp, uint64 _ratePerSec) = _lendingPair.currentRateInfo();
            assertEq(uint256(_ratePerSec), _DEFAULT_INT, "_testDepositLiquidity: E13");
            assertEq(uint256(_lastTimestamp), block.timestamp, "_testDepositLiquidity: E14");
            assertEq(uint256(_lastBlock), block.number, "_testDepositLiquidity: E15");
            assertEq(uint256(_feeToProtocolRate), _DEFAULT_PROTOCOL_FEE, "_testDepositLiquidity: E16");
        }
    }

    // function _testRedeemLiquidity

    // --------------------------------- Borrowing --------------------------------

    function _testLeveragePosition(address _pair, address _underlyingAsset) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        uint256 _borrowAmount = _lendingPair.totalAssets() / 3;
        // use exchange rate to calculate borrow amount in collateral
        // uint256 _borrowAmountInCollateral = _borrowAmount * 1e5 / _lendingPair.exchangeRateStored();
        uint256 _initialCollateralAmount = ((_borrowAmount * 1e5) / _lendingPair.maxLTV()) - _borrowAmount;
        console.log("borrowAmount1: %s", _borrowAmount);
        console.log("initialCollateralAmount1: %s", _initialCollateralAmount);
        // uint256 _totalAssetsBefore = _lendingPair.totalAssets();
        // uint256 _totalSupplyBefore = _lendingPair.totalSupply();

        vm.startPrank(alice);
        // _dealERC20(address(_lendingPair.collateralContract()), alice, _initialCollateralAmount);
        // assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(address(alice)), _initialCollateralAmount, "_testLeveragePosition: E0");
        // IERC20(address(_lendingPair.collateralContract())).approve(address(_lendingPair), _initialCollateralAmount);
        // _lendingPair.leveragePosition(_borrowAmount, _initialCollateralAmount, 0, _underlyingAsset);
        _lendingPair.leveragePosition(_borrowAmount, 0, 0, _underlyingAsset);
    }

    // function leveragePosition(uint256 _borrowAmount, uint256 _initialCollateralAmount, uint256 _minAmount, address _underlyingAsset) external nonReentrant isSolvent(msg.sender) returns (uint256 _totalCollateralAdded) {
    //     if (pauseAddLeverage) revert AddLeveragePaused();

    //     _addInterest();
    //     _updateExchangeRate();

    //     // Add initial collateral
    //     if (_initialCollateralAmount > 0) _addCollateral(msg.sender, _initialCollateralAmount, msg.sender);

    //     // Debit borrowers (msg.sender) account
    //     uint256 _borrowShares = _borrowAsset(_borrowAmount);

    //     uint256 _underlyingAmount;
    //     address _asset = address(assetContract);
    //     _underlyingAmount = _asset != _underlyingAsset ? IFortressSwap(swap).swap(_asset, _underlyingAsset, _borrowAmount) : _borrowAmount;
        
    //     uint256 _amountCollateralOut = IFortressVault(address(collateralContract)).depositSingleUnderlying(_underlyingAmount, _underlyingAsset, address(this), 0);
    //     if (_amountCollateralOut < _minAmount) revert SlippageTooHigh();

    //     // address(this) as _sender means no transfer occurs as the pair has already received the collateral during swap
    //     _addCollateral(address(this), _amountCollateralOut, msg.sender);
        
    //     emit LeveragedPosition(msg.sender, _borrowAmount, _borrowShares, _initialCollateralAmount, _amountCollateralOut);

    //     return _initialCollateralAmount + _amountCollateralOut;
    // }

    // --------------------------------- Internal functions ---------------------------------

    function _dealERC20(address _token, address _recipient , uint256 _amount) internal {
        deal({ token: address(_token), to: _recipient, give: _amount});
    }

    // function getfcTokens(uint256 _amount, address _vault) internal view returns (address _fcToken) {
    //     _fcToken = FortressLendingPair(_pair).fcToken();
    // }
}