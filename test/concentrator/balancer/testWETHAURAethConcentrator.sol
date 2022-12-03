// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/interfaces/IConvexBasicRewards.sol";
import "src/compounders/balancer/BalancerCompounder.sol";
import "src/concentrators/balancer/BalancerEthConcentrator.sol";

import "test/concentrator/BaseTest.sol";

import "script/utils/concentrators/balancer/eth/InitWETHAURAEthConcentrator.sol";
import "script/utils/compounders/balancer/InitThreeETH.sol";

contract testWETHAURAethConcentrator is InitWETHAURAEthConcentrator, InitThreeETH, BaseTest {

    using SafeERC20 for IERC20;

    BalancerCompounder ethCompounder;
    BalancerEthConcentrator ethConcentrator;
    
    function setUp() public {
        
        _setUp();

        address tempAddr = _initializeThreeETH(address(fortressRegistry), address(fortressSwap), platform);
        ethCompounder = BalancerCompounder(payable(tempAddr));

        tempAddr = _initWETHAURAEthConcentrator(address(fortressRegistry), address(fortressSwap), platform, address(ethCompounder));
        ethConcentrator = BalancerEthConcentrator(payable(tempAddr));
    }

    // todo - add testWithdraw, testMint


    function testCorrectFlowAURA(uint256 _amount) public {
        // uint256 _amount = 1 ether;
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, AURA, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, AURA, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, AURA, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(AURA, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Withdraw ------------

        _testWithdrawUnderlying(AURA, _sharesAlice, _sharesBob, _sharesCharlie);

        // ------------ Claim ------------

        _testClaim();
    }

    function testCorrectFlowWETH(uint256 _amount) public {
        // uint256 _amount = 1 ether;
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, WETH, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, WETH, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, WETH, _amount);
        
        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(WETH, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Withdraw ------------

        _testWithdrawUnderlying(AURA, _sharesAlice, _sharesBob, _sharesCharlie);

        // ------------ Claim ------------

        _testClaim();
    }

    function testDepositNoAsset(uint256 _amount) public {
        vm.startPrank(alice);
        
        IERC20(AURA).safeApprove(address(ethConcentrator), _amount);
        vm.expectRevert();
        ethConcentrator.depositSingleUnderlying(_amount, AURA, alice, 0);

        vm.stopPrank();
    }

    function testDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, BAL, _amount);
        
        vm.startPrank(alice);
        IERC20(BAL).safeApprove(address(ethConcentrator), _underlyingAlice);
        vm.expectRevert();
        ethConcentrator.depositSingleUnderlying(_underlyingAlice, BAL, alice, 0);

        vm.stopPrank();
    }

    function testWrongWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, AURA, _amount);
        
        vm.startPrank(alice);
        IERC20(AURA).safeApprove(address(ethConcentrator), _underlyingAlice);
        uint256 _share = ethConcentrator.depositSingleUnderlying(_underlyingAlice, AURA, alice, 0);
        vm.stopPrank();
        assertEq(_share, IERC20(address(ethConcentrator)).balanceOf(alice), "testWithdrawNotOwner: E1");

        vm.startPrank(bob);
        vm.expectRevert();
        ethConcentrator.redeem(_share, bob, alice);
        vm.expectRevert();
        ethConcentrator.redeem(_share, bob, bob);
        vm.expectRevert();
        ethConcentrator.redeemSingleUnderlying(_share, AURA, bob, alice, 0);
        vm.expectRevert();
        ethConcentrator.redeemSingleUnderlying(_share, AURA, bob, bob, 0);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- internal functions -------------------------------------
    // ------------------------------------------------------------------------------------------

    function _depositSingleUnderlyingAsset(address _owner, address _asset, uint256 _amount) internal returns (uint256 _share) {
        vm.startPrank(_owner);
        if (_asset != ETH) {
            IERC20(_asset).safeApprove(address(ethConcentrator), _amount);
            _share = ethConcentrator.depositSingleUnderlying(_amount, _asset, _owner, 0);
        } else {
            _share = ethConcentrator.depositSingleUnderlying{value: _amount}(_amount, _asset, _owner, 0);
        }
        vm.stopPrank();

        assertEq(_share, ethConcentrator.balanceOf(_owner), "_depositSingleUnderlyingAsset: E1");
    }

    function _testDepositUnderlying(address _asset, uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        _sharesAlice = _depositSingleUnderlyingAsset(alice, _asset, _underlyingAlice);
        _sharesBob = _depositSingleUnderlyingAsset(bob, _asset, _underlyingBob);
        _sharesCharlie = _depositSingleUnderlyingAsset(charlie, _asset, _underlyingCharlie);
        
        assertEq(ethConcentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositUnderlying: E1");
        assertEq(ethConcentrator.totalAssets(), IConvexBasicRewards(ethConcentrator.crvRewards()).balanceOf(address(ethConcentrator)), "_testDepositUnderlying: E2");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e19, "_testDepositUnderlying: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e19, "_testDepositUnderlying: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testHarvest(uint256 _totalShare) internal {
        assertTrue(IConvexBasicRewards(ethConcentrator.crvRewards()).earned(address(ethConcentrator)) == 0, "_testHarvest: E1");
        assertEq(ethConcentrator.pendingReward(address(alice)), 0, "_testHarvest: E01");
        assertEq(ethConcentrator.pendingReward(address(alice)) , ethConcentrator.pendingReward(address(bob)), "_testHarvest: E02");
        assertEq(ethConcentrator.pendingReward(address(alice)) , ethConcentrator.pendingReward(address(charlie)), "_testHarvest: E03");
        assertEq(ethConcentrator.accRewardPerShare(), 0, "_testHarvest: E04");
        
        // Fast forward 1 month
        skip(216000);

        assertTrue(IConvexBasicRewards(ethConcentrator.crvRewards()).earned(address(ethConcentrator)) > 0, "_testHarvest: E2");
        
        uint256 _underlyingBefore = ethConcentrator.totalAssets();
        uint256 _rewardsBefore = IERC20(address(ethCompounder)).balanceOf(address(ethConcentrator));
        vm.prank(harvester);
        uint256 _newUnderlying = ethConcentrator.harvest(address(harvester), 0);

        assertTrue(IConvexBasicRewards(ethConcentrator.crvRewards()).earned(address(ethConcentrator)) == 0, "_testHarvest: E3");
        assertTrue(IERC20(BALANCER_3ETH).balanceOf(platform) > 0, "_testHarvest: E4");
        assertTrue(IERC20(BALANCER_3ETH).balanceOf(harvester) > 0, "_testHarvest: E5");
        assertEq(ethConcentrator.totalAssets(), _underlyingBefore, "_testHarvest: E6");
        assertEq(ethConcentrator.totalSupply(), _totalShare, "_testHarvest: E7");
        assertEq((IERC20(address(ethCompounder)).balanceOf(address(ethConcentrator)) - _rewardsBefore), _newUnderlying, "_testHarvest: E8");
        assertTrue(_newUnderlying > 0, "_testHarvest: E9");
        assertTrue(ethConcentrator.accRewardPerShare() > 0, "_testHarvest: E10");
        assertTrue(ethConcentrator.pendingReward(address(alice)) > 0, "_testHarvest: E11");
        assertApproxEqAbs(ethConcentrator.pendingReward(address(alice)) , ethConcentrator.pendingReward(address(bob)), 1e17, "_testHarvest: E12");
        assertApproxEqAbs(ethConcentrator.pendingReward(address(alice)) , ethConcentrator.pendingReward(address(charlie)), 1e17, "_testHarvest: E13");
    }

    function _testWithdrawUnderlying(address _asset, uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        vm.prank(alice);
        uint256 _tokenOutAlice = ethConcentrator.redeemSingleUnderlying(_sharesAlice, _asset, address(alice), address(alice), 0);
        assertEq(_tokenOutAlice, IERC20(_asset).balanceOf(address(alice)), "_testWithdrawUnderlying: E1");
        assertEq(ethConcentrator.balanceOf(address(alice)), 0, "_testWithdrawUnderlying: E2");
        
        vm.prank(bob);
        uint256 _tokenOutBob = ethConcentrator.redeemSingleUnderlying(_sharesBob, _asset, address(bob), address(bob), 0);
        assertEq(_tokenOutBob, IERC20(_asset).balanceOf(address(bob)), "_testWithdrawUnderlying: E3");
        assertEq(ethConcentrator.balanceOf(address(bob)), 0, "_testWithdrawUnderlying: E4");

        vm.prank(charlie);
        uint256 _tokenOutCharlie = ethConcentrator.redeemSingleUnderlying(_sharesCharlie, _asset, address(charlie), address(charlie), 0);
        assertEq(_tokenOutCharlie, IERC20(_asset).balanceOf(address(charlie)), "_testWithdrawUnderlying: E5");
        assertEq(ethConcentrator.balanceOf(address(charlie)), 0, "_testWithdrawUnderlying: E6");

        assertEq(ethConcentrator.totalAssets(), 0, "_testWithdrawUnderlying: E7");
        assertEq(ethConcentrator.totalSupply(), 0, "_testWithdrawUnderlying: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e20, "_testWithdrawUnderlying: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e20, "_testWithdrawUnderlying: E10");
    }

    function _testClaim() internal {
        vm.prank(alice);
        uint256 _rewardsOutAlice = ethConcentrator.claim(address(alice));
        assertTrue(_rewardsOutAlice > 0, "_testClaim: E01");
        assertEq(_rewardsOutAlice, IERC20(address(ethCompounder)).balanceOf(address(alice)), "_testClaim: E1");
        assertEq(ethConcentrator.pendingReward(address(alice)), 0, "_testClaim: E2");

        vm.prank(bob);
        uint256 _rewardsOutBob = ethConcentrator.claim(address(bob));
        assertTrue(_rewardsOutBob > 0, "_testClaim: E02");
        assertEq(_rewardsOutBob, IERC20(address(ethCompounder)).balanceOf(address(bob)), "_testClaim: E3");
        assertEq(ethConcentrator.pendingReward(address(bob)), 0, "_testClaim: E4");

        vm.prank(charlie);
        uint256 _rewardsOutCharlie = ethConcentrator.claim(address(charlie));
        assertTrue(_rewardsOutCharlie > 0, "_testClaim: E03");
        assertEq(_rewardsOutCharlie, IERC20(address(ethCompounder)).balanceOf(address(charlie)), "_testClaim: E5");
        assertEq(ethConcentrator.pendingReward(address(charlie)), 0, "_testClaim: E6");

        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutBob, 1e19, "_testClaim: E7");
        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutCharlie, 1e19, "_testClaim: E8");
    } 
}