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

    function _testDepositLiquidity(address _pair, uint256 _amount) internal returns (uint256 _totalAssetsAfter, uint256 _totalSupplyAfter) {
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

        _totalAssetsAfter = _lendingPair.totalAssets();
        _totalSupplyAfter = _lendingPair.totalSupply();

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

        return (_totalAssetsAfter, _totalSupplyAfter);
    }

    function _testRemoveLiquidity(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        uint256 _totalAssetsBefore = _lendingPair.totalAssets();
        uint256 _totalSupplyBefore = _lendingPair.totalSupply();

        uint256 _aliceShares = _lendingPair.balanceOf(address(alice));
        uint256 _bobShares = _lendingPair.balanceOf(address(bob));
        uint256 _charlieShares = _lendingPair.balanceOf(address(charlie));

        vm.startPrank(address(alice));
        uint256 _aliceAmount = _lendingPair.redeem(_aliceShares, address(alice), address(alice));
        vm.stopPrank();

        uint256 _totalAssetsAfter = _lendingPair.totalAssets();
        uint256 _totalSupplyAfter = _lendingPair.totalSupply();

        assertEq(_totalAssetsAfter, _totalAssetsBefore - _aliceAmount, "_testRemoveLiquidity: E1");
        assertEq(_totalSupplyAfter, _totalSupplyBefore - _aliceShares, "_testRemoveLiquidity: E2");
        assertEq(_lendingPair.balanceOf(address(alice)), 0, "_testRemoveLiquidity: E3");
        assertApproxEqAbs(IERC20(address(_lendingPair.asset())).balanceOf(address(alice)), _aliceAmount, 1e18, "_testRemoveLiquidity: E4");

        vm.startPrank(bob);
        uint256 _bobAmount = _lendingPair.redeem(_bobShares, address(bob), address(bob));
        vm.stopPrank();

        _totalAssetsAfter = _lendingPair.totalAssets();
        _totalSupplyAfter = _lendingPair.totalSupply();

        assertEq(_totalAssetsAfter, _totalAssetsBefore - _aliceAmount - _bobAmount, "_testRemoveLiquidity: E5");
        assertEq(_totalSupplyAfter, _totalSupplyBefore - _aliceShares - _bobShares, "_testRemoveLiquidity: E6");
        assertEq(_lendingPair.balanceOf(address(bob)), 0, "_testRemoveLiquidity: E7");
        assertApproxEqAbs(IERC20(address(_lendingPair.asset())).balanceOf(address(bob)), _bobAmount, 1e18, "_testRemoveLiquidity: E8");

        vm.startPrank(charlie);
        uint256 _charlieAmount = _lendingPair.redeem(_charlieShares, address(charlie), address(charlie));
        vm.stopPrank();

        assertEq(_lendingPair.balanceOf(address(charlie)), 0, "_testRemoveLiquidity: E11");
        assertApproxEqAbs(IERC20(address(_lendingPair.asset())).balanceOf(address(charlie)), _charlieAmount, 1e18, "_testRemoveLiquidity: E12");
    }

    // --------------------------------- Borrowing --------------------------------

    function _testLeveragePosition(address _pair, address _underlyingAsset) internal returns (uint256 _totalCollateral) {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        uint256 _borrowAmount = _lendingPair.totalAssets() / 3;
        (, uint224 _exchangeRate) = _lendingPair.exchangeRateInfo();
        // _borrowAmount = (_borrowAmount * 1e18) / uint256(_exchangeRate);
        uint256 _minCollateral = (((_borrowAmount * 1e5) / _lendingPair.maxLTV()) - _borrowAmount) * uint256(_exchangeRate) / 1e18; 

        uint256 _totalAssetsBefore = _lendingPair.totalAssets();
        uint256 _totalSupplyBefore = _lendingPair.totalSupply();
        (uint256 _totalBorrowAmount, uint256 _totalBorrowSupply) = _lendingPair.totalBorrow();
        _totalCollateral = _lendingPair.totalCollateral();

        assertEq(_totalCollateral, 0, "_testLeveragePosition: E00");
        assertEq(_totalBorrowAmount, 0, "_testLeveragePosition: E0");
        assertEq(_totalBorrowSupply, 0, "_testLeveragePosition: E1");
        assertTrue(_totalAssetsBefore > 0, "_testLeveragePosition: E2");
        assertTrue(_totalSupplyBefore > 0, "_testLeveragePosition: E3");
        
        // add 1% to _minCollateral
        _minCollateral = _minCollateral * 101 / 100;

        vm.startPrank(alice);
        _dealERC20(address(_lendingPair.collateralContract()), alice, _minCollateral);
        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(address(alice)), _minCollateral, "_testLeveragePosition: E03");
        IERC20(address(_lendingPair.collateralContract())).approve(address(_lendingPair), _minCollateral);

        vm.expectRevert();
        // remove 10% of collateral
        _lendingPair.leveragePosition(_borrowAmount, (_minCollateral * 9 / 10), 0, _underlyingAsset);
        uint256 _userAddedCollateral = _lendingPair.leveragePosition(_borrowAmount, _minCollateral, 0, _underlyingAsset);
        _totalCollateral += _userAddedCollateral;

        (_totalBorrowAmount, _totalBorrowSupply) = _lendingPair.totalBorrow();
        
        assertEq(_lendingPair.totalCollateral(), _totalCollateral, "_testLeveragePosition: E4");
        assertEq(_lendingPair.totalAssets(), _totalAssetsBefore, "_testLeveragePosition: E5");
        assertEq(_lendingPair.totalSupply(), _totalSupplyBefore, "_testLeveragePosition: E6");
        assertEq(_totalBorrowAmount, _borrowAmount, "_testLeveragePosition: E7");
        assertEq(_totalBorrowSupply, _lendingPair.convertToShares(_totalBorrowAmount, _totalBorrowSupply, _borrowAmount, true), "_testLeveragePosition: E8");
        assertEq(_userAddedCollateral, _lendingPair.userCollateralBalance(alice), "_testLeveragePosition: E9");

        vm.stopPrank();

        _totalAssetsBefore = _lendingPair.totalAssets();
        _totalSupplyBefore = _lendingPair.totalSupply();
        (_totalBorrowAmount, _totalBorrowSupply) = _lendingPair.totalBorrow();
        _totalCollateral = _lendingPair.totalCollateral();

        vm.startPrank(bob);
        _dealERC20(address(_lendingPair.collateralContract()), bob, _minCollateral);
        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(address(bob)), _minCollateral, "_testLeveragePosition: E10");
        IERC20(address(_lendingPair.collateralContract())).approve(address(_lendingPair), _minCollateral);

        _userAddedCollateral = _lendingPair.leveragePosition(_borrowAmount, _minCollateral, 0, _underlyingAsset);
        _totalCollateral += _userAddedCollateral;

        (_totalBorrowAmount, _totalBorrowSupply) = _lendingPair.totalBorrow();

        assertEq(_lendingPair.totalCollateral(), _totalCollateral, "_testLeveragePosition: E11");
        assertEq(_lendingPair.totalAssets(), _totalAssetsBefore, "_testLeveragePosition: E12");
        assertEq(_lendingPair.totalSupply(), _totalSupplyBefore, "_testLeveragePosition: E13");
        assertEq(_totalBorrowAmount, _borrowAmount * 2, "_testLeveragePosition: E14");
        assertEq(_totalBorrowSupply, _lendingPair.convertToShares(_totalBorrowAmount, _totalBorrowSupply, _borrowAmount, true) * 2, "_testLeveragePosition: E15");
        assertEq(_userAddedCollateral, _lendingPair.userCollateralBalance(bob), "_testLeveragePosition: E16");

        vm.stopPrank();

        _totalAssetsBefore = _lendingPair.totalAssets();
        _totalSupplyBefore = _lendingPair.totalSupply();
        (_totalBorrowAmount, _totalBorrowSupply) = _lendingPair.totalBorrow();
        _totalCollateral = _lendingPair.totalCollateral();

        vm.startPrank(charlie);
        _dealERC20(address(_lendingPair.collateralContract()), charlie, _minCollateral);
        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(address(charlie)), _minCollateral, "_testLeveragePosition: E17");
        IERC20(address(_lendingPair.collateralContract())).approve(address(_lendingPair), _minCollateral);

        _userAddedCollateral = _lendingPair.leveragePosition(_borrowAmount, _minCollateral, 0, _underlyingAsset);
        _totalCollateral += _userAddedCollateral;

        (_totalBorrowAmount, _totalBorrowSupply) = _lendingPair.totalBorrow();

        assertEq(_lendingPair.totalCollateral(), _totalCollateral, "_testLeveragePosition: E18");
        assertEq(_lendingPair.totalAssets(), _totalAssetsBefore, "_testLeveragePosition: E19");
        assertEq(_lendingPair.totalSupply(), _totalSupplyBefore, "_testLeveragePosition: E20");
        assertEq(_totalBorrowAmount, _borrowAmount * 3, "_testLeveragePosition: E21");
        assertEq(_totalBorrowSupply, _lendingPair.convertToShares(_totalBorrowAmount, _totalBorrowSupply, _borrowAmount, true) * 3, "_testLeveragePosition: E22");
        assertEq(_userAddedCollateral, _lendingPair.userCollateralBalance(charlie), "_testLeveragePosition: E23");

        vm.stopPrank();

        assertEq(_lendingPair.totalAssets() - _totalBorrowAmount, 0, "_testLeveragePosition: E24");

        assertTrue(IERC20(address(_lendingPair)).balanceOf(alice) > 0, "_testLeveragePosition: E25");
        // vm.expectRevert(); // reverts with InsufficientAssetsInContract
        // _lendingPair.redeem(IERC20(address(_lendingPair)).balanceOf(alice), alice, alice);
        
        vm.startPrank(charlie);
        _minCollateral = 1 ether;
        _dealERC20(address(_lendingPair.collateralContract()), charlie, _minCollateral);
        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(address(charlie)), _minCollateral, "_testLeveragePosition: E26");
        IERC20(address(_lendingPair.collateralContract())).approve(address(_lendingPair), _minCollateral);

        vm.expectRevert(); // reverts with InsufficientAssetsInContract
        _userAddedCollateral = _lendingPair.leveragePosition(_borrowAmount, _minCollateral, 0, _underlyingAsset);
        
        vm.stopPrank();

        return _totalCollateral;
    }

    // assumes maxLTV is 75%
    function _testClosePosition(address _pair, address _underlyingAsset, uint256 _totalAssets, uint256 _totalSupply, uint256 _totalCollateral) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        _lendingPair.addInterest();
        
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 days);

        _lendingPair.addInterest();

        assertApproxEqAbs(_lendingPair.totalAssets(), _totalAssets, 1e17, "_testCloseLeveragePosition: E1");
        assertApproxEqAbs(_lendingPair.totalSupply(), _totalSupply, 1e17, "_testCloseLeveragePosition: E2");
        assertEq(_lendingPair.totalCollateral(), _totalCollateral, "_testCloseLeveragePosition: E3");
        assertEq(_lendingPair.userCollateralBalance(alice), _lendingPair.userCollateralBalance(bob), "_testCloseLeveragePosition: E4");
        assertEq(_lendingPair.userCollateralBalance(charlie), _lendingPair.userCollateralBalance(bob), "_testCloseLeveragePosition: E5");

        (uint256 _borrowAmountBefore, uint256 _borrowSharesBefore) = _lendingPair.totalBorrow();
        
        vm.startPrank(alice);
        uint256 _userCollateralBalance = (_lendingPair.userCollateralBalance(alice) / 4) * 3;
        
        vm.expectRevert(); // reverts with Insolvent
        _lendingPair.removeCollateral(_userCollateralBalance, alice);
        
        assertEq(IERC20(address(_lendingPair.assetContract())).balanceOf(alice), 0, "_testCloseLeveragePosition: E6");
        
        uint256 _userBorrowShare = _lendingPair.userBorrowShares(alice);
        uint256 _amountAssetOut = _lendingPair.repayAssetWithCollateral(_userCollateralBalance, 0, _underlyingAsset);
        
        (uint256 _borrowAmountAfter, uint256 _borrowSharesAfter) = _lendingPair.totalBorrow();
        _userBorrowShare = _userBorrowShare - _lendingPair.userBorrowShares(alice);
        
        assertEq(_borrowAmountBefore - _amountAssetOut, _borrowAmountAfter, "_testCloseLeveragePosition: E7");
        assertEq(_borrowSharesBefore - _userBorrowShare, _borrowSharesAfter, "_testCloseLeveragePosition: E8");
        assertApproxEqAbs(_lendingPair.userCollateralBalance(alice), _userCollateralBalance / 3, 1e5, "_testCloseLeveragePosition: E9");
        assertEq(_lendingPair.totalCollateral(), _totalCollateral - _userCollateralBalance, "_testCloseLeveragePosition: E10");
        assertApproxEqAbs(_lendingPair.totalAssets(), _totalAssets, 1e17, "_testCloseLeveragePosition: E11");
        assertApproxEqAbs(_lendingPair.totalSupply(), _totalSupply, 1e17, "_testCloseLeveragePosition: E12");

        _clearDebt(_pair, alice, _underlyingAsset);
        
        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(alice), 0, "_testCloseLeveragePosition: E13");
        _lendingPair.removeCollateral(_lendingPair.userCollateralBalance(alice), alice);
        assertTrue(IERC20(address(_lendingPair.collateralContract())).balanceOf(alice) > 0, "_testCloseLeveragePosition: E14");

        vm.stopPrank();

        vm.startPrank(bob);
        
        (_borrowAmountBefore, _borrowSharesBefore) = _lendingPair.totalBorrow();

        vm.expectRevert(); // reverts with Insolvent
        _lendingPair.removeCollateral(_userCollateralBalance, bob);

        assertEq(IERC20(address(_lendingPair.assetContract())).balanceOf(bob), 0, "_testCloseLeveragePosition: E15");

        _userBorrowShare = _lendingPair.userBorrowShares(bob);
        _amountAssetOut = _lendingPair.repayAssetWithCollateral(_userCollateralBalance, 0, _underlyingAsset);

        (_borrowAmountAfter, _borrowSharesAfter) = _lendingPair.totalBorrow();
        _userBorrowShare = _userBorrowShare - _lendingPair.userBorrowShares(bob);

        assertEq(_borrowAmountBefore - _amountAssetOut, _borrowAmountAfter, "_testCloseLeveragePosition: E16");
        assertEq(_borrowSharesBefore - _userBorrowShare, _borrowSharesAfter, "_testCloseLeveragePosition: E17");
        assertApproxEqAbs(_lendingPair.userCollateralBalance(bob), _userCollateralBalance / 3, 1e5, "_testCloseLeveragePosition: E18");
        assertApproxEqAbs(_lendingPair.totalAssets(), _totalAssets, 1e17, "_testCloseLeveragePosition: E20");
        assertApproxEqAbs(_lendingPair.totalSupply(), _totalSupply, 1e17, "_testCloseLeveragePosition: E21");

        _clearDebt(_pair, bob, _underlyingAsset);

        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(bob), 0, "_testCloseLeveragePosition: E22");
        _lendingPair.removeCollateral(_lendingPair.userCollateralBalance(bob), bob);
        assertTrue(IERC20(address(_lendingPair.collateralContract())).balanceOf(bob) > 0, "_testCloseLeveragePosition: E23");

        vm.stopPrank();

        vm.startPrank(charlie);

        (_borrowAmountBefore, _borrowSharesBefore) = _lendingPair.totalBorrow();

        vm.expectRevert(); // reverts with AlreadyCalledOnBlock
        _lendingPair.removeCollateral(_userCollateralBalance, charlie);

        vm.roll(block.number + 1);
        
        vm.expectRevert(); // reverts with Insolvent
        _lendingPair.removeCollateral(_userCollateralBalance, charlie);
        
        assertEq(IERC20(address(_lendingPair.assetContract())).balanceOf(charlie), 0, "_testCloseLeveragePosition: E24");

        _userBorrowShare = _lendingPair.userBorrowShares(charlie);
        _amountAssetOut = _lendingPair.repayAssetWithCollateral(_userCollateralBalance, 0, _underlyingAsset);

        (_borrowAmountAfter, _borrowSharesAfter) = _lendingPair.totalBorrow();
        _userBorrowShare = _userBorrowShare - _lendingPair.userBorrowShares(charlie);

        assertEq(_borrowAmountBefore - _amountAssetOut, _borrowAmountAfter, "_testCloseLeveragePosition: E25");
        assertEq(_borrowSharesBefore - _userBorrowShare, _borrowSharesAfter, "_testCloseLeveragePosition: E26");
        assertApproxEqAbs(_lendingPair.userCollateralBalance(charlie), _userCollateralBalance / 3, 1e5, "_testCloseLeveragePosition: E27");
        assertApproxEqAbs(_lendingPair.totalAssets(), _totalAssets, 1e17, "_testCloseLeveragePosition: E29");
        assertApproxEqAbs(_lendingPair.totalSupply(), _totalSupply, 1e17, "_testCloseLeveragePosition: E30");

        _clearDebt(_pair, charlie, _underlyingAsset);

        // assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(charlie), 0, "_testCloseLeveragePosition: E31");
        _lendingPair.removeCollateral(_lendingPair.userCollateralBalance(charlie), charlie);
        assertTrue(IERC20(address(_lendingPair.collateralContract())).balanceOf(charlie) > 0, "_testCloseLeveragePosition: E32");

        vm.stopPrank();

        (_borrowAmountAfter, _borrowSharesAfter) = _lendingPair.totalBorrow();

        assertEq(_borrowAmountAfter, 0, "_testCloseLeveragePosition: E33");
        assertEq(_borrowSharesAfter, 0, "_testCloseLeveragePosition: E34");
        assertEq(_lendingPair.totalCollateral(), 0, "_testCloseLeveragePosition: E35");
        assertApproxEqAbs(_lendingPair.totalAssets(), _totalAssets, 1e17, "_testCloseLeveragePosition: E36");
        assertApproxEqAbs(_lendingPair.totalSupply(), _totalSupply, 1e17, "_testCloseLeveragePosition: E37");
    }

    function _clearDebt(address _pair, address _user, address _underlyingAsset) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        vm.roll(block.number + 1);
        
        (, uint224 _exchangeRate) = _lendingPair.exchangeRateInfo();
        (uint256 _borrowAmount, uint256 _borrowShares) = _lendingPair.totalBorrow();

        uint256 _userBorrowAmountInCollateral = _lendingPair.convertToAssets(_borrowAmount, _borrowShares, _lendingPair.userBorrowShares(_user), true) * uint256(_exchangeRate) / 1e18;
        uint256 _pairAssetBalance1 = IERC20(address(_lendingPair.assetContract())).balanceOf(_pair);
        uint256 _pairCollateralBalance1 = IERC20(address(_lendingPair.collateralContract())).balanceOf(_pair);
        _lendingPair.repayAssetWithCollateral(_userBorrowAmountInCollateral, 0, _underlyingAsset);
        assertTrue(IERC20(address(_lendingPair.assetContract())).balanceOf(_pair) > _pairAssetBalance1 - _userBorrowAmountInCollateral, "_clearDebt: E0");
        assertTrue(IERC20(address(_lendingPair.collateralContract())).balanceOf(_pair) < _pairCollateralBalance1, "_clearDebt: E00");

        _dealERC20(address(_lendingPair.assetContract()), _user, _lendingPair.userBorrowShares(_user) * 10);
        IERC20(address(_lendingPair.assetContract())).approve(address(_lendingPair), type(uint256).max);

        vm.roll(block.number + 1);

        uint256 _pairAssetBalance2 = IERC20(address(_lendingPair.assetContract())).balanceOf(_pair);
        uint256 _pairCollateralBalance2 = IERC20(address(_lendingPair.collateralContract())).balanceOf(_pair);
        _lendingPair.repayAsset(_lendingPair.userBorrowShares(_user), _user);

        assertTrue(IERC20(address(_lendingPair.assetContract())).balanceOf(_pair) > _pairAssetBalance2, "_clearDebt: E1");
        assertEq(IERC20(address(_lendingPair.collateralContract())).balanceOf(_pair), _pairCollateralBalance2, "_clearDebt: E2");
        assertEq(_lendingPair.userBorrowShares(_user), 0, "_clearDebt: E3");

        vm.roll(block.number + 1);
    }

    function _testPlatformFee(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        vm.warp(block.timestamp + 1 days);

        (, uint64 _feeToProtocolRate,,) = _lendingPair.currentRateInfo();

        assertTrue(uint256(_feeToProtocolRate) > 0, "_testPlatformFee: E1");

        _lendingPair.addInterest();

        uint256 _platformShares = IERC20(address(_lendingPair)).balanceOf(_pair);
        assertTrue(_platformShares > 0, "_testPlatformFee: E2");

        uint256 _platformBalanceBefore = IERC20(address(_lendingPair.assetContract())).balanceOf(platform);

        vm.startPrank(owner);
        _lendingPair.withdrawFees(0, platform);

        assertTrue(IERC20(address(_lendingPair.assetContract())).balanceOf(platform) > _platformBalanceBefore, "_testPlatformFee: E3");

        vm.stopPrank();

        assertEq(_lendingPair.totalAssets(), 0 , "_testPlatformFee: E4");
        assertEq(_lendingPair.totalSupply(), 0, "_testPlatformFee: E5");
    }

    function _testUpdateSwap(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        address _swap = address(0x1234);

        vm.startPrank(owner);
        _lendingPair.updateSwap(_swap);
        vm.stopPrank();

        assertEq(_lendingPair.swap(), _swap, "_testUpdateSwap: E1");
    }

    function _testUpdateOwner(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        address _owner = address(0x1234);

        vm.startPrank(owner);
        _lendingPair.updateOwner(_owner);
        vm.stopPrank();

        assertEq(_lendingPair.owner(), _owner, "_testUpdateOwner: E1");
    }

    function _testUpdatePauseSettings(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        bytes memory _configData = abi.encode(true, true, true, true, true, true, true, true, true);

        vm.startPrank(owner);
        _lendingPair.updatePauseSettings(_configData);
        vm.stopPrank();

        (bool _depositLiquidity, bool _withdrawLiquidity, bool _addLeverage, bool _removeLeverage, bool _addInterest, bool _liquidations, bool _addCollateral, bool _removeCollateral, bool _repayAsset)
            = _lendingPair.pauseSettings();

        assertTrue(_depositLiquidity, "_testUpdatePauseSettings: E1");
        assertTrue(_withdrawLiquidity, "_testUpdatePauseSettings: E2");
        assertTrue(_addLeverage, "_testUpdatePauseSettings: E3");
        assertTrue(_removeLeverage, "_testUpdatePauseSettings: E4");
        assertTrue(_addInterest, "_testUpdatePauseSettings: E5");
        assertTrue(_liquidations, "_testUpdatePauseSettings: E6");
        assertTrue(_addCollateral, "_testUpdatePauseSettings: E7");
        assertTrue(_removeCollateral, "_testUpdatePauseSettings: E8");
        assertTrue(_repayAsset, "_testUpdatePauseSettings: E9");
    }

    function _testUpdateFee(address _pair) internal {
        FortressLendingPair _lendingPair = FortressLendingPair(_pair);

        uint64 _newFee = 1000;

        vm.startPrank(owner);
        _lendingPair.updateFee(_newFee);
        vm.stopPrank();

        (, uint64 _feeToProtocolRate,,) = _lendingPair.currentRateInfo();

        assertEq(uint256(_feeToProtocolRate), _newFee, "_testUpdateFee: E1");
    }

    // --------------------------------- Internal functions ---------------------------------

    function _dealERC20(address _token, address _recipient , uint256 _amount) internal {
        deal({ token: address(_token), to: _recipient, give: _amount});
    }

    // --------------------------------- Notes ---------------------------------

    // -- Dual Oracle --
    // 
    // Asset MKR is 1e18
    // Collateral WBTC 1e8
    // exchange rate is given in Collateral/Asset ratio, essentialy how much collateral to buy 1e18 asset
    // ETH MKR Feed ==> ETH/MKR (returns ETH per MKR) --> MKR already at denomminator --> ETH/MKR will be oracleMultiply
    // ETH BTC Feed ==> ETH/WBTC (returns ETH per WBTC) --> WBTC also at denomminator, but we want it at numerator  --> ETH/WBTC will be oracleDivide
    // rate = ETHMKRFeed / ETHWBTCFeed --> WBTC/MKR
    // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)

    // -- single oracle --
    // 
    // Asset WETH is 1e18
    // Collateral FXS 1e18
    // exchange rate is given in Collateral/Asset ratio, essentialy how much collateral to buy 1e18 asset
    // ETH FXS Feed => ETH/FXS --> (returns ETH per FXS) --> FXS is at denomminator, but we want it at numerator --> ETH/FXS will be oracleDivide (oracleMultiply is address(0))
    // rate = 1 / ETHFXSFeed --> FXS/ETH 
    // oracle normalization 1^(18 + precision of numerator oracle - precision of denominator oracle + precision of asset token - precision of collateral token)
}