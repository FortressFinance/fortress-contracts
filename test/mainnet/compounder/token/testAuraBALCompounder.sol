// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "src/mainnet/compounders/balancer/AuraBalCompounder.sol";
// import "src/mainnet/interfaces/IBalancerVault.sol";
// import "src/mainnet/interfaces/IBalancerPool.sol";

// import "test/mainnet/compounder/token/TokenCompounderBaseTest.sol";

// contract testAuraBALCompounder is TokenCompounderBaseTest {
contract testAuraBALCompounder {}
//     using SafeERC20 for IERC20;

//     address BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

//     AuraBalCompounder auraBALCompounder;
    
//     function setUp() public {
        
//         _setUp();

//         auraBALCompounder = new AuraBalCompounder(owner, platform, address(fortressSwap));
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- test mutated functions ---------------------------------
//     // ------------------------------------------------------------------------------------------

//     function testDeposit(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _getAssetFromETH(alice, BAL, _amount);
//         _getAssetFromETH(bob, BAL, _amount);
//         _getAssetFromETH(charlie, BAL, _amount);

//         vm.startPrank(alice);
//         amount = _swapBALToAuraBAL(IERC20(BAL).balanceOf(alice), address(alice));
//         vm.stopPrank();
//         assertTrue(IERC20(auraBAL).balanceOf(address(alice)) == amount, "testDeposit: E01");

//         vm.startPrank(bob);
//         amount = _swapBALToAuraBAL(IERC20(BAL).balanceOf(bob), address(bob));
//         vm.stopPrank();
//         assertTrue(IERC20(auraBAL).balanceOf(address(bob)) == amount, "testDeposit: E02");

//         vm.startPrank(charlie);
//         amount = _swapBALToAuraBAL(IERC20(BAL).balanceOf(charlie), address(charlie));
//         vm.stopPrank();
//         assertTrue(IERC20(auraBAL).balanceOf(address(charlie)) == amount, "testDeposit: E03");

//         // ---------------- deposit ----------------

//         vm.startPrank(alice);
//         amount = IERC20(auraBAL).balanceOf(address(alice));
//         accumulatedAmount += amount;
//         _approve(auraBAL, address(auraBALCompounder), amount);
//         aliceAmountOut = auraBALCompounder.deposit(amount, address(alice));
//         accumulatedShares += aliceAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(alice)), 0, "testDeposit: E1");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), aliceAmountOut, "testDeposit: E2");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E3");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E4");

//         vm.startPrank(bob);
//         amount = IERC20(auraBAL).balanceOf(address(bob));
//         accumulatedAmount += amount;
//         _approve(auraBAL, address(auraBALCompounder), amount);
//         bobAmountOut = auraBALCompounder.deposit(amount, address(bob));
//         accumulatedShares += bobAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), 0, "testDeposit: E5");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), bobAmountOut, "testDeposit: E6");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E7");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E8");

//         vm.startPrank(charlie);
//         amount = IERC20(auraBAL).balanceOf(address(charlie));
//         accumulatedAmount += amount;
//         _approve(auraBAL, address(auraBALCompounder), amount);
//         charlieAmountOut = auraBALCompounder.deposit(amount, address(charlie));
//         accumulatedShares += charlieAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), 0, "testDeposit: E9");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), charlieAmountOut, "testDeposit: E10");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E11");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E12");

//         assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testDeposit: E13");
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testDeposit: E14");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testDeposit: E15");
        
//         // ---------------- harvest ----------------

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testDeposit: E16");

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(auraBALCompounder.isPendingRewards(), true, "testDeposit: E17");

//         vm.prank(harvester);
//         accumulatedAmount += auraBALCompounder.harvest(address(harvester), 0);

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testDeposit: E18");
//         assertTrue(IERC20(auraBAL).balanceOf(harvester) > 0, "testDeposit: E19");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E20");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E21");

//         assertTrue(IERC20(auraBAL).balanceOf(platform) > 0, "testDeposit: E22");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E23");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E24");

//         // ---------------- redeem ---------------

//         shares = auraBALCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = auraBALCompounder.redeem(shares, address(alice), address(alice));
//         accumulatedAmount -= aliceAmountOut;
//         accumulatedShares -= shares;

//         assertEq(IERC20(auraBAL).balanceOf(address(alice)), aliceAmountOut, "testDeposit: E25");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), 0, "testDeposit: E26");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E27");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E28");

//         shares = auraBALCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = auraBALCompounder.redeem(shares, address(bob), address(bob));
//         accumulatedAmount -= bobAmountOut;
//         accumulatedShares -= shares;

