// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

// import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";

// import "test/arbitrum/compounders/token/BaseTest.sol";

// contract MonitorGlpCompounder is BaseTest, InitGlpCompounder {
    
//     using SafeERC20 for IERC20;

//     GlpCompounder glpCompounder;
    
//     function setUp() public {
        
//         _setUp();

//         fortressSwap = FortressArbiSwap(payable(address(FortressSwapV1)));
//         fortressRegistry = FortressArbiRegistry(address(FortressRegistryV1));

//         address _compounder = address(FortGLP);

//         glpCompounder = GlpCompounder(_compounder);
//     }

//     function testCorrectFlowWETH(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(address(alice));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowWETH: E1");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowWETH: E2");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowWETH: E7");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowWETH: E8");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowWETH: E9");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowWETH: E12");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowWETH: E13");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowWETH: E14");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowWETH: E17");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowWETH: E19");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowWETH: E19");
        
//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowWETH: E23");

//         vm.prank(harvester);
//         uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);
        
//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowWETH: E24");
//         assertTrue(_rewardsOut > 0, "testCorrectFlowWETH: E25");
        
//         // ---------------- redeem ---------------

//         shares = glpCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(alice), address(alice), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowWETH: E29");
//         assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowWETH: E30");
        
//         shares = glpCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(bob), address(bob), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowWETH: E33");
//         assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowWETH: E34");
        
//         shares = glpCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(charlie), address(charlie), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowWETH: E37");
//         assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowWETH: E38");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowWETH: E43");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testCorrectFlowWETH: E043");
//     }

//     function testCorrectFlowWETHHarvestLink(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(address(alice));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowWETHHarvestLink: E1");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowWETHHarvestLink: E2");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowWETHHarvestLink: E7");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowWETHHarvestLink: E8");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowWETHHarvestLink: E9");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowWETHHarvestLink: E12");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowWETHHarvestLink: E13");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowWETHHarvestLink: E14");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowWETHHarvestLink: E17");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowWETHHarvestLink: E19");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowWETHHarvestLink: E19");
        
//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowWETHHarvestLink: E23");

//         vm.prank(harvester);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 _harvestRewards = glpCompounder.harvest(address(harvester), LINK, 0);
        
//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowWETHHarvestLink: E24");
//         assertTrue(_harvestRewards > 0, "testCorrectFlowWETHHarvestLink: E25");

//         // ---------------- redeem ---------------

//         shares = glpCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(alice), address(alice), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowWETHHarvestLink: E29");
//         assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowWETHHarvestLink: E30");
        
//         shares = glpCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(bob), address(bob), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowWETHHarvestLink: E33");
//         assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowWETHHarvestLink: E34");
        
//         shares = glpCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(charlie), address(charlie), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowWETHHarvestLink: E37");
//         assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowWETHHarvestLink: E38");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowWETHHarvestLink: E43");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testCorrectFlowWETHHarvestLink: E043");
//     }

//     function testCorrectFlowWETHHarvestFrax(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(address(alice));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowWETHHarvestLink: E1");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowWETHHarvestLink: E2");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowWETHHarvestLink: E7");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowWETHHarvestLink: E8");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowWETHHarvestLink: E9");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowWETHHarvestLink: E12");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowWETHHarvestLink: E13");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowWETHHarvestLink: E14");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowWETHHarvestLink: E17");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowWETHHarvestLink: E19");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowWETHHarvestLink: E19");
        
//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowWETHHarvestLink: E23");

//         vm.prank(harvester);
//         uint256 _harvestRewards = glpCompounder.harvest(address(harvester), FRAX, 0);
        
//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowWETHHarvestLink: E24");
//         assertTrue(_harvestRewards > 0, "testCorrectFlowWETHHarvestLink: E028");

//         // ---------------- redeem ---------------

//         shares = glpCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(alice), address(alice), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowWETHHarvestLink: E29");
//         assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowWETHHarvestLink: E30");
        
