// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/mainnet/compounders/curve/CvxCrvCompounder.sol";

import "src/shared/interfaces/IBalancerVault.sol";
import "src/shared/interfaces/IBalancerPool.sol";

import "test/mainnet/compounder/token/TokenCompounderBaseTest.sol";

contract testCvxCRVCompounder is TokenCompounderBaseTest {
    
    using SafeERC20 for IERC20;

    CvxCrvCompounder cvxCRVCompounder;
    
    function setUp() public {
        
        _setUp();

        cvxCRVCompounder = new CvxCrvCompounder(owner, platform, address(fortressSwap));
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test mutated functions ---------------------------------
    // ------------------------------------------------------------------------------------------

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _getAssetFromETH(alice, cvxCRV, _amount);
        _getAssetFromETH(bob, cvxCRV, _amount);
        _getAssetFromETH(charlie, cvxCRV, _amount);

        // ---------------- deposit ----------------

        vm.startPrank(alice);
        amount = IERC20(cvxCRV).balanceOf(address(alice));
        accumulatedAmount += amount;
        _approve(cvxCRV, address(cvxCRVCompounder), amount);
        aliceAmountOut = cvxCRVCompounder.deposit(amount, address(alice));
        accumulatedShares += aliceAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(alice)), 0, "testDeposit: E1");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), aliceAmountOut, "testDeposit: E2");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E3");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E4");
        assertTrue(cvxCRVCompounder.totalAssets() > 0, "testDeposit: E04");

        vm.startPrank(bob);
        amount = IERC20(cvxCRV).balanceOf(address(bob));
        accumulatedAmount += amount;
        _approve(cvxCRV, address(cvxCRVCompounder), amount);
        bobAmountOut = cvxCRVCompounder.deposit(amount, address(bob));
        accumulatedShares += bobAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), 0, "testDeposit: E5");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), bobAmountOut, "testDeposit: E6");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E7");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E8");

        vm.startPrank(charlie);
        amount = IERC20(cvxCRV).balanceOf(address(charlie));
        accumulatedAmount += amount;
        _approve(cvxCRV, address(cvxCRVCompounder), amount);
        charlieAmountOut = cvxCRVCompounder.deposit(amount, address(charlie));
        accumulatedShares += charlieAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), 0, "testDeposit: E9");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), charlieAmountOut, "testDeposit: E10");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E11");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E12");

        assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testDeposit: E13");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testDeposit: E14");
        assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testDeposit: E15");
        
        // ---------------- harvest ----------------

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testDeposit: E16");

        // Fast forward 1 month
        skip(216000);

        assertEq(cvxCRVCompounder.isPendingRewards(), true, "testDeposit: E17");

        vm.prank(harvester);
        accumulatedAmount += cvxCRVCompounder.harvest(address(harvester), 0);

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testDeposit: E18");
        assertTrue(IERC20(cvxCRV).balanceOf(harvester) > 0, "testDeposit: E19");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E20");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E21");

        assertTrue(IERC20(cvxCRV).balanceOf(platform) > 0, "testDeposit: E22");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E23");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E24");

        // ---------------- redeem ---------------

        shares = cvxCRVCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = cvxCRVCompounder.redeem(shares, address(alice), address(alice));
        accumulatedAmount -= aliceAmountOut;
        accumulatedShares -= shares;

        assertEq(IERC20(cvxCRV).balanceOf(address(alice)), aliceAmountOut, "testDeposit: E25");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), 0, "testDeposit: E26");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E27");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E28");

        shares = cvxCRVCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = cvxCRVCompounder.redeem(shares, address(bob), address(bob));
        accumulatedAmount -= bobAmountOut;
        accumulatedShares -= shares;

        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), bobAmountOut, "testDeposit: E29");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), 0, "testDeposit: E30");
        assertEq(cvxCRVCompounder.totalAssets(), accumulatedAmount, "testDeposit: E31");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E32");

        shares = cvxCRVCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = cvxCRVCompounder.redeem(shares, address(charlie), address(charlie));
        
        accumulatedShares -= shares;

        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), charlieAmountOut, "testDeposit: E33");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), 0, "testDeposit: E34");
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testDeposit: E35");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E36");

        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testDeposit: E37");
        assertEq(accumulatedShares, 0, "testDeposit: E39");
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testDeposit: E40");
        assertEq(cvxCRVCompounder.totalSupply(), 0, "testDeposit: E41");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testDeposit: E42");
    }

    function testDepositUnwrapped(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _getAssetFromETH(alice, CRV, _amount);
        _getAssetFromETH(bob, CRV, _amount);
        _getAssetFromETH(charlie, CRV, _amount);

        // ---------------- deposit ----------------

        vm.startPrank(alice);
        amount = IERC20(CRV).balanceOf(address(alice));
        _approve(CRV, address(cvxCRVCompounder), amount);
        aliceAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(alice), 0);
        accumulatedShares += aliceAmountOut;
        vm.stopPrank();

        assertEq(IERC20(CRV).balanceOf(address(alice)), 0, "testDepositUnwrapped: E1");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), aliceAmountOut, "testDepositUnwrapped: E2");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDepositUnwrapped: E3");

        vm.startPrank(bob);
        amount = IERC20(CRV).balanceOf(address(bob));
        _approve(CRV, address(cvxCRVCompounder), amount);
        bobAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(bob), 0);
        accumulatedShares += bobAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), 0, "testDepositUnwrapped: E4");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), bobAmountOut, "testDepositUnwrapped: E5");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDepositUnwrapped: E6");

        vm.startPrank(charlie);
        amount = IERC20(CRV).balanceOf(address(charlie));
        _approve(CRV, address(cvxCRVCompounder), amount);
        charlieAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(charlie), 0);
        accumulatedShares += charlieAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), 0, "testDepositUnwrapped: E7");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), charlieAmountOut, "testDepositUnwrapped: E8");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDepositUnwrapped: E9");

        assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testDepositUnwrapped: E10");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testDepositUnwrapped: E11");
        assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testDepositUnwrapped: E12");

        // ---------------- harvest ----------------

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testDeposit: E13");

        // Fast forward 1 month
        skip(216000);

        assertEq(cvxCRVCompounder.isPendingRewards(), true, "testDeposit: E14");

        vm.prank(harvester);
        cvxCRVCompounder.harvest(address(harvester), 0);

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testDeposit: E15");
        assertTrue(IERC20(cvxCRV).balanceOf(harvester) > 0, "testDeposit: E16");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E17");

        assertTrue(IERC20(cvxCRV).balanceOf(platform) > 0, "testDeposit: E18");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E19");

        // ---------------- redeem ---------------

        shares = cvxCRVCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = cvxCRVCompounder.redeem(shares, address(alice), address(alice));
        accumulatedShares -= shares;

        assertEq(IERC20(cvxCRV).balanceOf(address(alice)), aliceAmountOut, "testDeposit: E20");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), 0, "testDeposit: E21");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E22");

        shares = cvxCRVCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = cvxCRVCompounder.redeem(shares, address(bob), address(bob));
        accumulatedShares -= shares;

        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), bobAmountOut, "testDeposit: E23");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), 0, "testDeposit: E24");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E25");

        shares = cvxCRVCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = cvxCRVCompounder.redeem(shares, address(charlie), address(charlie));
        accumulatedShares -= shares;

        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), charlieAmountOut, "testDeposit: E26");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), 0, "testDeposit: E27");
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testDeposit: E28");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testDeposit: E29");

        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testDeposit: E37");
        assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testDeposit: E38");
        assertEq(accumulatedShares, 0, "testDeposit: E39");
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testDeposit: E40");
        assertEq(cvxCRVCompounder.totalSupply(), 0, "testDeposit: E41");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testDeposit: E42");
    }

    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);
        
        // ---------------- get assets ----------------

        _getAssetFromETH(alice, CRV, _amount);
        _getAssetFromETH(bob, CRV, _amount);
        _getAssetFromETH(charlie, CRV, _amount);

        // ---------------- deposit ----------------

        vm.startPrank(alice);
        amount = IERC20(CRV).balanceOf(address(alice));
        _approve(CRV, address(cvxCRVCompounder), amount);
        aliceAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(alice), 0);
        accumulatedShares += aliceAmountOut;
        vm.stopPrank();

        assertEq(IERC20(CRV).balanceOf(address(alice)), 0, "testWithdraw: E1");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), aliceAmountOut, "testWithdraw: E2");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testWithdraw: E3");

        vm.startPrank(bob);
        amount = IERC20(CRV).balanceOf(address(bob));
        _approve(CRV, address(cvxCRVCompounder), amount);
        bobAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(bob), 0);
        accumulatedShares += bobAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), 0, "testWithdraw: E4");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), bobAmountOut, "testWithdraw: E5");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testWithdraw: E6");

        vm.startPrank(charlie);
        amount = IERC20(CRV).balanceOf(address(charlie));
        _approve(CRV, address(cvxCRVCompounder), amount);
        charlieAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(charlie), 0);
        accumulatedShares += charlieAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), 0, "testWithdraw: E7");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), charlieAmountOut, "testWithdraw: E8");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testWithdraw: E9");

        assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testWithdraw: E10");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testWithdraw: E11");
        assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testWithdraw: E12");

        // ---------------- harvest ----------------

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testWithdraw: E13");

        // Fast forward 1 month
        skip(216000);

        assertEq(cvxCRVCompounder.isPendingRewards(), true, "testWithdraw: E14");

        vm.prank(harvester);
        cvxCRVCompounder.harvest(address(harvester), 0);

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testWithdraw: E15");
        assertTrue(IERC20(cvxCRV).balanceOf(harvester) > 0, "testWithdraw: E16");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testWithdraw: E17");

        assertTrue(IERC20(cvxCRV).balanceOf(platform) > 0, "testWithdraw: E18");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testWithdraw: E19");

        // ---------------- withdraw ----------------

        shares = cvxCRVCompounder.balanceOf(address(alice));
        uint256 assetsClaim = cvxCRVCompounder.previewRedeem(shares);
        vm.prank(alice);
        uint256 aliceSharesOut = cvxCRVCompounder.withdraw(assetsClaim, address(alice), address(alice));
        
        assertEq(IERC20(cvxCRV).balanceOf(address(alice)), assetsClaim, "testWithdraw: E20");
        assertApproxEqAbs(aliceSharesOut, shares, 1e17, "testWithdraw: E21");
        assertApproxEqAbs(cvxCRVCompounder.balanceOf(address(alice)), 0, 1e17, "testWithdraw: E22");
        
        shares = cvxCRVCompounder.balanceOf(address(bob));
        assetsClaim = cvxCRVCompounder.previewRedeem(shares);
        vm.prank(bob);
        uint256 bobSharesOut = cvxCRVCompounder.withdraw(assetsClaim, address(bob), address(bob));
        
        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), assetsClaim, "testWithdraw: E23");
        assertApproxEqAbs(shares, bobSharesOut, 1e17, "testWithdraw: E24");
        assertApproxEqAbs(cvxCRVCompounder.balanceOf(address(bob)), 0, 1e17, "testWithdraw: E25");
        
        shares = cvxCRVCompounder.balanceOf(address(charlie));
        assetsClaim = cvxCRVCompounder.previewRedeem(shares);
        vm.prank(charlie);
        uint256 charlieSharesOut = cvxCRVCompounder.withdraw(assetsClaim, address(charlie), address(charlie));
        
        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), assetsClaim, "testWithdraw: E26");
        assertApproxEqAbs(shares, charlieSharesOut, 1e17, "testWithdraw: E27");
        assertApproxEqAbs(cvxCRVCompounder.balanceOf(address(charlie)), 0, 1e17, "testWithdraw: E28");
        
        assertApproxEqAbs(charlieSharesOut, bobSharesOut, 1e19, "testWithdraw: E29");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testWithdraw: E30");
        assertApproxEqAbs(cvxCRVCompounder.totalAssets(), 0, 1e20, "testWithdraw: E31");
        assertApproxEqAbs(cvxCRVCompounder.totalSupply(), 0, 1e18, "testWithdraw: E32");
    }

    function testRedeemUnderlying(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _getAssetFromETH(alice, CRV, _amount);
        _getAssetFromETH(bob, CRV, _amount);
        _getAssetFromETH(charlie, CRV, _amount);

        // ---------------- deposit ----------------

        vm.startPrank(alice);
        amount = IERC20(CRV).balanceOf(address(alice));
        _approve(CRV, address(cvxCRVCompounder), amount);
        aliceAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(alice), 0);
        accumulatedShares += aliceAmountOut;
        vm.stopPrank();

        assertEq(IERC20(CRV).balanceOf(address(alice)), 0, "testRedeemUnderlying: E1");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), aliceAmountOut, "testRedeemUnderlying: E2");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E3");

        vm.startPrank(bob);
        amount = IERC20(CRV).balanceOf(address(bob));
        _approve(CRV, address(cvxCRVCompounder), amount);
        bobAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(bob), 0);
        accumulatedShares += bobAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(bob)), 0, "testRedeemUnderlying: E4");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), bobAmountOut, "testRedeemUnderlying: E5");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E6");

        vm.startPrank(charlie);
        amount = IERC20(CRV).balanceOf(address(charlie));
        _approve(CRV, address(cvxCRVCompounder), amount);
        charlieAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(charlie), 0);
        accumulatedShares += charlieAmountOut;
        vm.stopPrank();

        assertEq(IERC20(cvxCRV).balanceOf(address(charlie)), 0, "testRedeemUnderlying: E7");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), charlieAmountOut, "testRedeemUnderlying: E8");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E9");

        assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testRedeemUnderlying: E10");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testRedeemUnderlying: E11");
        assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testRedeemUnderlying: E12");

        // ---------------- harvest ----------------

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testRedeemUnderlying: E13");

        // Fast forward 1 month
        skip(216000);

        assertEq(cvxCRVCompounder.isPendingRewards(), true, "testRedeemUnderlying: E14");

        vm.prank(harvester);
        cvxCRVCompounder.harvest(address(harvester), 0);

        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testRedeemUnderlying: E15");
        assertTrue(IERC20(cvxCRV).balanceOf(harvester) > 0, "testRedeemUnderlying: E16");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E17");

        assertTrue(IERC20(cvxCRV).balanceOf(platform) > 0, "testRedeemUnderlying: E18");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E19");

        // ---------------- redeem ---------------

        shares = cvxCRVCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = cvxCRVCompounder.redeemUnderlying(shares, address(alice), address(alice), 0);
        accumulatedShares -= shares;

        assertEq(IERC20(CRV).balanceOf(address(alice)), aliceAmountOut, "testRedeemUnderlying: E20");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), 0, "testRedeemUnderlying: E21");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E22");

        shares = cvxCRVCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = cvxCRVCompounder.redeemUnderlying(shares, address(bob), address(bob), 0);
        accumulatedShares -= shares;

        assertEq(IERC20(CRV).balanceOf(address(bob)), bobAmountOut, "testRedeemUnderlying: E23");
        assertEq(cvxCRVCompounder.balanceOf(address(bob)), 0, "testRedeemUnderlying: E24");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E25");

        shares = cvxCRVCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = cvxCRVCompounder.redeemUnderlying(shares, address(charlie), address(charlie), 0);
        accumulatedShares -= shares;

        assertEq(IERC20(CRV).balanceOf(address(charlie)), charlieAmountOut, "testRedeemUnderlying: E26");
        assertEq(cvxCRVCompounder.balanceOf(address(charlie)), 0, "testRedeemUnderlying: E27");
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testRedeemUnderlying: E28");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E29");

        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testRedeemUnderlying: E37");
        assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testRedeemUnderlying: E38");
        assertEq(accumulatedShares, 0, "testRedeemUnderlying: E39");
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testRedeemUnderlying: E40");
        assertEq(cvxCRVCompounder.totalSupply(), 0, "testRedeemUnderlying: E41");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testRedeemUnderlying: E42");
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test view functions ------------------------------------
    // ------------------------------------------------------------------------------------------

    function testTotalAssets() public {
        assertEq(cvxCRVCompounder.totalAssets(), 0, "testTotalAssets: E1");
    }

    function testIsPendingRewards() public {
        assertEq(cvxCRVCompounder.isPendingRewards(), false, "testIsPendingRewards: E1");
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test wrong flows ---------------------------------------
    // ------------------------------------------------------------------------------------------

    function testDepositNoAssets(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        vm.startPrank(alice);
        amount = IERC20(CRV).balanceOf(address(alice));
        assertEq(amount, 0, "testDepositNoAssets: E1");
        _approve(CRV, address(cvxCRVCompounder), amount);
        vm.expectRevert();
        aliceAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(alice), 0);

        amount = IERC20(cvxCRV).balanceOf(address(alice));
        assertEq(amount, 0, "testDepositNoAssets: E2");
        _approve(cvxCRV, address(cvxCRVCompounder), amount);
        vm.expectRevert();
        aliceAmountOut = cvxCRVCompounder.deposit(amount, address(alice));

        vm.stopPrank();
    }

    function testWithdrawNoShares(uint256 _amount, uint256 _fakeShares) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _getAssetFromETH(alice, CRV, _amount);

        vm.startPrank(alice);
        amount = IERC20(CRV).balanceOf(address(alice));
        _approve(CRV, address(cvxCRVCompounder), amount);
        aliceAmountOut = cvxCRVCompounder.depositUnderlying(amount, address(alice), 0);
        accumulatedShares += aliceAmountOut;
        vm.stopPrank();

        assertEq(IERC20(CRV).balanceOf(address(alice)), 0, "testWithdrawNoShares: E1");
        assertEq(cvxCRVCompounder.balanceOf(address(alice)), aliceAmountOut, "testWithdrawNoShares: E2");
        assertEq(cvxCRVCompounder.totalSupply(), accumulatedShares, "testWithdrawNoShares: E3");

        vm.startPrank(bob);
        vm.expectRevert();
        bobAmountOut = cvxCRVCompounder.redeemUnderlying(_fakeShares, address(bob), address(bob), 0);

        vm.expectRevert();
        bobAmountOut = cvxCRVCompounder.redeem(_fakeShares, address(bob), address(bob));

        vm.expectRevert();
        bobAmountOut = cvxCRVCompounder.withdraw(_amount, address(bob), address(bob));
        
        vm.stopPrank();
    }

    function testHarvestNoRewards(uint256 _amount) public {
        vm.startPrank(alice);
        vm.expectRevert();
        aliceAmountOut = cvxCRVCompounder.harvest(address(alice), _amount);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- internal functions -------------------------------------
    // ------------------------------------------------------------------------------------------

    function _approve(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }
}