//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), bobAmountOut, "testDeposit: E29");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), 0, "testDeposit: E30");
//         assertEq(auraBALCompounder.totalAssets(), accumulatedAmount, "testDeposit: E31");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E32");

//         shares = auraBALCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = auraBALCompounder.redeem(shares, address(charlie), address(charlie));
        
//         accumulatedShares -= shares;

//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), charlieAmountOut, "testDeposit: E33");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), 0, "testDeposit: E34");
//         assertEq(auraBALCompounder.totalAssets(), 0, "testDeposit: E35");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E36");

//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testDeposit: E37");
//         assertEq(accumulatedShares, 0, "testDeposit: E39");
//         assertEq(auraBALCompounder.totalAssets(), 0, "testDeposit: E40");
//         assertEq(auraBALCompounder.totalSupply(), 0, "testDeposit: E41");
        
//         // Fast forward 1 month
//         skip(216000);
//         assertEq(auraBALCompounder.isPendingRewards(), false, "testDeposit: E42");
//     }

//     function testDepositUnwrapped(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _getAssetFromETH(alice, BAL, _amount);
//         _getAssetFromETH(bob, BAL, _amount);
//         _getAssetFromETH(charlie, BAL, _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(alice);
//         amount = IERC20(BAL).balanceOf(address(alice));
//         _approve(BAL, address(auraBALCompounder), amount);
//         aliceAmountOut = auraBALCompounder.depositUnderlying(amount, address(alice), 0);
//         accumulatedShares += aliceAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(BAL).balanceOf(address(alice)), 0, "testDepositUnwrapped: E1");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), aliceAmountOut, "testDepositUnwrapped: E2");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDepositUnwrapped: E3");

//         vm.startPrank(bob);
//         amount = IERC20(BAL).balanceOf(address(bob));
//         _approve(BAL, address(auraBALCompounder), amount);
//         bobAmountOut = auraBALCompounder.depositUnderlying(amount, address(bob), 0);
//         accumulatedShares += bobAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), 0, "testDepositUnwrapped: E4");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), bobAmountOut, "testDepositUnwrapped: E5");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDepositUnwrapped: E6");

//         vm.startPrank(charlie);
//         amount = IERC20(BAL).balanceOf(address(charlie));
//         _approve(BAL, address(auraBALCompounder), amount);
//         charlieAmountOut = auraBALCompounder.depositUnderlying(amount, address(charlie), 0);
//         accumulatedShares += charlieAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), 0, "testDepositUnwrapped: E7");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), charlieAmountOut, "testDepositUnwrapped: E8");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDepositUnwrapped: E9");

//         assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testDepositUnwrapped: E10");
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testDepositUnwrapped: E11");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testDepositUnwrapped: E12");

//         // ---------------- harvest ----------------

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testDeposit: E13");

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(auraBALCompounder.isPendingRewards(), true, "testDeposit: E14");

//         vm.prank(harvester);
//         auraBALCompounder.harvest(address(harvester), 0);

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testDeposit: E15");
//         assertTrue(IERC20(auraBAL).balanceOf(harvester) > 0, "testDeposit: E16");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E17");

//         assertTrue(IERC20(auraBAL).balanceOf(platform) > 0, "testDeposit: E18");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E19");

//         // ---------------- redeem ---------------

//         shares = auraBALCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = auraBALCompounder.redeem(shares, address(alice), address(alice));
//         accumulatedShares -= shares;

//         assertEq(IERC20(auraBAL).balanceOf(address(alice)), aliceAmountOut, "testDeposit: E20");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), 0, "testDeposit: E21");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E22");

//         shares = auraBALCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = auraBALCompounder.redeem(shares, address(bob), address(bob));
//         accumulatedShares -= shares;

//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), bobAmountOut, "testDeposit: E23");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), 0, "testDeposit: E24");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E25");

//         shares = auraBALCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = auraBALCompounder.redeem(shares, address(charlie), address(charlie));
//         accumulatedShares -= shares;

//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), charlieAmountOut, "testDeposit: E26");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), 0, "testDeposit: E27");
//         assertEq(auraBALCompounder.totalAssets(), 0, "testDeposit: E28");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testDeposit: E29");

//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testDeposit: E37");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testDeposit: E38");
//         assertEq(accumulatedShares, 0, "testDeposit: E39");
//         assertEq(auraBALCompounder.totalAssets(), 0, "testDeposit: E40");
//         assertEq(auraBALCompounder.totalSupply(), 0, "testDeposit: E41");
        