//         shares = glpCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(bob), address(bob), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowWETHHarvestLink: E33");
//         assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowWETHHarvestLink: E34");
        
//         shares = glpCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(charlie), address(charlie), 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowWETHHarvestLink: E37");
//         assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowWETHHarvestLink: E38");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowWETHHarvestLink: E43");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testCorrectFlowWETHHarvestLink: E043");
//     }

//     // function testCorrectFlowUSDC(uint256 _amount) public {
//     //     vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//     //     // ---------------- get assets ----------------
        
//     //     _wrapETH(alice, _amount);
//     //     assertEq(IERC20(WETH).balanceOf(alice), _amount);

//     //     _wrapETH(bob, _amount);
//     //     assertEq(IERC20(WETH).balanceOf(bob), _amount);

//     //     _wrapETH(charlie, _amount);
//     //     assertEq(IERC20(WETH).balanceOf(charlie), _amount);
        
//     //     // ---------------- swap to USDC ----------------
        
//     //     vm.startPrank(alice);
//     //     IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max); 
//     //     uint256 _amountOut = fortressSwap.swap(WETH, USDC, _amount);
//     //     uint256 aliceAmount = IERC20(USDC).balanceOf(alice);
//     //     assertEq(aliceAmount, _amountOut, "testCorrectFlowUSDC: E1");
//     //     assertTrue(aliceAmount > 0, "testCorrectFlowUSDC: E2");
//     //     vm.stopPrank();
        
//     //     vm.startPrank(bob);
//     //     IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max);
//     //     _amountOut = fortressSwap.swap(WETH, USDC, _amount);
//     //     uint256 bobAmount = IERC20(USDC).balanceOf(bob);
//     //     assertEq(bobAmount, _amountOut, "testCorrectFlowUSDC: E3");
//     //     assertTrue(bobAmount > 0, "testCorrectFlowUSDC: E4");
//     //     vm.stopPrank();

//     //     vm.startPrank(charlie);
//     //     IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max);
//     //     _amountOut = fortressSwap.swap(WETH, USDC, _amount);
//     //     uint256 charlieAmount = IERC20(USDC).balanceOf(charlie);
//     //     assertEq(charlieAmount, _amountOut, "testCorrectFlowUSDC: E5");
//     //     assertTrue(charlieAmount > 0, "testCorrectFlowUSDC: E6");
//     //     vm.stopPrank();

//     //     assertEq(charlieAmount, aliceAmount, "testCorrectFlowUSDC: E7");
//     //     assertEq(charlieAmount, bobAmount, "testCorrectFlowUSDC: E8");

//     //     // ---------------- deposit USDC ----------------

//     //     uint256 _amountUSDC = aliceAmount < bobAmount ? aliceAmount : bobAmount;
//     //     _amountUSDC = _amountUSDC < charlieAmount ? _amountUSDC : charlieAmount;

//     //     vm.startPrank(address(alice));
//     //     IERC20(USDC).safeApprove(address(glpCompounder), type(uint256).max); 
//     //     uint256 aliceSharesOut = glpCompounder.depositUnderlying(USDC, _amountUSDC, alice, 0);
        
//     //     assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowUSDC: E47");
//     //     assertTrue(IERC20(fsGLP).balanceOf(address(glpCompounder)) > 0, "testCorrectFlowUSDC: E049");
//     //     assertTrue(aliceSharesOut > 0, "testCorrectFlowUSDC: E52");
//     //     vm.stopPrank();

//     //     vm.startPrank(address(bob));
//     //     IERC20(USDC).safeApprove(address(glpCompounder), type(uint256).max);
//     //     uint256 bobSharesOut = glpCompounder.depositUnderlying(USDC, _amountUSDC, bob, 0);
        
//     //     assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowUSDC: E53");
//     //     assertTrue(bobSharesOut > 0, "testCorrectFlowUSDC: E56");
//     //     vm.stopPrank();

//     //     vm.startPrank(address(charlie));
//     //     IERC20(USDC).safeApprove(address(glpCompounder), type(uint256).max);
//     //     uint256 charlieSharesOut = glpCompounder.depositUnderlying(USDC, _amountUSDC, charlie, 0);
        
