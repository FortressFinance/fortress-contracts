// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/BaseTest.sol";
import "src/shared/concentrators/AMMConcentratorBase.sol";
import "src/arbitrum/concentrators/curve/CurveGlpConcentrator.sol";

import "src/shared/interfaces/ERC4626.sol";
import "src/arbitrum/fortress-interfaces/IGlpCompounder.sol";

contract BaseCurveGlpConcentratorTest is BaseTest {

    using SafeERC20 for IERC20;

    // -------------------------------------------------------------------------
    // --------------------------------- TESTS ---------------------------------
    // -------------------------------------------------------------------------
    
    function _testCorrectFlow(address _asset, uint256 _amount, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator);

        // ------------ Withdraw ------------
        
        _testRedeemUnderlying(_asset, _sharesAlice, _sharesBob, _sharesCharlie, _concentrator);

        // ------------ Claim ------------

        _testClaim(_concentrator);
    }

    // function testDepositNoAsset(uint256 _amount) public {
    //     vm.startPrank(alice);
        
    //     IERC20(wBTC).safeApprove(address(ethConcentrator), _amount);
    //     vm.expectRevert();
    //     ethConcentrator.depositSingleUnderlying(_amount, wBTC, alice, 0);

    //     vm.stopPrank();
    // }

    // function testDepositWrongAsset(uint256 _amount) public {
    //     vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
    //     uint256 _underlyingAlice = _getAssetFromETH(alice, BAL, _amount);
        
    //     vm.startPrank(alice);
    //     IERC20(BAL).safeApprove(address(ethConcentrator), _underlyingAlice);
    //     vm.expectRevert();
    //     ethConcentrator.depositSingleUnderlying(_underlyingAlice, BAL, alice, 0);

    //     vm.stopPrank();
    // }

    // function testWrongWithdraw(uint256 _amount) public {
    //     vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
    //     uint256 _underlyingAlice = _getAssetFromETH(alice, USDT, _amount);
        
    //     vm.startPrank(alice);
    //     IERC20(USDT).safeApprove(address(ethConcentrator), _underlyingAlice);
    //     uint256 _share = ethConcentrator.depositSingleUnderlying(_underlyingAlice, USDT, alice, 0);
    //     vm.stopPrank();
    //     assertEq(_share, IERC20(address(ethConcentrator)).balanceOf(alice), "testWithdrawNotOwner: E1");

    //     vm.startPrank(bob);
    //     vm.expectRevert();
    //     ethConcentrator.redeem(_share, bob, alice);
    //     vm.expectRevert();
    //     ethConcentrator.redeem(_share, bob, bob);
    //     vm.expectRevert();
    //     ethConcentrator.redeemSingleUnderlying(_share, USDT, bob, alice, 0);
    //     vm.expectRevert();
    //     ethConcentrator.redeemSingleUnderlying(_share, USDT, bob, bob, 0);
    //     vm.stopPrank();
    // }

    // todo - test transfers...

    // ------------------------------------------------------------------------------------------
    // --------------------------------- internal tests -----------------------------------------
    // ------------------------------------------------------------------------------------------

    function _testDepositUnderlying(address _asset, uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie, address _concentrator) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);

        _sharesAlice = _depositSingleUnderlyingAsset(alice, _asset, _underlyingAlice, _concentrator);
        _sharesBob = _depositSingleUnderlyingAsset(bob, _asset, _underlyingBob, _concentrator);
        _sharesCharlie = _depositSingleUnderlyingAsset(charlie, _asset, _underlyingCharlie, _concentrator);
        
        assertEq(_localConcentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositUnderlying: E1");
        assertEq(_localConcentrator.totalAssets(), IConvexBasicRewards(AMMConcentratorBase(_concentrator).crvRewards()).balanceOf(address(_concentrator)), "_testDepositUnderlying: E2");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e19, "_testDepositUnderlying: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e19, "_testDepositUnderlying: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testRedeemUnderlying(address _asset, uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie, address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);

        assertEq(_localConcentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testRedeemUnderlying: E01");

        vm.prank(alice);
        uint256 _tokenOutAlice = _localConcentrator.redeemSingleUnderlying(_sharesAlice, _asset, address(alice), address(alice), 0);
        
        assertEq(_tokenOutAlice, IERC20(_asset).balanceOf(address(alice)), "_testWithdrawUnderlying: E1");
        assertEq(_localConcentrator.balanceOf(address(alice)), 0, "_testWithdrawUnderlying: E2");
        assertEq(_localConcentrator.totalSupply(), (_sharesBob + _sharesCharlie), "_testRedeemUnderlying: E02");
        
        vm.prank(bob);
        uint256 _tokenOutBob = _localConcentrator.redeemSingleUnderlying(_sharesBob, _asset, address(bob), address(bob), 0);
        
        assertEq(_tokenOutBob, IERC20(_asset).balanceOf(address(bob)), "_testWithdrawUnderlying: E3");
        assertEq(_localConcentrator.balanceOf(address(bob)), 0, "_testWithdrawUnderlying: E4");
        assertEq(_localConcentrator.totalSupply(), _sharesCharlie, "_testRedeemUnderlying: E04");

        vm.prank(charlie);
        uint256 _tokenOutCharlie = _localConcentrator.redeemSingleUnderlying(_sharesCharlie, _asset, address(charlie), address(charlie), 0);
        
        assertEq(_tokenOutCharlie, IERC20(_asset).balanceOf(address(charlie)), "_testWithdrawUnderlying: E5");
        assertEq(_localConcentrator.balanceOf(address(charlie)), 0, "_testWithdrawUnderlying: E6");

        assertEq(_localConcentrator.totalAssets(), 0, "_testWithdrawUnderlying: E7");
        assertEq(_localConcentrator.totalSupply(), 0, "_testWithdrawUnderlying: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e20, "_testWithdrawUnderlying: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e20, "_testWithdrawUnderlying: E10");
    }

    function _testClaim(address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        address _compounder = _localConcentrator.compounder();
        // assertTrue(_localConcentrator.balanceOf(address(alice)) > 0, "_testClaim: E001");
        // assertTrue(_localConcentrator.balanceOf(address(bob)) > 0, "_testClaim: E002");
        // assertTrue(_localConcentrator.balanceOf(address(charlie)) > 0, "_testClaim: E003");
        // assertTrue(_localConcentrator.totalAssets() > 0, "_testClaim: E0003");
        // assertTrue(IConvexBasicRewards(_localConcentrator.crvRewards()).balanceOf(_concentrator) > 0, "_testClaim: E00003");
        assertEq(IERC20(_compounder).balanceOf(address(alice)), 0, "_testClaim: E01");
        assertEq(IERC20(_compounder).balanceOf(address(bob)), 0, "_testClaim: E02");
        assertEq(IERC20(_compounder).balanceOf(address(charlie)), 0, "_testClaim: E03");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testClaim: E004");
        // assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testClaim: E04");
        // assertTrue(_localConcentrator.pendingReward(address(bob)) > 0, "_testClaim: E05");
        // assertTrue(_localConcentrator.pendingReward(address(charlie)) > 0, "_testClaim: E06");
        assertTrue(IERC20(_compounder).balanceOf(_concentrator) > 0, "_testClaim: E006");

        vm.prank(alice);
        uint256 _rewardsOutAlice = _localConcentrator.claim(address(alice));
        assertEq(_rewardsOutAlice, IERC20(_compounder).balanceOf(address(alice)), "_testClaim: E1");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testClaim: E2");

        vm.prank(bob);
        uint256 _rewardsOutBob = _localConcentrator.claim(address(bob));
        assertApproxEqAbs(_rewardsOutBob, IERC20(_compounder).balanceOf(address(alice)), 1e16, "_testClaim: E3");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testClaim: E4");

        vm.prank(charlie);
        uint256 _rewardsOutCharlie = _localConcentrator.claim(address(charlie));
        assertApproxEqAbs(_rewardsOutCharlie, IERC20(_compounder).balanceOf(address(alice)), 1e16, "_testClaim: E5");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testClaim: E6");

        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutBob, 1e19, "_testClaim: E7");
        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutCharlie, 1e19, "_testClaim: E8");
    }

    // todo

    // test mint

    // test withdraw

    // test redeemAndClaim

    // redeemUnderlyingAndClaim

    function _testHarvest(uint256 _totalShare, address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        
        assertEq(_localConcentrator.isPendingRewards(), false, "_testHarvest: E1");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testHarvest: E1");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testHarvest: E2");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testHarvest: E3");
        assertEq(_localConcentrator.accRewardPerShare(), 0, "_testHarvest: E4");
        assertTrue(_localConcentrator.totalAssets() > 0, "_testHarvest: E04");
        
        // Fast forward 1 month
        skip(216000);

        // From Curve dev discord "Arbitrum is probably a bit funkier -- I haven't dove into it, but I think it requires making a cross-chain call to trigger rewards that may be tough to reproduce"
        // assertEq(_localConcentrator.isPendingRewards(), true, "_testHarvest: E01");
        
        uint256 _underlyingBefore = _localConcentrator.totalAssets();
        uint256 _rewardsBefore = IERC20(_localConcentrator.compounder()).balanceOf(address(_localConcentrator));
        vm.prank(harvester);
        uint256 _newUnderlying = _localConcentrator.harvest(address(harvester), 0);

        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testHarvest: E001");
        assertTrue(_localConcentrator.pendingReward(address(bob)) > 0, "_testHarvest: E02");
        assertTrue(_localConcentrator.pendingReward(address(charlie)) > 0, "_testHarvest: E03");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testHarvest: E04");

        address _rewardAsset = address(ERC4626(address(_localConcentrator.compounder())).asset());
        assertEq(_localConcentrator.isPendingRewards(), false, "_testHarvest: E3");
        assertTrue(IERC20(_rewardAsset).balanceOf(platform) > 0, "_testHarvest: E4");
        assertTrue(IERC20(_rewardAsset).balanceOf(harvester) > 0, "_testHarvest: E5");
        assertEq(_localConcentrator.totalAssets(), _underlyingBefore, "_testHarvest: E6");
        assertEq(_localConcentrator.totalSupply(), _totalShare, "_testHarvest: E7");
        assertEq((IERC20(_localConcentrator.compounder()).balanceOf(address(_localConcentrator)) - _rewardsBefore), _newUnderlying, "_testHarvest: E8");
        assertTrue(_newUnderlying > 0, "_testHarvest: E9");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testHarvest: E10");
        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testHarvest: E11");
        assertApproxEqAbs(_localConcentrator.pendingReward(address(alice)) , _localConcentrator.pendingReward(address(bob)), 1e17, "_testHarvest: E12");
        assertApproxEqAbs(_localConcentrator.pendingReward(address(alice)) , _localConcentrator.pendingReward(address(charlie)), 1e17, "_testHarvest: E13");
    }

    function _testHarvestWithUnderlying(uint256 _totalShare, address _concentrator, address _targetAsset) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        
        assertEq(_localConcentrator.isPendingRewards(), false, "_testHarvest: E1");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testHarvest: E1");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testHarvest: E2");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testHarvest: E3");
        assertEq(_localConcentrator.accRewardPerShare(), 0, "_testHarvest: E4");
        
        // Fast forward 1 month
        skip(216000);

        assertEq(_localConcentrator.isPendingRewards(), true, "_testHarvest: E01");
        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testHarvest: E001");
        assertTrue(_localConcentrator.pendingReward(address(bob)) > 0, "_testHarvest: E02");
        assertTrue(_localConcentrator.pendingReward(address(charlie)) > 0, "_testHarvest: E03");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testHarvest: E04");
        
        uint256 _underlyingBefore = _localConcentrator.totalAssets();
        uint256 _rewardsBefore = IERC20(_localConcentrator.compounder()).balanceOf(address(_localConcentrator));
        vm.prank(harvester);
        uint256 _newUnderlying = CurveGlpConcentrator(payable(_concentrator)).harvest(address(harvester), _targetAsset, 0);

        address _rewardAsset = address(ERC4626(address(_localConcentrator.compounder())).asset());
        assertEq(_localConcentrator.isPendingRewards(), false, "_testHarvest: E3");
        assertTrue(IERC20(_rewardAsset).balanceOf(platform) > 0, "_testHarvest: E4");
        assertTrue(IERC20(_rewardAsset).balanceOf(harvester) > 0, "_testHarvest: E5");
        assertEq(_localConcentrator.totalAssets(), _underlyingBefore, "_testHarvest: E6");
        assertEq(_localConcentrator.totalSupply(), _totalShare, "_testHarvest: E7");
        assertEq((IERC20(_localConcentrator.compounder()).balanceOf(address(_localConcentrator)) - _rewardsBefore), _newUnderlying, "_testHarvest: E8");
        assertTrue(_newUnderlying > 0, "_testHarvest: E9");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testHarvest: E10");
        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testHarvest: E11");
        assertApproxEqAbs(_localConcentrator.pendingReward(address(alice)) , _localConcentrator.pendingReward(address(bob)), 1e17, "_testHarvest: E12");
        assertApproxEqAbs(_localConcentrator.pendingReward(address(alice)) , _localConcentrator.pendingReward(address(charlie)), 1e17, "_testHarvest: E13");
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- internal functions -------------------------------------
    // ------------------------------------------------------------------------------------------

    function _depositSingleUnderlyingAsset(address _owner, address _asset, uint256 _amount, address _concentrator) internal returns (uint256 _share) {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);

        vm.startPrank(_owner);

        uint256 _shareBefore = _localConcentrator.totalSupply();
        
        if (_asset != ETH) {
            IERC20(_asset).safeApprove(address(_concentrator), _amount);
            _share = _localConcentrator.depositSingleUnderlying(_amount, _asset, _owner, 0);
        } else {
            _share = _localConcentrator.depositSingleUnderlying{value: _amount}(_amount, _asset, _owner, 0);
        }
        vm.stopPrank();

        uint256 _totalShare = _shareBefore + _share;

        assertEq(_share, _localConcentrator.balanceOf(_owner), "_depositSingleUnderlyingAsset: E1");
        assertEq(_share, IERC20(_concentrator).balanceOf(_owner), "_depositSingleUnderlyingAsset: E2");
        assertEq(_localConcentrator.totalSupply(), _totalShare, "_depositSingleUnderlyingAsset: E3");
    } 
}