//         // Fast forward 1 month
//         skip(216000);
//         assertEq(auraBALCompounder.isPendingRewards(), false, "testDeposit: E42");
//     }

//     function testWithdraw(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _getAssetFromETH(alice, BAL, _amount);
//         _getAssetFromETH(bob, BAL, _amount);
//         _getAssetFromETH(charlie, BAL, _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(alice);
//         amount = IERC20(BAL).balanceOf(address(alice));
//         _approve(BAL, address(auraBALCompounder), amount);
//         aliceAmountOut = auraBALCompounder.depositUnderlying(amount, address(alice), 0);
//         accumulatedShares += aliceAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(BAL).balanceOf(address(alice)), 0, "testWithdraw: E1");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), aliceAmountOut, "testWithdraw: E2");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testWithdraw: E3");

//         vm.startPrank(bob);
//         amount = IERC20(BAL).balanceOf(address(bob));
//         _approve(BAL, address(auraBALCompounder), amount);
//         bobAmountOut = auraBALCompounder.depositUnderlying(amount, address(bob), 0);
//         accumulatedShares += bobAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), 0, "testWithdraw: E4");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), bobAmountOut, "testWithdraw: E5");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testWithdraw: E6");

//         vm.startPrank(charlie);
//         amount = IERC20(BAL).balanceOf(address(charlie));
//         _approve(BAL, address(auraBALCompounder), amount);
//         charlieAmountOut = auraBALCompounder.depositUnderlying(amount, address(charlie), 0);
//         accumulatedShares += charlieAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), 0, "testWithdraw: E7");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), charlieAmountOut, "testWithdraw: E8");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testWithdraw: E9");

//         assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testWithdraw: E10");
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testWithdraw: E11");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testWithdraw: E12");

//         // ---------------- harvest ----------------

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testWithdraw: E13");

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(auraBALCompounder.isPendingRewards(), true, "testWithdraw: E14");

//         vm.prank(harvester);
//         auraBALCompounder.harvest(address(harvester), 0);

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testWithdraw: E15");
//         assertTrue(IERC20(auraBAL).balanceOf(harvester) > 0, "testWithdraw: E16");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testWithdraw: E17");

//         assertTrue(IERC20(auraBAL).balanceOf(platform) > 0, "testWithdraw: E18");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testWithdraw: E19");

//         // ---------------- withdraw ----------------

//         shares = auraBALCompounder.balanceOf(address(alice));
//         uint256 assetsClaim = auraBALCompounder.previewRedeem(shares);
//         vm.prank(alice);
//         aliceAmountOut = auraBALCompounder.withdraw(assetsClaim, address(alice), address(alice));
        
//         assertEq(IERC20(auraBAL).balanceOf(address(alice)), assetsClaim, "testWithdraw: E20");
//         assertApproxEqAbs(IERC20(auraBAL).balanceOf(address(alice)), aliceAmountOut, 1e18, "testWithdraw: E21");
//         assertApproxEqAbs(auraBALCompounder.balanceOf(address(alice)), 0, 1e16, "testWithdraw: E22");
        
//         shares = auraBALCompounder.balanceOf(address(bob));
//         assetsClaim = auraBALCompounder.previewRedeem(shares);
//         vm.prank(bob);
//         bobAmountOut = auraBALCompounder.withdraw(assetsClaim, address(bob), address(bob));
        
//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), assetsClaim, "testWithdraw: E23");
//         assertApproxEqAbs(IERC20(auraBAL).balanceOf(address(bob)), bobAmountOut, 1e19, "testWithdraw: E24");
//         assertApproxEqAbs(auraBALCompounder.balanceOf(address(bob)), 0, 1e16, "testWithdraw: E25");
        
//         shares = auraBALCompounder.balanceOf(address(charlie));
//         assetsClaim = auraBALCompounder.previewRedeem(shares);
//         vm.prank(charlie);
//         charlieAmountOut = auraBALCompounder.withdraw(assetsClaim, address(charlie), address(charlie));
        
//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), assetsClaim, "testWithdraw: E26");
//         assertApproxEqAbs(IERC20(auraBAL).balanceOf(address(charlie)), charlieAmountOut, 1e20, "testWithdraw: E27");
//         assertApproxEqAbs(auraBALCompounder.balanceOf(address(charlie)), 0, 1e16, "testWithdraw: E28");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testWithdraw: E29");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testWithdraw: E30");
//         assertApproxEqAbs(auraBALCompounder.totalAssets(), 0, 1e18, "testWithdraw: E31");
//         assertApproxEqAbs(auraBALCompounder.totalSupply(), 0, 1e18, "testWithdraw: E32");
//     }