//     //     assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowUSDC: E57");
//     //     assertTrue(charlieSharesOut > 0, "testCorrectFlowUSDC: E60");
//     //     vm.stopPrank();

//     //     assertEq(aliceSharesOut, bobSharesOut, "testCorrectFlowUSDC: E62");
//     //     assertEq(aliceSharesOut, charlieSharesOut, "testCorrectFlowUSDC: E63");

//     //     // ---------------- harvest ----------------

//     //     // Fast forward 1 month
//     //     skip(216000);

//     //     assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowUSDC: E67");

//     //     vm.prank(harvester);
//     //     uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//     //     uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);
        
//     //     assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowUSDC: E67");
//     //     assertTrue(_rewardsOut > 0, "testCorrectFlowUSDC: E72");
//     //     assertEq((IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before), _rewardsOut, "testCorrectFlowUSDC: E73");


//     //     // ---------------- redeem ---------------

//     //     assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowUSDC: E074");
//     //     assertEq(charlieSharesOut, aliceSharesOut, "testCorrectFlowUSDC: E075");
//     //     assertEq(charlieSharesOut, bobSharesOut, "testCorrectFlowUSDC: E076");
//     //     assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowUSDC: E076");
//     //     assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowUSDC: E077");

//     //     shares = glpCompounder.balanceOf(address(alice));
//     //     _before = IERC20(USDC).balanceOf(address(alice));
//     //     vm.prank(alice);
//     //     aliceAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(alice), address(alice), 0);
//     //     aliceAmount = IERC20(USDC).balanceOf(address(alice)) - _before;
        
//     //     assertEq(aliceAmountOut, aliceAmount, "testCorrectFlowUSDC: E73");
//     //     assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowUSDC: E74");
        
//     //     shares = glpCompounder.balanceOf(address(bob));
//     //     _before = IERC20(USDC).balanceOf(address(bob));
//     //     vm.prank(bob);
//     //     bobAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(bob), address(bob), 0);
//     //     bobAmount = IERC20(USDC).balanceOf(address(bob)) - _before;
        
//     //     assertEq(bobAmount, bobAmountOut, "testCorrectFlowUSDC: E77");
//     //     assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowUSDC: E78");
        
//     //     shares = glpCompounder.balanceOf(address(charlie));
//     //     _before = IERC20(USDC).balanceOf(address(charlie));
//     //     vm.prank(charlie);
//     //     charlieAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(charlie), address(charlie), 0);
//     //     charlieAmount = IERC20(USDC).balanceOf(address(charlie)) - _before;
        
//     //     assertEq(charlieAmount, charlieAmountOut, "testCorrectFlowUSDC: E81");
//     //     assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowUSDC: E82");
        
//     //     assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowUSDC: E88");
//     //     assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testCorrectFlowUSDC: E89");
//     // }

//     function testCorrectFlowFRAX(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- swap to FRAX ----------------
        
//         vm.startPrank(alice);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max); 
//         uint256 _amountOut = fortressSwap.swap(WETH, FRAX, _amount);
//         uint256 aliceAmount = IERC20(FRAX).balanceOf(alice);
//         assertEq(aliceAmount, _amountOut, "testCorrectFlowFRAX: E1");
//         assertTrue(aliceAmount > 0, "testCorrectFlowFRAX: E2");
//         vm.stopPrank();

//         vm.startPrank(bob);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max);
//         _amountOut = fortressSwap.swap(WETH, FRAX, _amount);
//         uint256 bobAmount = IERC20(FRAX).balanceOf(bob);
//         assertEq(bobAmount, _amountOut, "testCorrectFlowFRAX: E3");
//         assertTrue(bobAmount > 0, "testCorrectFlowFRAX: E4");
//         vm.stopPrank();

