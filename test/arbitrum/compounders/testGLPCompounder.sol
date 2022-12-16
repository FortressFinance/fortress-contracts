// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

import "test/arbitrum/BaseTest.sol";

contract testGLPCompounder is BaseTest {
    
    using SafeERC20 for IERC20;

    GlpCompounder glpCompounder;
    
    function setUp() public {
        
        _setUp();

        glpCompounder = new GlpCompounder(owner, platform, address(0));
    }

    function testCorrectFlowWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _wrapETH(alice, _amount);
        assertEq(IERC20(WETH).balanceOf(alice), _amount);

        _wrapETH(bob, _amount);
        assertEq(IERC20(WETH).balanceOf(bob), _amount);

        _wrapETH(charlie, _amount);
        assertEq(IERC20(WETH).balanceOf(charlie), _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowWETH: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowWETH: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowWETH: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E4");
        assertTrue(accumulatedShares > 0, "testCorrectFlowWETH: E5");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowWETH: E6");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowWETH: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowWETH: E8");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowWETH: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowWETH: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E11");
        assertTrue(bobSharesOut > 0, "testCorrectFlowWETH: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowWETH: E13");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowWETH: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowWETH: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E16");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowWETH: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowWETH: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowWETH: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowWETH: E19");
        
        // ---------------- harvest ----------------

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowWETH: E20");
        assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "testCorrectFlowWETH: E21");
        assertEq(IERC20(fsGLP).balanceOf(platform), 0, "testCorrectFlowWETH: E22");

        // Fast forward 1 month
        skip(216000);

        assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowWETH: E23");

        vm.prank(harvester);
        accumulatedAmount += glpCompounder.harvest(address(harvester), 0);

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowWETH: E24");
        assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testCorrectFlowWETH: E25");
        assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "testCorrectFlowWETH: E26");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowWETH: E27");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E28");

        // ---------------- redeem ---------------

        shares = glpCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(alice), address(alice), 0);
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(WETH).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowWETH: E29");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowWETH: E30");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowWETH: E31");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E32");

        shares = glpCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(bob), address(bob), 0);
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(WETH).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowWETH: E33");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowWETH: E34");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowWETH: E35");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E36");

        shares = glpCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(charlie), address(charlie), 0);
        // accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(WETH).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowWETH: E37");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowWETH: E38");
        // assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowWETH: E39");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowWETH: E40");

        // assertEq(accumulatedAmount, 0, "testCorrectFlowWETH: E41");
        assertEq(accumulatedShares, 0, "testCorrectFlowWETH: E42");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowWETH: E43");
        assertEq(glpCompounder.totalAssets(), 0, "testCorrectFlowWETH: E44");
        assertEq(glpCompounder.totalSupply(), 0, "testCorrectFlowWETH: E45");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowWETH: E46");
    }

    function testCorrectFlowUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _wrapETH(alice, _amount);
        assertEq(IERC20(WETH).balanceOf(alice), _amount);

        _wrapETH(bob, _amount);
        assertEq(IERC20(WETH).balanceOf(bob), _amount);

        _wrapETH(charlie, _amount);
        assertEq(IERC20(WETH).balanceOf(charlie), _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowUSDC: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowUSDC: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E4");
        assertTrue(accumulatedShares > 0, "testCorrectFlowUSDC: E5");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowUSDC: E6");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowUSDC: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowUSDC: E8");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowUSDC: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E11");
        assertTrue(bobSharesOut > 0, "testCorrectFlowUSDC: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowUSDC: E13");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowUSDC: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E16");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowUSDC: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowUSDC: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowUSDC: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowUSDC: E19");

        // ---------------- redeem to USDC ----------------

        shares = glpCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(alice), address(alice), 0);
        
        assertEq(IERC20(USDC).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowUSDC: E29");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowUSDC: E30");
        
        shares = glpCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(bob), address(bob), 0);
        
        assertEq(IERC20(USDC).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowUSDC: E33");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowUSDC: E34");
        
        shares = glpCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(charlie), address(charlie), 0);
        
        assertEq(IERC20(USDC).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowUSDC: E37");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowUSDC: E38");
        
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowUSDC: E43");
        assertEq(glpCompounder.totalAssets(), 0, "testCorrectFlowUSDC: E44");
        assertEq(glpCompounder.totalSupply(), 0, "testCorrectFlowUSDC: E45");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowUSDC: E46");

        // ---------------- deposit USDC ----------------

        uint256 _amountUSDC = aliceAmountOut < bobAmountOut ? aliceAmountOut : bobAmountOut;

        vm.startPrank(address(alice));
        IERC20(USDC).safeApprove(address(glpCompounder), type(uint256).max); 
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        aliceSharesOut = glpCompounder.depositUnderlying(USDC, _amountUSDC, alice, 0);
        accumulatedShares = aliceSharesOut;
        accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowUSDC: E47");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E48");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E49");
        assertTrue(accumulatedShares > 0, "testCorrectFlowUSDC: E50");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowUSDC: E51");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowUSDC: E52");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(USDC).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        bobSharesOut = glpCompounder.depositUnderlying(USDC, _amountUSDC, bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowUSDC: E53");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E54");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E55");
        assertTrue(bobSharesOut > 0, "testCorrectFlowUSDC: E56");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(USDC).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        charlieSharesOut = glpCompounder.depositUnderlying(USDC, _amountUSDC, charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowUSDC: E57");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E58");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E59");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowUSDC: E60");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowUSDC: E61");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowUSDC: E62");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowUSDC: E63");

        // ---------------- harvest ----------------

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowUSDC: E64");
        assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "testCorrectFlowUSDC: E65");
        assertEq(IERC20(fsGLP).balanceOf(platform), 0, "testCorrectFlowUSDC: E66");

        // Fast forward 1 month
        skip(216000);

        assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowUSDC: E67");

        vm.prank(harvester);
        accumulatedAmount += glpCompounder.harvest(address(harvester), 0);

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowUSDC: E67");
        assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testCorrectFlowUSDC: E68");
        assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "testCorrectFlowUSDC: E69");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowUSDC: E70");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E71");

        // ---------------- redeem ---------------

        shares = glpCompounder.balanceOf(address(alice));
        _before = IERC20(USDC).balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(alice), address(alice), 0);
        aliceAmountOut = IERC20(USDC).balanceOf(address(alice)) - _before;
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(USDC).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowUSDC: E73");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowUSDC: E74");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowUSDC: E75");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E76");

        shares = glpCompounder.balanceOf(address(bob));
        _before = IERC20(USDC).balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(bob), address(bob), 0);
        bobAmountOut = IERC20(USDC).balanceOf(address(bob)) - _before;
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertApproxEqAbs(IERC20(USDC).balanceOf(address(bob)), bobAmountOut, 1e14, "testCorrectFlowUSDC: E77");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowUSDC: E78");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowUSDC: E79");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E80");

        shares = glpCompounder.balanceOf(address(charlie));
        _before = IERC20(USDC).balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeemUnderlying(USDC, shares, address(charlie), address(charlie), 0);
        charlieAmountOut = IERC20(USDC).balanceOf(address(charlie)) - _before;
        accumulatedShares -= shares;

        assertApproxEqAbs(IERC20(USDC).balanceOf(address(charlie)), charlieAmountOut, 1e14, "testCorrectFlowUSDC: E81");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowUSDC: E82");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowUSDC: E83");

        assertEq(accumulatedShares, 0, "testCorrectFlowUSDC: E84");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowUSDC: E85");
        assertEq(glpCompounder.totalAssets(), 0, "testCorrectFlowUSDC: E86");
        assertEq(glpCompounder.totalSupply(), 0, "testCorrectFlowUSDC: E87");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowUSDC: E88");
    }

    function testCorrectFlowFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _wrapETH(alice, _amount);
        assertEq(IERC20(WETH).balanceOf(alice), _amount);

        _wrapETH(bob, _amount);
        assertEq(IERC20(WETH).balanceOf(bob), _amount);

        _wrapETH(charlie, _amount);
        assertEq(IERC20(WETH).balanceOf(charlie), _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowFRAX: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowFRAX: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E4");
        assertTrue(accumulatedShares > 0, "testCorrectFlowFRAX: E5");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowFRAX: E6");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowFRAX: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowFRAX: E8");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowFRAX: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E11");
        assertTrue(bobSharesOut > 0, "testCorrectFlowFRAX: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowFRAX: E13");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowFRAX: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E16");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowFRAX: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowFRAX: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowFRAX: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowFRAX: E19");

        // ---------------- redeem to FRAX ----------------

        shares = glpCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(alice), address(alice), 0);
        
        assertEq(IERC20(FRAX).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowFRAX: E29");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowFRAX: E30");
        
        shares = glpCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(bob), address(bob), 0);
        
        assertEq(IERC20(FRAX).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowFRAX: E33");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowFRAX: E34");
        
        shares = glpCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(charlie), address(charlie), 0);
        
        assertEq(IERC20(FRAX).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowFRAX: E37");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowFRAX: E38");
        
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowFRAX: E43");
        assertEq(glpCompounder.totalAssets(), 0, "testCorrectFlowFRAX: E44");
        assertEq(glpCompounder.totalSupply(), 0, "testCorrectFlowFRAX: E45");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowFRAX: E46");

        // ---------------- deposit FRAX ----------------

        uint256 _amountFRAX = aliceAmountOut < bobAmountOut ? aliceAmountOut : bobAmountOut;

        vm.startPrank(address(alice));
        IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max); 
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        aliceSharesOut = glpCompounder.depositUnderlying(FRAX, _amountFRAX, alice, 0);
        accumulatedShares = aliceSharesOut;
        accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowFRAX: E47");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E48");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E49");
        assertTrue(accumulatedShares > 0, "testCorrectFlowFRAX: E50");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowFRAX: E51");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowFRAX: E52");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        bobSharesOut = glpCompounder.depositUnderlying(FRAX, _amountFRAX, bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowFRAX: E53");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E54");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E55");
        assertTrue(bobSharesOut > 0, "testCorrectFlowFRAX: E56");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        charlieSharesOut = glpCompounder.depositUnderlying(FRAX, _amountFRAX, charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowFRAX: E57");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E58");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E59");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowFRAX: E60");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowFRAX: E61");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowFRAX: E62");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowFRAX: E63");

        // ---------------- harvest ----------------

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowFRAX: E64");
        assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "testCorrectFlowFRAX: E65");
        assertEq(IERC20(fsGLP).balanceOf(platform), 0, "testCorrectFlowFRAX: E66");

        // Fast forward 1 month
        skip(216000);

        assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowFRAX: E67");

        vm.prank(harvester);
        accumulatedAmount += glpCompounder.harvest(address(harvester), 0);

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowFRAX: E67");
        assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testCorrectFlowFRAX: E68");
        assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "testCorrectFlowFRAX: E69");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowFRAX: E70");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E71");

        // ---------------- redeem ---------------

        shares = glpCompounder.balanceOf(address(alice));
        _before = IERC20(FRAX).balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(alice), address(alice), 0);
        aliceAmountOut = IERC20(FRAX).balanceOf(address(alice)) - _before;
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(FRAX).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowFRAX: E73");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowFRAX: E74");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowFRAX: E75");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E76");

        shares = glpCompounder.balanceOf(address(bob));
        _before = IERC20(FRAX).balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(bob), address(bob), 0);
        bobAmountOut = IERC20(FRAX).balanceOf(address(bob)) - _before;
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertApproxEqAbs(IERC20(FRAX).balanceOf(address(bob)), bobAmountOut, 1e20, "testCorrectFlowFRAX: E77");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowFRAX: E78");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowFRAX: E79");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E80");

        shares = glpCompounder.balanceOf(address(charlie));
        _before = IERC20(FRAX).balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeemUnderlying(FRAX, shares, address(charlie), address(charlie), 0);
        charlieAmountOut = IERC20(FRAX).balanceOf(address(charlie)) - _before;
        accumulatedShares -= shares;

        assertApproxEqAbs(IERC20(FRAX).balanceOf(address(charlie)), charlieAmountOut, 1e20, "testCorrectFlowFRAX: E81");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowFRAX: E82");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowFRAX: E83");

        assertEq(accumulatedShares, 0, "testCorrectFlowFRAX: E84");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowFRAX: E85");
        assertEq(glpCompounder.totalAssets(), 0, "testCorrectFlowFRAX: E86");
        assertEq(glpCompounder.totalSupply(), 0, "testCorrectFlowFRAX: E87");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowFRAX: E88");
    }
    
    function testCorrectFlowGLP(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _wrapETH(alice, _amount);
        assertEq(IERC20(WETH).balanceOf(alice), _amount);

        _wrapETH(bob, _amount);
        assertEq(IERC20(WETH).balanceOf(bob), _amount);

        _wrapETH(charlie, _amount);
        assertEq(IERC20(WETH).balanceOf(charlie), _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testCorrectFlowGLP: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowGLP: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E4");
        assertTrue(accumulatedShares > 0, "testCorrectFlowGLP: E5");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowGLP: E6");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowGLP: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testCorrectFlowGLP: E8");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowGLP: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E11");
        assertTrue(bobSharesOut > 0, "testCorrectFlowGLP: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testCorrectFlowGLP: E13");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowGLP: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E16");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowGLP: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowGLP: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowGLP: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testCorrectFlowGLP: E19");

        // ---------------- harvest ----------------

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowGLP: E20");
        assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "testCorrectFlowGLP: E21");
        assertEq(IERC20(fsGLP).balanceOf(platform), 0, "testCorrectFlowGLP: E22");

        // Fast forward 1 month
        skip(216000);

        assertEq(glpCompounder.isPendingRewards(), true, "testCorrectFlowGLP: E23");

        vm.prank(harvester);
        accumulatedAmount += glpCompounder.harvest(address(harvester), 0);

        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowGLP: E24");
        assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testCorrectFlowGLP: E25");
        assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "testCorrectFlowGLP: E26");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E27");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E28");

        // ---------------- redeem to GLP ----------------

        shares = glpCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeem(shares, address(alice), address(alice));
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(fsGLP).balanceOf(address(alice)), aliceAmountOut, "testCorrectFlowGLP: E29");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "testCorrectFlowGLP: E30");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowGLP: E31");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E32");

        shares = glpCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeem(shares, address(bob), address(bob));
        accumulatedAmount -= bobAmountOut;
        accumulatedShares -= shares;

        assertEq(IERC20(fsGLP).balanceOf(address(bob)), bobAmountOut, "testCorrectFlowGLP: E33");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "testCorrectFlowGLP: E34");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "testCorrectFlowGLP: E35");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E36");

        shares = glpCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeem(shares, address(charlie), address(charlie));
        accumulatedShares -= shares;
        // accumulatedAmount -= charlieAmountOut;

        assertEq(IERC20(fsGLP).balanceOf(address(charlie)), charlieAmountOut, "testCorrectFlowGLP: E37");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "testCorrectFlowGLP: E38");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E39");
        // assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E40");

        assertEq(accumulatedShares, 0, "testCorrectFlowGLP: E41");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "testCorrectFlowGLP: E42");
        assertEq(glpCompounder.totalAssets(), 0, "testCorrectFlowGLP: E43");
        assertEq(glpCompounder.totalSupply(), 0, "testCorrectFlowGLP: E44");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "testCorrectFlowGLP: E45");

        // ---------------- deposit GLP ----------------

        vm.startPrank(address(alice));
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(sGLP).balanceOf(address(alice));
        aliceSharesOut = glpCompounder.deposit(_before, alice);
        accumulatedShares = 0;
        accumulatedAmount = 0;
        accumulatedShares += aliceSharesOut;
        accumulatedAmount += _before;

        assertEq(IERC20(sGLP).balanceOf(address(alice)), 0, "testCorrectFlowGLP: E46");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testCorrectFlowGLP: E47");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E48");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E49");
        assertTrue(accumulatedShares > 0, "testCorrectFlowGLP: E50");
        assertTrue(accumulatedAmount > 0, "testCorrectFlowGLP: E51");
        assertTrue(aliceSharesOut > 0, "testCorrectFlowGLP: E52");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(sGLP).balanceOf(address(bob));
        bobSharesOut = glpCompounder.deposit(_before, bob);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += _before;

        assertEq(IERC20(sGLP).balanceOf(address(bob)), 0, "testCorrectFlowGLP: E53");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testCorrectFlowGLP: E54");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E55");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E56");
        assertTrue(bobSharesOut > 0, "testCorrectFlowGLP: E57");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(charlie));
        charlieSharesOut = glpCompounder.deposit(_before, charlie);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += _before;

        assertEq(IERC20(sGLP).balanceOf(address(charlie)), 0, "testCorrectFlowGLP: E58");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testCorrectFlowGLP: E59");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testCorrectFlowGLP: E60");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testCorrectFlowGLP: E61");
        assertTrue(charlieSharesOut > 0, "testCorrectFlowGLP: E62");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testCorrectFlowGLP: E63");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testCorrectFlowGLP: E64");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e20, "testCorrectFlowGLP: E65");
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test wrong flows ---------------------------------------
    // ------------------------------------------------------------------------------------------

    function testHarvestMoreThanOnce(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ---------------- get assets ----------------

        _wrapETH(alice, _amount);
        assertEq(IERC20(WETH).balanceOf(alice), _amount);

        _wrapETH(bob, _amount);
        assertEq(IERC20(WETH).balanceOf(bob), _amount);

        _wrapETH(charlie, _amount);
        assertEq(IERC20(WETH).balanceOf(charlie), _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testHarvestMoreThanOnce: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testHarvestMoreThanOnce: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testHarvestMoreThanOnce: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testHarvestMoreThanOnce: E4");
        assertTrue(accumulatedShares > 0, "testHarvestMoreThanOnce: E5");
        assertTrue(accumulatedAmount > 0, "testHarvestMoreThanOnce: E6");
        assertTrue(aliceSharesOut > 0, "testHarvestMoreThanOnce: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(bob), bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(bob)), 0, "testHarvestMoreThanOnce: E8");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "testHarvestMoreThanOnce: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testHarvestMoreThanOnce: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testHarvestMoreThanOnce: E11");
        assertTrue(bobSharesOut > 0, "testHarvestMoreThanOnce: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(charlie), charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(charlie)), 0, "testHarvestMoreThanOnce: E13");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "testHarvestMoreThanOnce: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testHarvestMoreThanOnce: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testHarvestMoreThanOnce: E16");
        assertTrue(charlieSharesOut > 0, "testHarvestMoreThanOnce: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "testHarvestMoreThanOnce: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "testHarvestMoreThanOnce: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "testHarvestMoreThanOnce: E19");
        
        // ---------------- harvest ----------------

        assertEq(glpCompounder.isPendingRewards(), false, "testHarvestMoreThanOnce: E20");
        assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "testHarvestMoreThanOnce: E21");
        assertEq(IERC20(fsGLP).balanceOf(platform), 0, "testHarvestMoreThanOnce: E22");

        // Fast forward 1 month
        skip(216000);

        assertEq(glpCompounder.isPendingRewards(), true, "testHarvestMoreThanOnce: E23");

        vm.prank(harvester);
        accumulatedAmount += glpCompounder.harvest(address(harvester), 0);

        assertEq(glpCompounder.isPendingRewards(), false, "testHarvestMoreThanOnce: E24");
        assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "testHarvestMoreThanOnce: E25");
        assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "testHarvestMoreThanOnce: E26");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testHarvestMoreThanOnce: E27");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testHarvestMoreThanOnce: E28");

        vm.expectRevert();
        glpCompounder.harvest(address(harvester), 0);
    }

    function testDepositNoAssets(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        vm.startPrank(alice);
        assertEq(IERC20(FRAX).balanceOf(address(alice)), 0, "testDepositNoAssets: E1");
        IERC20(FRAX).safeApprove(address(glpCompounder), type(uint256).max);
        vm.expectRevert();
        aliceAmountOut = glpCompounder.depositUnderlying(FRAX, _amount, alice, 0);

        assertEq(IERC20(sGLP).balanceOf(address(alice)), 0, "testDepositNoAssets: E2");
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        vm.expectRevert();
        aliceAmountOut = glpCompounder.deposit(amount, address(alice));

        vm.stopPrank();
    }

    function testWithdrawNoShares(uint256 _amount, uint256 _fakeShares) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _wrapETH(alice, _amount);
        assertEq(IERC20(WETH).balanceOf(alice), _amount);

        vm.startPrank(address(alice));
        IERC20(WETH).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(WETH, IERC20(WETH).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(WETH).balanceOf(address(alice)), 0, "testHarvestMoreThanOnce: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "testHarvestMoreThanOnce: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "testHarvestMoreThanOnce: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "testHarvestMoreThanOnce: E4");
        assertTrue(accumulatedShares > 0, "testHarvestMoreThanOnce: E5");
        assertTrue(accumulatedAmount > 0, "testHarvestMoreThanOnce: E6");
        assertTrue(aliceSharesOut > 0, "testHarvestMoreThanOnce: E7");
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert();
        bobAmountOut = glpCompounder.redeemUnderlying(_fakeShares, address(bob), address(bob), 0);

        vm.expectRevert();
        bobAmountOut = glpCompounder.redeemUnderlying(WETH, _fakeShares, address(bob), address(bob), 0);

        vm.expectRevert();
        bobAmountOut = glpCompounder.redeem(_fakeShares, address(bob), address(bob));

        vm.expectRevert();
        bobAmountOut = glpCompounder.withdraw(_amount, address(bob), address(bob));
        
        vm.stopPrank();
    }

    function testHarvestNoRewards(uint256 _amount) public {
        vm.startPrank(alice);
        vm.expectRevert();
        aliceAmountOut = glpCompounder.harvest(address(alice), _amount);
        vm.stopPrank();
    }
}