//     function testRedeemUnderlying(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _getAssetFromETH(alice, BAL, _amount);
//         _getAssetFromETH(bob, BAL, _amount);
//         _getAssetFromETH(charlie, BAL, _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(alice);
//         amount = IERC20(BAL).balanceOf(address(alice));
//         _approve(BAL, address(auraBALCompounder), amount);
//         aliceAmountOut = auraBALCompounder.depositUnderlying(amount, address(alice), 0);
//         accumulatedShares += aliceAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(BAL).balanceOf(address(alice)), 0, "testRedeemUnderlying: E1");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), aliceAmountOut, "testRedeemUnderlying: E2");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E3");

//         vm.startPrank(bob);
//         amount = IERC20(BAL).balanceOf(address(bob));
//         _approve(BAL, address(auraBALCompounder), amount);
//         bobAmountOut = auraBALCompounder.depositUnderlying(amount, address(bob), 0);
//         accumulatedShares += bobAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(bob)), 0, "testRedeemUnderlying: E4");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), bobAmountOut, "testRedeemUnderlying: E5");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E6");

//         vm.startPrank(charlie);
//         amount = IERC20(BAL).balanceOf(address(charlie));
//         _approve(BAL, address(auraBALCompounder), amount);
//         charlieAmountOut = auraBALCompounder.depositUnderlying(amount, address(charlie), 0);
//         accumulatedShares += charlieAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(auraBAL).balanceOf(address(charlie)), 0, "testRedeemUnderlying: E7");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), charlieAmountOut, "testRedeemUnderlying: E8");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E9");

//         assertEq((aliceAmountOut + bobAmountOut + charlieAmountOut), accumulatedShares, "testRedeemUnderlying: E10");
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testRedeemUnderlying: E11");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testRedeemUnderlying: E12");

//         // ---------------- harvest ----------------

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testRedeemUnderlying: E13");

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(auraBALCompounder.isPendingRewards(), true, "testRedeemUnderlying: E14");

//         vm.prank(harvester);
//         auraBALCompounder.harvest(address(harvester), 0);

//         assertEq(auraBALCompounder.isPendingRewards(), false, "testRedeemUnderlying: E15");
//         assertTrue(IERC20(auraBAL).balanceOf(harvester) > 0, "testRedeemUnderlying: E16");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E17");

//         assertTrue(IERC20(auraBAL).balanceOf(platform) > 0, "testRedeemUnderlying: E18");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E19");

//         // ---------------- redeem ---------------

//         shares = auraBALCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = auraBALCompounder.redeemUnderlying(shares, address(alice), address(alice), 0);
//         accumulatedShares -= shares;

//         assertEq(IERC20(BAL).balanceOf(address(alice)), aliceAmountOut, "testRedeemUnderlying: E20");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), 0, "testRedeemUnderlying: E21");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E22");

//         shares = auraBALCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = auraBALCompounder.redeemUnderlying(shares, address(bob), address(bob), 0);
//         accumulatedShares -= shares;

//         assertEq(IERC20(BAL).balanceOf(address(bob)), bobAmountOut, "testRedeemUnderlying: E23");
//         assertEq(auraBALCompounder.balanceOf(address(bob)), 0, "testRedeemUnderlying: E24");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E25");

//         shares = auraBALCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = auraBALCompounder.redeemUnderlying(shares, address(charlie), address(charlie), 0);
//         accumulatedShares -= shares;

//         assertEq(IERC20(BAL).balanceOf(address(charlie)), charlieAmountOut, "testRedeemUnderlying: E26");
//         assertEq(auraBALCompounder.balanceOf(address(charlie)), 0, "testRedeemUnderlying: E27");
//         assertEq(auraBALCompounder.totalAssets(), 0, "testRedeemUnderlying: E28");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testRedeemUnderlying: E29");

//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testRedeemUnderlying: E37");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testRedeemUnderlying: E38");
//         assertEq(accumulatedShares, 0, "testRedeemUnderlying: E39");
//         assertEq(auraBALCompounder.totalAssets(), 0, "testRedeemUnderlying: E40");
//         assertEq(auraBALCompounder.totalSupply(), 0, "testRedeemUnderlying: E41");
        
//         // Fast forward 1 month
//         skip(216000);
//         assertEq(auraBALCompounder.isPendingRewards(), false, "testRedeemUnderlying: E42");
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- test view functions ------------------------------------
//     // ------------------------------------------------------------------------------------------