//         vm.startPrank(charlie);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max);
//         _amountOut = fortressSwap.swap(WETH, FRAX, _amount);
//         uint256 charlieAmount = IERC20(FRAX).balanceOf(charlie);
//         assertEq(charlieAmount, _amountOut, "testCorrectFlowFRAX: E5");
//         assertTrue(charlieAmount > 0, "testCorrectFlowFRAX: E6");
//         vm.stopPrank();

//         assertEq(charlieAmount, aliceAmount, "testCorrectFlowFRAX: E7");
//         assertEq(charlieAmount, bobAmount, "testCorrectFlowFRAX: E8");

//         // ---------------- deposit FRAX ----------------

//         uint256 _amountFRAX = aliceAmount < bobAmount ? aliceAmount : bobAmount;
//         _amountFRAX = _amountFRAX < charlieAmount ? _amountFRAX : charlieAmount;

//         vm.startPrank(address(alice));
//         IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(FRAX, _amountFRAX, alice, 0);
        
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowFRAX: E47");
//         assertTrue(IERC20(fsGLP).balanceOf(address(glpCompounder)) > 0, "testCorrectFlowFRAX: E049");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowFRAX: E52");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(FRAX, _amountFRAX, bob, 0);
        
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowFRAX: E53");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowFRAX: E56");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(FRAX, _amountFRAX, charlie, 0);
        
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowFRAX: E57");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowFRAX: E60");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e18, "testCorrectFlowFRAX: E62");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e18, "testCorrectFlowFRAX: E63");

//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowFRAX: E67");

//         vm.prank(harvester);
//         uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);
        
//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowFRAX: E67");
//         assertTrue(_rewardsOut > 0, "testCorrectFlowFRAX: E72");
//         assertEq((IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before), _rewardsOut, "testCorrectFlowFRAX: E73");

//         // ---------------- redeem ---------------

//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowFRAX: E074");
//         assertApproxEqAbs(charlieSharesOut, aliceSharesOut, 1e18, "testCorrectFlowFRAX: E075");
//         assertApproxEqAbs(charlieSharesOut, bobSharesOut, 1e18, "testCorrectFlowFRAX: E076");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowFRAX: E076");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowFRAX: E077");

//         shares = glpCompounder.balanceOf(address(alice));
//         _before = IERC20(FRAX).balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(alice), address(alice), 0);
//         aliceAmount = IERC20(FRAX).balanceOf(address(alice)) - _before;
        
//         assertEq(aliceAmountOut, aliceAmount, "testCorrectFlowFRAX: E73");
//         assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowFRAX: E74");
        
//         shares = glpCompounder.balanceOf(address(bob));
//         _before = IERC20(FRAX).balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(bob), address(bob), 0);
//         bobAmount = IERC20(FRAX).balanceOf(address(bob)) - _before;
        
//         assertEq(bobAmount, bobAmountOut, "testCorrectFlowFRAX: E77");
//         assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowFRAX: E78");
        
//         shares = glpCompounder.balanceOf(address(charlie));
//         _before = IERC20(FRAX).balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(charlie), address(charlie), 0);
//         charlieAmount = IERC20(FRAX).balanceOf(address(charlie)) - _before;
        
//         assertEq(charlieAmount, charlieAmountOut, "testCorrectFlowFRAX: E81");
//         assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowFRAX: E82");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e20, "testCorrectFlowFRAX: E88");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e20, "testCorrectFlowFRAX: E89");
//     }

//     function testCorrectFlowLINK(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- swap to LINK ----------------
        
//         vm.startPrank(alice);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max); 
//         uint256 _amountOut = fortressSwap.swap(WETH, LINK, _amount);
//         uint256 aliceAmount = IERC20(LINK).balanceOf(alice);
//         assertEq(aliceAmount, _amountOut, "testCorrectFlowLINK: E1");
//         assertTrue(aliceAmount > 0, "testCorrectFlowLINK: E2");
//         vm.stopPrank();

