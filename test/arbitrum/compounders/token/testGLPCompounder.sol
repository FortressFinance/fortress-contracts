// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";

import "test/arbitrum/compounders/token/BaseTest.sol";

contract testGlpCompounder is BaseTest, InitGlpCompounder {
    
    using SafeERC20 for IERC20;

    GlpCompounder glpCompounder;

    // *********************** Public Functions ***********************

    // *********************** Correct Flows ***********************

    function setUp() public {
        
        _setUp();

        vm.startPrank(owner);
        address _compounder = _initializeGlpCompounder(address(owner), address(platform), address(fortressRegistry), address(fortressSwap));
        vm.stopPrank();

        glpCompounder = GlpCompounder(_compounder);
    }

    function testWhitelistRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, WETH);

        _harvest(_accumulatedAmount, _accumulatedShares);

        _whitelistedRedeem(_accumulatedShares);
    }

    function testCorrectFlowGLP(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // TODO - depositing sGLP via `deposit` seems to not accrue ETH rewards, GMX dev team is looking into it https://discord.com/channels/837652500948713502/837652500948713506/1079720289736339466
        // (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _deposit(_amount);
        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, WETH);

        _harvest(_accumulatedAmount, _accumulatedShares);

        redeemNonEthUnderlying(_accumulatedShares);
    }

    function testCorrectFlowWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, WETH);

        _harvest(_accumulatedAmount, _accumulatedShares);

        redeemNonEthUnderlying(_accumulatedShares);
    }

    function testCorrectFlowRedeemETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, WETH);

        _harvest(_accumulatedAmount, _accumulatedShares);

        redeemEthUnderlying(_accumulatedShares);
    }

    // function testCorrectFlowUSDC(uint256 _amount) public {
    //     vm.assume(_amount > 0.01 ether && _amount < 1 ether);
        
    //     (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, USDC);

    //     _harvest(_accumulatedAmount, _accumulatedShares);

    //     redeemNonEthUnderlying(_accumulatedShares);
    // }

    // function testCorrectFlowUSDT(uint256 _amount) public {
    //     vm.assume(_amount > 0.01 ether && _amount < 1 ether);

    //     (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, USDT);

    //     _harvest(_accumulatedAmount, _accumulatedShares);

    //     redeemNonEthUnderlying(_accumulatedShares);
    // }

    function testCorrectFlowFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, FRAX);

        _harvest(_accumulatedAmount, _accumulatedShares);

        redeemNonEthUnderlying(_accumulatedShares);
    }

    function testCorrectFlowETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositEthUnderlying(_amount);

        _harvest(_accumulatedAmount, _accumulatedShares);

        redeemNonEthUnderlying(_accumulatedShares);
    }

    function testCorrectFlowHarvestUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, WETH);

        _harvestUnderlying(USDC, _accumulatedAmount, _accumulatedShares);

        redeemNonEthUnderlying(_accumulatedShares);
    }

    function testMaxDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _capDeposit(_amount);
    }

    // *********************** Wrong Flows ***********************

    function testHarvestMoreThanOnce(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        (uint256 _accumulatedAmount, uint256 _accumulatedShares) = _depositNonEthUnderlying(_amount, FRAX);

        _harvest(_accumulatedAmount, _accumulatedShares);

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
        bobAmountOut = glpCompounder.redeemUnderlying(WETH, _fakeShares, address(bob), address(bob), 0);

        vm.expectRevert();
        bobAmountOut = glpCompounder.redeem(_fakeShares, address(bob), address(bob));

        vm.expectRevert();
        bobAmountOut = glpCompounder.withdraw(_amount, address(bob), address(bob));
        
        vm.stopPrank();
    }

    function testHarvestNoRewards(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _depositNonEthUnderlying(_amount, FRAX);

        vm.expectRevert();
        glpCompounder.harvest(address(harvester), 0);
    }

    function testDepositEthWrongAmount(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        vm.deal(alice, _amount);

        vm.startPrank(alice);

        vm.expectRevert();
        glpCompounder.depositUnderlying{value: _amount}(ETH, _amount - 1, alice, 0);

        vm.expectRevert();
        glpCompounder.depositUnderlying{value: _amount - 1}(ETH, _amount, alice, 0);
        
        vm.stopPrank();
    }

    function testDepositEthWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        vm.deal(alice, _amount);

        vm.startPrank(alice);

        vm.expectRevert();
        glpCompounder.depositUnderlying{value: _amount}(WETH, _amount, alice, 0);

        vm.expectRevert();
        glpCompounder.depositUnderlying{value: _amount}(FRAX, _amount, alice, 0);
        
        vm.stopPrank();
    }

    // *********************** Internal Functions ***********************

    function _deposit(uint256 _amount) internal returns (uint256, uint256) {

        (uint256 accumulatedAmount, uint256 accumulatedShares) = _depositNonEthUnderlying(_amount, WETH);

        // ---------------- redeem to GLP ----------------

        uint256 shares = glpCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeem(shares, address(alice), address(alice));
        accumulatedAmount -= glpCompounder.convertToAssets(shares);
        accumulatedShares -= shares;

        assertEq(IERC20(fsGLP).balanceOf(address(alice)), aliceAmountOut, "_deposit: E29");
        assertEq(glpCompounder.balanceOf(address(alice)), 0, "_deposit: E30");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "_deposit: E31");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_deposit: E32");

        shares = glpCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeem(shares, address(bob), address(bob));
        accumulatedAmount -= bobAmountOut;
        accumulatedShares -= shares;

        assertEq(IERC20(fsGLP).balanceOf(address(bob)), bobAmountOut, "_deposit: E33");
        assertEq(glpCompounder.balanceOf(address(bob)), 0, "_deposit: E34");
        assertApproxEqAbs(glpCompounder.totalAssets(), accumulatedAmount, 1e20, "_deposit: E35");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_deposit: E36");

        shares = glpCompounder.balanceOf(address(charlie));
        vm.prank(charlie);
        charlieAmountOut = glpCompounder.redeem(shares, address(charlie), address(charlie));
        accumulatedShares -= shares;
        // accumulatedAmount -= charlieAmountOut;

        assertEq(IERC20(fsGLP).balanceOf(address(charlie)), charlieAmountOut, "_deposit: E37");
        assertEq(glpCompounder.balanceOf(address(charlie)), 0, "_deposit: E38");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_deposit: E39");
        // assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_deposit: E40");

        assertEq(accumulatedShares, 0, "_deposit: E41");
        assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "_deposit: E42");
        assertEq(glpCompounder.totalAssets(), 0, "_deposit: E43");
        assertEq(glpCompounder.totalSupply(), 0, "_deposit: E44");
        
        // Fast forward 1 month
        skip(216000);
        assertEq(glpCompounder.isPendingRewards(), false, "_deposit: E45");

        // ---------------- deposit GLP ----------------

        vm.startPrank(address(alice));
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        uint256 _before = IERC20(fsGLP).balanceOf(address(alice));
        uint256 aliceSharesOut = glpCompounder.deposit(_before, alice);

        require (IERC20(sGLP).balanceOf(address(glpCompounder)) == _before, "testE46");
        require (IERC20(fsGLP).balanceOf(address(glpCompounder)) == _before, "testE47");
        accumulatedShares = 0;
        accumulatedAmount = 0;
        accumulatedShares += aliceSharesOut;
        accumulatedAmount += _before;

        assertEq(IERC20(sGLP).balanceOf(address(alice)), 0, "_deposit: E46");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "_deposit: E47");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_deposit: E48");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_deposit: E49");
        assertTrue(accumulatedShares > 0, "_deposit: E50");
        assertTrue(accumulatedAmount > 0, "_deposit: E51");
        assertTrue(aliceSharesOut > 0, "_deposit: E52");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(sGLP).balanceOf(address(bob));
        uint256 bobSharesOut = glpCompounder.deposit(_before, bob);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += _before;

        assertEq(IERC20(sGLP).balanceOf(address(bob)), 0, "_deposit: E53");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "_deposit: E54");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_deposit: E55");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_deposit: E56");
        assertTrue(bobSharesOut > 0, "_deposit: E57");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(sGLP).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(charlie));
        uint256 charlieSharesOut = glpCompounder.deposit(_before, charlie);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += _before;

        assertEq(IERC20(sGLP).balanceOf(address(charlie)), 0, "_deposit: E58");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "_deposit: E59");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_deposit: E60");
        assertEq(glpCompounder.totalAssets(), IERC20(sGLP).balanceOf(address(charlie)), "_deposit: E060");
        assertEq(glpCompounder.totalAssets(), IERC20(fsGLP).balanceOf(address(charlie)), "_deposit: E0060");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_deposit: E61");
        assertTrue(charlieSharesOut > 0, "_deposit: E62");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "_deposit: E63");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "_deposit: E64");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e20, "_deposit: E65");

        return (accumulatedAmount, accumulatedShares);
    }

    function _depositEthUnderlying(uint256 _amount) internal returns (uint256, uint256) {

        // ---------------- get assets ----------------

        vm.deal(owner, _amount);
        vm.deal(alice, _amount);
        vm.deal(bob, _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying{value: _amount}(ETH, _amount, alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "_depositNonEthUnderlying: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_depositNonEthUnderlying: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_depositNonEthUnderlying: E4");
        assertTrue(accumulatedShares > 0, "_depositNonEthUnderlying: E5");
        assertTrue(accumulatedAmount > 0, "_depositNonEthUnderlying: E6");
        assertTrue(aliceSharesOut > 0, "_depositNonEthUnderlying: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying{value: _amount}(ETH, _amount, bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "_depositNonEthUnderlying: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_depositNonEthUnderlying: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_depositNonEthUnderlying: E11");
        assertTrue(bobSharesOut > 0, "_depositNonEthUnderlying: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying{value: _amount}(ETH, _amount, charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "_depositNonEthUnderlying: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_depositNonEthUnderlying: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_depositNonEthUnderlying: E16");
        assertTrue(charlieSharesOut > 0, "_depositNonEthUnderlying: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "_depositNonEthUnderlying: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "_depositNonEthUnderlying: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "_depositNonEthUnderlying: E19");

        return (accumulatedAmount, accumulatedShares);
    }

    function _depositNonEthUnderlying(uint256 _amount, address _underlyingAsset) internal returns (uint256, uint256) {

        // ---------------- get assets ----------------

        _dealERC20(_underlyingAsset, address(alice), _amount);

        _dealERC20(_underlyingAsset, address(bob), _amount);

        _dealERC20(_underlyingAsset, address(charlie), _amount);

        // ---------------- deposit ----------------

        vm.startPrank(address(alice));
        IERC20(_underlyingAsset).safeApprove(address(glpCompounder), type(uint256).max); 
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 aliceSharesOut = glpCompounder.depositUnderlying(_underlyingAsset, IERC20(_underlyingAsset).balanceOf(alice), alice, 0);
        uint256 accumulatedShares = aliceSharesOut;
        uint256 accumulatedAmount = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(_underlyingAsset).balanceOf(address(alice)), 0, "_depositNonEthUnderlying: E1");
        assertEq(glpCompounder.balanceOf(address(alice)), aliceSharesOut, "_depositNonEthUnderlying: E2");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_depositNonEthUnderlying: E3");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_depositNonEthUnderlying: E4");
        assertTrue(accumulatedShares > 0, "_depositNonEthUnderlying: E5");
        assertTrue(accumulatedAmount > 0, "_depositNonEthUnderlying: E6");
        assertTrue(aliceSharesOut > 0, "_depositNonEthUnderlying: E7");
        vm.stopPrank();

        vm.startPrank(address(bob));
        IERC20(_underlyingAsset).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 bobSharesOut = glpCompounder.depositUnderlying(_underlyingAsset, IERC20(_underlyingAsset).balanceOf(bob), bob, 0);
        accumulatedShares += bobSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(_underlyingAsset).balanceOf(address(bob)), 0, "_depositNonEthUnderlying: E8");
        assertEq(glpCompounder.balanceOf(address(bob)), bobSharesOut, "_depositNonEthUnderlying: E9");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_depositNonEthUnderlying: E10");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_depositNonEthUnderlying: E11");
        assertTrue(bobSharesOut > 0, "_depositNonEthUnderlying: E12");
        vm.stopPrank();

        vm.startPrank(address(charlie));
        IERC20(_underlyingAsset).safeApprove(address(glpCompounder), type(uint256).max);
        _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 charlieSharesOut = glpCompounder.depositUnderlying(_underlyingAsset, IERC20(_underlyingAsset).balanceOf(charlie), charlie, 0);
        accumulatedShares += charlieSharesOut;
        accumulatedAmount += IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;

        assertEq(IERC20(_underlyingAsset).balanceOf(address(charlie)), 0, "_depositNonEthUnderlying: E13");
        assertEq(glpCompounder.balanceOf(address(charlie)), charlieSharesOut, "_depositNonEthUnderlying: E14");
        assertEq(glpCompounder.totalAssets(), accumulatedAmount, "_depositNonEthUnderlying: E15");
        assertEq(glpCompounder.totalSupply(), accumulatedShares, "_depositNonEthUnderlying: E16");
        assertTrue(charlieSharesOut > 0, "_depositNonEthUnderlying: E17");
        vm.stopPrank();

        assertEq((aliceSharesOut + bobSharesOut + charlieSharesOut), accumulatedShares, "_depositNonEthUnderlying: E18");
        assertApproxEqAbs(aliceSharesOut, bobSharesOut, 1e19, "_depositNonEthUnderlying: E19");
        assertApproxEqAbs(aliceSharesOut, charlieSharesOut, 1e19, "_depositNonEthUnderlying: E19");

        return (accumulatedAmount, accumulatedShares);
    }

    function _harvest(uint256 _accumulatedAmount, uint256 _accumulatedShares) internal {
            
            // ---------------- harvest ----------------

            assertEq(glpCompounder.isPendingRewards(), false, "_harvest: E20");
            assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "_harvest: E21");
            assertEq(IERC20(fsGLP).balanceOf(platform), 0, "_harvest: E22");

            // Fast forward 1 month
            skip(216000);

            assertEq(glpCompounder.isPendingRewards(), true, "_harvest: E23");

            vm.prank(harvester);
            uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
            uint256 _harvestRewards = glpCompounder.harvest(address(harvester), 0);
            uint256 accumulatedAmountDelta = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;
            _accumulatedAmount += accumulatedAmountDelta;

            assertEq(glpCompounder.isPendingRewards(), false, "_harvest: E24");
            assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "_harvest: E25");
            assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "_harvest: E26");
            assertEq(glpCompounder.totalAssets(), _accumulatedAmount, "_harvest: E27");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_harvest: E28");
            assertEq(_harvestRewards, accumulatedAmountDelta, "_harvest: E028");
    }

    function _harvestUnderlying(address _underlyingAsset, uint256 _accumulatedAmount, uint256 _accumulatedShares) internal {
        
        // ---------------- harvest ----------------

        assertEq(glpCompounder.isPendingRewards(), false, "_harvestUnderlying: E20");
        assertEq(IERC20(fsGLP).balanceOf(harvester), 0, "_harvestUnderlying: E21");
        assertEq(IERC20(fsGLP).balanceOf(platform), 0, "_harvestUnderlying: E22");
        assertTrue(IERC20(fsGLP).balanceOf(address(glpCompounder)) > 0, "_harvestUnderlying: E23420");
        
        // Fast forward 1 month
        skip(216000);

        assertEq(glpCompounder.isPendingRewards(), true, "_harvestUnderlying: E23");

        vm.prank(harvester);
        uint256 _before = IERC20(fsGLP).balanceOf(address(glpCompounder));
        uint256 _harvestRewards = glpCompounder.harvest(address(harvester), _underlyingAsset, 0);
        uint256 accumulatedAmountDelta = IERC20(fsGLP).balanceOf(address(glpCompounder)) - _before;
        _accumulatedAmount += accumulatedAmountDelta;

        assertEq(glpCompounder.isPendingRewards(), false, "_harvestUnderlying: E24");
        assertTrue(IERC20(fsGLP).balanceOf(harvester) > 0, "_harvestUnderlying: E25");
        assertTrue(IERC20(fsGLP).balanceOf(platform) > 0, "_harvestUnderlying: E26");
        assertEq(glpCompounder.totalAssets(), _accumulatedAmount, "_harvestUnderlying: E27");
        assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_harvestUnderlying: E28");
        assertEq(_harvestRewards, accumulatedAmountDelta, "_harvestUnderlying: E028");
    }

    function redeemNonEthUnderlying(uint256 _accumulatedShares) internal {

            // ---------------- redeem ---------------

            shares = glpCompounder.balanceOf(address(alice));
            vm.prank(alice);
            aliceAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(alice), address(alice), 0);
            _accumulatedShares -= shares;

            assertEq(IERC20(WETH).balanceOf(address(alice)), aliceAmountOut, "_depositNonEthUnderlying: E29");
            assertEq(glpCompounder.balanceOf(address(alice)), 0, "_depositNonEthUnderlying: E30");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_depositNonEthUnderlying: E32");

            shares = glpCompounder.balanceOf(address(bob));
            vm.prank(bob);
            bobAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(bob), address(bob), 0);
            _accumulatedShares -= shares;

            assertEq(IERC20(WETH).balanceOf(address(bob)), bobAmountOut, "_depositNonEthUnderlying: E33");
            assertEq(glpCompounder.balanceOf(address(bob)), 0, "_depositNonEthUnderlying: E34");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_depositNonEthUnderlying: E36");

            shares = glpCompounder.balanceOf(address(charlie));
            vm.prank(charlie);
            charlieAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(charlie), address(charlie), 0);
            _accumulatedShares -= shares;

            assertEq(IERC20(WETH).balanceOf(address(charlie)), charlieAmountOut, "_depositNonEthUnderlying: E37");
            assertEq(glpCompounder.balanceOf(address(charlie)), 0, "_depositNonEthUnderlying: E38");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_depositNonEthUnderlying: E40");

            assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "_depositNonEthUnderlying: E43");
            assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "_depositNonEthUnderlying: E043");
            assertEq(glpCompounder.totalAssets(), 0, "_depositNonEthUnderlying: E44");
            assertEq(glpCompounder.totalSupply(), 0, "_depositNonEthUnderlying: E45");
            
            // Fast forward 1 month
            skip(216000);
            assertEq(glpCompounder.isPendingRewards(), false, "_depositNonEthUnderlying: E46");
    }

    function redeemEthUnderlying(uint256 _accumulatedShares) internal {

            // ---------------- redeem ---------------

            shares = glpCompounder.balanceOf(address(alice));
            vm.prank(alice);
            uint256 _balanceBefore = address(alice).balance;
            aliceAmountOut = glpCompounder.redeemUnderlying(ETH, shares, address(alice), address(alice), 0);
            uint256 _realAmountOut = address(alice).balance - _balanceBefore;
            _accumulatedShares -= shares;

            assertEq(_realAmountOut, aliceAmountOut, "_depositNonEthUnderlying: E29");
            assertEq(glpCompounder.balanceOf(address(alice)), 0, "_depositNonEthUnderlying: E30");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_depositNonEthUnderlying: E32");

            shares = glpCompounder.balanceOf(address(bob));
            vm.prank(bob);
            _balanceBefore = address(bob).balance;
            bobAmountOut = glpCompounder.redeemUnderlying(ETH, shares, address(bob), address(bob), 0);
            _realAmountOut = address(bob).balance - _balanceBefore;
            _accumulatedShares -= shares;

            assertEq(_realAmountOut, bobAmountOut, "_depositNonEthUnderlying: E33");
            assertEq(glpCompounder.balanceOf(address(bob)), 0, "_depositNonEthUnderlying: E34");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_depositNonEthUnderlying: E36");

            shares = glpCompounder.balanceOf(address(charlie));
            vm.prank(charlie);
            _balanceBefore = address(charlie).balance;
            charlieAmountOut = glpCompounder.redeemUnderlying(ETH, shares, address(charlie), address(charlie), 0);
            _realAmountOut = address(charlie).balance - _balanceBefore;
            _accumulatedShares -= shares;

            assertEq(_realAmountOut, charlieAmountOut, "_depositNonEthUnderlying: E37");
            assertEq(glpCompounder.balanceOf(address(charlie)), 0, "_depositNonEthUnderlying: E38");
            assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_depositNonEthUnderlying: E40");

            assertApproxEqAbs(aliceAmountOut, bobAmountOut, 1e19, "_depositNonEthUnderlying: E43");
            assertApproxEqAbs(aliceAmountOut, charlieAmountOut, 1e19, "_depositNonEthUnderlying: E043");
            assertEq(glpCompounder.totalAssets(), 0, "_depositNonEthUnderlying: E44");
            assertEq(glpCompounder.totalSupply(), 0, "_depositNonEthUnderlying: E45");
            
            // Fast forward 1 month
            skip(216000);
            assertEq(glpCompounder.isPendingRewards(), false, "_depositNonEthUnderlying: E46");
    }

    function _whitelistedRedeem(uint256 _accumulatedShares) internal {
        
        vm.startPrank(owner);
        glpCompounder.updateFeelessRedeemerWhitelist(address(alice), true);
        vm.stopPrank();

        assertEq(glpCompounder.balanceOf(address(alice)), glpCompounder.balanceOf(address(bob)), "_whitelistedRedeem: E1");

        shares = glpCompounder.balanceOf(address(alice)) / 2;
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(alice), address(alice), 0);
        _accumulatedShares -= shares;

        assertEq(IERC20(WETH).balanceOf(address(alice)), aliceAmountOut, "_whitelistedRedeem: E2");
        assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_whitelistedRedeem: E3");

        shares = glpCompounder.balanceOf(address(bob)) / 2;
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeemUnderlying(WETH, shares, address(bob), address(bob), 0);
        _accumulatedShares -= shares;

        assertEq(IERC20(WETH).balanceOf(address(bob)), bobAmountOut, "_whitelistedRedeem: E4");
        assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_whitelistedRedeem: E5");

        assertTrue(aliceAmountOut > bobAmountOut, "_whitelistedRedeem: E6");

        // ---

        shares = glpCompounder.balanceOf(address(alice));
        vm.prank(alice);
        aliceAmountOut = glpCompounder.redeem(shares, address(alice), address(alice));
        _accumulatedShares -= shares;

        assertEq(IERC20(sGLP).balanceOf(address(alice)), aliceAmountOut, "_whitelistedRedeem: E7");
        assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_whitelistedRedeem: E8");

        shares = glpCompounder.balanceOf(address(bob));
        vm.prank(bob);
        bobAmountOut = glpCompounder.redeem(shares, address(bob), address(bob));
        _accumulatedShares -= shares;

        assertEq(IERC20(sGLP).balanceOf(address(bob)), bobAmountOut, "_whitelistedRedeem: E9");
        assertEq(glpCompounder.totalSupply(), _accumulatedShares, "_whitelistedRedeem: E10");

        assertTrue(aliceAmountOut > bobAmountOut, "_whitelistedRedeem: E11");
    }

    function _capDeposit(uint256 _amount) internal {
        vm.startPrank(owner);
        glpCompounder.updateInternalUtils(address(platform), address(fortressSwap), address(owner), _amount, glpCompounder.getUnderlyingAssets());
        vm.stopPrank();

        assertEq(glpCompounder.maxMint(address(0)), _amount, "_capDeposit: E0");
        assertEq(glpCompounder.maxDeposit(address(0)), glpCompounder.convertToAssets(_amount), "_capDeposit: E1");

        uint256 _maxMintPerUser = glpCompounder.maxMint(address(0)) / 3;

        uint256 _requiredAssets = glpCompounder.previewMint(_maxMintPerUser);
        
        assertApproxEqAbs(_requiredAssets * 3, glpCompounder.maxDeposit(address(0)), 1e15, "_capDeposit: E2");
    }
}