//     function testTotalAssets() public {
//         assertEq(auraBALCompounder.totalAssets(), 0, "testTotalAssets: E1");
//     }

//     function testIsPendingRewards() public {
//         assertEq(auraBALCompounder.isPendingRewards(), false, "testIsPendingRewards: E1");
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- test wrong flows ---------------------------------------
//     // ------------------------------------------------------------------------------------------

//     function testDepositNoAssets(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         vm.startPrank(alice);
//         amount = IERC20(BAL).balanceOf(address(alice));
//         assertEq(amount, 0, "testDepositNoAssets: E1");
//         _approve(BAL, address(auraBALCompounder), amount);
//         vm.expectRevert();
//         aliceAmountOut = auraBALCompounder.depositUnderlying(amount, address(alice), 0);

//         amount = IERC20(auraBAL).balanceOf(address(alice));
//         assertEq(amount, 0, "testDepositNoAssets: E2");
//         _approve(auraBAL, address(auraBALCompounder), amount);
//         vm.expectRevert();
//         aliceAmountOut = auraBALCompounder.deposit(amount, address(alice));

//         vm.stopPrank();
//     }

//     function testWithdrawNoShares(uint256 _amount, uint256 _fakeShares) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         _getAssetFromETH(alice, BAL, _amount);

//         vm.startPrank(alice);
//         amount = IERC20(BAL).balanceOf(address(alice));
//         _approve(BAL, address(auraBALCompounder), amount);
//         aliceAmountOut = auraBALCompounder.depositUnderlying(amount, address(alice), 0);
//         accumulatedShares += aliceAmountOut;
//         vm.stopPrank();

//         assertEq(IERC20(BAL).balanceOf(address(alice)), 0, "testWithdrawNoShares: E1");
//         assertEq(auraBALCompounder.balanceOf(address(alice)), aliceAmountOut, "testWithdrawNoShares: E2");
//         assertEq(auraBALCompounder.totalSupply(), accumulatedShares, "testWithdrawNoShares: E3");

//         vm.startPrank(bob);
//         vm.expectRevert();
//         bobAmountOut = auraBALCompounder.redeemUnderlying(_fakeShares, address(bob), address(bob), 0);

//         vm.expectRevert();
//         bobAmountOut = auraBALCompounder.redeem(_fakeShares, address(bob), address(bob));

//         vm.expectRevert();
//         bobAmountOut = auraBALCompounder.withdraw(_amount, address(bob), address(bob));
        
//         vm.stopPrank();
//     }

//     function testHarvestNoRewards(uint256 _amount) public {
//         vm.startPrank(alice);
//         vm.expectRevert();
//         aliceAmountOut = auraBALCompounder.harvest(address(alice), _amount);
//         vm.stopPrank();
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- internal functions -------------------------------------
//     // ------------------------------------------------------------------------------------------

//     function _swapBALToAuraBAL(uint256 _amount, address _sender) internal returns (uint256) {
//         address[] memory _tokens = new address[](2);
//         uint256[] memory _amounts = new uint256[](2);

//         _tokens[0] = BAL;
//         _tokens[1] = WETH;
//         _amounts[0] = _amount;
//         _amounts[1] = 0;

//         _amount = _addLiquidity(BALANCER_WETHBAL, _tokens, _amounts, _sender);

//         _approve(BALANCER_WETHBAL, address(fortressSwap), _amount);
//         return fortressSwap.swap(BALANCER_WETHBAL, auraBAL, _amount);
//     }

//     function _addLiquidity(address _poolAddress, address[] memory _tokens, uint256[] memory _amounts, address _sender) internal returns (uint256) {
//         uint256 _before = IERC20(_poolAddress).balanceOf(address(_sender));
//         bytes32 _poolId = IBalancerPool(_poolAddress).getPoolId();

//         _approve(_tokens[0], BALANCER_VAULT, _amounts[0]);
//         IBalancerVault(BALANCER_VAULT).joinPool(
//             _poolId,
//             address(_sender),
//             address(_sender),
//             IBalancerVault.JoinPoolRequest({
//                 assets: _tokens,
//                 maxAmountsIn: _amounts,
//                 userData: abi.encode(
//                         IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
//                         _amounts,
//                         0
//                     ),
//                 fromInternalBalance: false
//             })
//         );
        
//         return (IERC20(_poolAddress).balanceOf(address(_sender)) - _before);
//     }

//     function _approve(address _token, address _spender, uint256 _amount) internal {
//         IERC20(_token).safeApprove(_spender, 0);
//         IERC20(_token).safeApprove(_spender, _amount);
//     }

// }