//         vm.startPrank(bob);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max);
//         _amountOut = fortressSwap.swap(WETH, LINK, _amount);
//         uint256 bobAmount = IERC20(LINK).balanceOf(bob);
//         assertEq(bobAmount, _amountOut, "testCorrectFlowLINK: E3");
//         assertTrue(bobAmount > 0, "testCorrectFlowLINK: E4");
//         vm.stopPrank();

//         vm.startPrank(charlie);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max);
//         _amountOut = fortressSwap.swap(WETH, LINK, _amount);
//         uint256 charlieAmount = IERC20(LINK).balanceOf(charlie);
//         assertEq(charlieAmount, _amountOut, "testCorrectFlowLINK: E5");
//         assertTrue(charlieAmount > 0, "testCorrectFlowLINK: E6");
//         vm.stopPrank();

//         assertApproxEqAbs(charlieAmount, aliceAmount, 1e18, "testCorrectFlowLINK: E7");
//         assertApproxEqAbs(charlieAmount, bobAmount, 1e18, "testCorrectFlowLINK: E8");

//         // ---------------- deposit LINK ----------------

//         uint256 _amountLINK = aliceAmount < bobAmount ? aliceAmount : bobAmount;
//         _amountLINK = _amountLINK < charlieAmount ? _amountLINK : charlieAmount;

//         vm.startPrank(address(alice));
//         IERC20(LINK).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(LINK, _amountLINK, alice, 0);
        
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowLINK: E47");
//         assertTrue(IERC20(fsGLP).balanceOf(address(glpCompounder)) > 0, "testCorrectFlowLINK: E049");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowLINK: E52");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(LINK).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(LINK, _amountLINK, bob, 0);
        
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowLINK: E53");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowLINK: E56");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(LINK).safeApprove(address(glpCompounder), type(uint256).max);
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(LINK, _amountLINK, charlie, 0);
        
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowLINK: E57");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowLINK: E60");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e18, "testCorrectFlowLINK: E62");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e18, "testCorrectFlowLINK: E63");

//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowLINK: E67");

//         vm.prank(harvester);
//         uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);
        
//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowLINK: E67");
//         assertTrue(_rewardsOut > 0, "testCorrectFlowLINK: E72");
        
//         // ---------------- redeem ---------------

//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowLINK: E074");
//         assertApproxEqAbs(charlieSharesOut, aliceSharesOut, 1e18, "testCorrectFlowLINK: E075");
//         assertApproxEqAbs(charlieSharesOut, bobSharesOut, 1e18, "testCorrectFlowLINK: E076");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowLINK: E076");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowLINK: E077");

//         shares = glpCompounder.balanceOf(address(alice));
//         _before = IERC20(LINK).balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = glpCompounder.redeemUnderlying(LINK, shares, address(alice), address(alice), 0);
//         aliceAmount = IERC20(LINK).balanceOf(address(alice)) - _before;
        
//         assertEq(aliceAmountOut, aliceAmount, "testCorrectFlowLINK: E73");
//         assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowLINK: E74");
        
//         shares = glpCompounder.balanceOf(address(bob));
//         _before = IERC20(LINK).balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = glpCompounder.redeemUnderlying(LINK, shares, address(bob), address(bob), 0);
//         bobAmount = IERC20(LINK).balanceOf(address(bob)) - _before;
        
//         assertEq(bobAmount, bobAmountOut, "testCorrectFlowLINK: E77");
//         assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowLINK: E78");
        
//         shares = glpCompounder.balanceOf(address(charlie));
//         _before = IERC20(LINK).balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = glpCompounder.redeemUnderlying(LINK, shares, address(charlie), address(charlie), 0);
//         charlieAmount = IERC20(LINK).balanceOf(address(charlie)) - _before;
        
//         assertEq(charlieAmount, charlieAmountOut, "testCorrectFlowLINK: E81");
//         assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowLINK: E82");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowLINK: E88");
//         assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "testCorrectFlowLINK: E89");
//     }
    
//     function testCorrectFlowGLP(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(address(alice));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowGLP: E1");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowGLP: E2");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowGLP: E7");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowGLP: E8");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowGLP: E9");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowGLP: E12");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowGLP: E13");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowGLP: E14");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowGLP: E17");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowGLP: E19");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowGLP: E19");

//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowGLP: E23");

//         vm.prank(harvester);
//         uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);

//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowGLP: E24");
//         assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testCorrectFlowGLP: E25");
//         assertTrue(_rewardsOut > 0, "testCorrectFlowGLP: E27");
        
//         // ---------------- redeem to GLP ----------------

//         shares = glpCompounder.balanceOf(address(alice));
//         vm.prank(alice);
//         aliceAmountOut = glpCompounder.redeem(shares, address(alice), address(alice));
        
//         assertEq(IERC20(fsGLP).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowGLP: E29");
//         assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowGLP: E30");
        
//         shares = glpCompounder.balanceOf(address(bob));
//         vm.prank(bob);
//         bobAmountOut = glpCompounder.redeem(shares, address(bob), address(bob));
        
//         assertEq(IERC20(fsGLP).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowGLP: E33");
//         assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowGLP: E34");
        
//         shares = glpCompounder.balanceOf(address(charlie));
//         vm.prank(charlie);
//         charlieAmountOut = glpCompounder.redeem(shares, address(charlie), address(charlie));
        
//         assertEq(IERC20(fsGLP).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowGLP: E37");
//         assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowGLP: E38");
        
//         assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowGLP: E42");
        
//         // ---------------- deposit GLP ----------------

//         vm.startPrank(address(alice));
//         IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(sGLP).balanceOf(address(alice));
//         aliceSharesOut = glpCompounder.deposit(_before, alice);
        
//         assertEq(IERC20(sGLP).balanceOf(address(alice)), 0, "testCorrectFlowGLP: E46");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowGLP: E47");
//         assertTrue(aliceSharesOut > 0, "testCorrectFlowGLP: E52");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(sGLP).balanceOf(address(bob));
//         bobSharesOut = glpCompounder.deposit(_before, bob);
        
//         assertEq(IERC20(sGLP).balanceOf(address(bob)), 0, "testCorrectFlowGLP: E53");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowGLP: E54");
//         assertTrue(bobSharesOut > 0, "testCorrectFlowGLP: E57");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(charlie));
//         charlieSharesOut = glpCompounder.deposit(_before, charlie);
        
//         assertEq(IERC20(sGLP).balanceOf(address(charlie)), 0, "testCorrectFlowGLP: E58");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowGLP: E59");
//         assertTrue(charlieSharesOut > 0, "testCorrectFlowGLP: E62");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowGLP: E64");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e20, "testCorrectFlowGLP: E65");
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- test wrong flows ---------------------------------------
//     // ------------------------------------------------------------------------------------------

//     function testHarvestMoreThanOnce(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ---------------- get assets ----------------

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         _wrapETH(bob, _amount);
//         assertEq(IERC20(WETH).balanceOf(bob), _amount);

//         _wrapETH(charlie, _amount);
//         assertEq(IERC20(WETH).balanceOf(charlie), _amount);

//         // ---------------- deposit ----------------

//         vm.startPrank(address(alice));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testHarvestMoreThanOnce: E1");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testHarvestMoreThanOnce: E2");
//         assertTrue(aliceSharesOut > 0, "testHarvestMoreThanOnce: E7");
//         vm.stopPrank();

//         vm.startPrank(address(bob));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testHarvestMoreThanOnce: E8");
//         assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testHarvestMoreThanOnce: E9");
//         assertTrue(bobSharesOut > 0, "testHarvestMoreThanOnce: E12");
//         vm.stopPrank();

//         vm.startPrank(address(charlie));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
//         _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
//         uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testHarvestMoreThanOnce: E13");
//         assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testHarvestMoreThanOnce: E14");
//         assertTrue(charlieSharesOut > 0, "testHarvestMoreThanOnce: E17");
//         vm.stopPrank();

//         assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testHarvestMoreThanOnce: E19");
//         assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testHarvestMoreThanOnce: E19");
        
//         // ---------------- harvest ----------------

//         // Fast forward 1 month
//         skip(216000);

//         assertEq(glpCompounder.isPendingRewards(), true, "testHarvestMoreThanOnce: E23");

//         vm.prank(harvester);
//         uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);

//         assertEq(glpCompounder.isPendingRewards(), false, "testHarvestMoreThanOnce: E24");
//         assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testHarvestMoreThanOnce: E25");
//         assertTrue(_rewardsOut > 0, "testHarvestMoreThanOnce: E26");
        
//         vm.expectRevert();
//         glpCompounder.harvest(address(harvester), 0);
//     }

//     function testDepositNoAssets(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         vm.startPrank(alice);
//         assertEq(IERC20(FRAX).balanceOf(address(alice)), 0, "testDepositNoAssets: E1");
//         IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max);
//         vm.expectRevert();
//         aliceAmountOut = glpCompounder.depositUnderlying(FRAX, _amount, alice, 0);

//         assertEq(IERC20(sGLP).balanceOf(address(alice)), 0, "testDepositNoAssets: E2");
//         IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
//         vm.expectRevert();
//         aliceAmountOut = glpCompounder.deposit(amount, address(alice));

//         vm.stopPrank();
//     }

//     function testWithdrawNoShares(uint256 _amount, uint256 _fakeShares) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         vm.startPrank(address(alice));
//         IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
//         uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        
//         assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testHarvestMoreThanOnce: E1");
//         assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testHarvestMoreThanOnce: E2");
//         assertTrue(aliceSharesOut > 0, "testHarvestMoreThanOnce: E7");
//         vm.stopPrank();

//         vm.startPrank(bob);
//         vm.expectRevert();
//         bobAmountOut = glpCompounder.redeemUnderlying(_fakeShares, address(bob), address(bob), 0);

//         vm.expectRevert();
//         bobAmountOut = glpCompounder.redeemUnderlying(WETH, _fakeShares, address(bob), address(bob), 0);

//         vm.expectRevert();
//         bobAmountOut = glpCompounder.redeem(_fakeShares, address(bob), address(bob));

//         vm.expectRevert();
//         bobAmountOut = glpCompounder.withdraw(_amount, address(bob), address(bob));
        
//         vm.stopPrank();
//     }

//     function testHarvestNoRewards(uint256 _amount) public {

//         // ---------------- harvest ----------------

//         if (glpCompounder.isPendingRewards()) {
//             assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowLINK: E67");

//             vm.prank(harvester);
//             uint256 _rewardsOut = glpCompounder.harvest(address(harvester), 0);

//             assertTrue(_rewardsOut > 0, "testCorrectFlowLINK: E72");
//         }
        
//         assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowLINK: E67");
        

//         vm.startPrank(alice);
//         vm.expectRevert();
//         aliceAmountOut = glpCompounder.harvest(address(alice), _amount);
//         vm.stopPrank();
//     }

//     // ---------------- swap ----------------

//     function testBalancerSwap(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         _wrapETH(alice, _amount);
//         assertEq(IERC20(WETH).balanceOf(alice), _amount);

//         vm.startPrank(alice);
//         IERC20(WETH).safeApprove(address(fortressSwap), type(uint256).max); 
//         uint256 _amountOut = fortressSwap.swap(WETH, WSTETH, _amount);
//         uint256 aliceAmount = IERC20(WSTETH).balanceOf(alice);
//         assertEq(aliceAmount, _amountOut, "testBaltest: E1");
//         assertTrue(aliceAmount > 0, "testBaltest: E2");
        
//         IERC20(WSTETH).safeApprove(address(fortressSwap), type(uint256).max); 
//         _amountOut = fortressSwap.swap(WSTETH, WETH, aliceAmount);
//         uint256 aliceAmountWETH = IERC20(WETH).balanceOf(alice);
//         assertEq(aliceAmountWETH, _amountOut, "testBaltest: E3");
//         assertTrue(aliceAmountWETH > 0, "testBaltest: E4");
        
//         vm.stopPrank();
//     }
// }