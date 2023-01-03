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

    function _testCorrectFlowTransfer(address _asset, uint256 _amount, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator);

        // ------------ Transfer ------------
        
        _testTransfer(_concentrator);

        // ------------ Claim ------------

        _testClaim(_concentrator);
    }

    function _testCorrectFlowHarvestWithUnderlying(address _asset, uint256 _amount, address _concentrator, address _targetAsset) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Harvest rewards ------------

        _testHarvestWithUnderlying((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator, _targetAsset);

        // ------------ Withdraw ------------
        
        _testRedeemUnderlying(_asset, _sharesAlice, _sharesBob, _sharesCharlie, _concentrator);

        // ------------ Claim ------------

        _testClaim(_concentrator);
    }

    function _testMint(address _asset, uint256 _amount, address _concentrator, address _targetAsset) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Redeem ------------

        (_underlyingAlice, _underlyingBob, _underlyingCharlie) = _testRedeemInt(_sharesAlice, _sharesBob, _sharesCharlie, _concentrator); 

        // ------------ Mint ------------

        (_sharesAlice, _sharesBob, _sharesCharlie) = _testMintInt(_underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);
        
        // ------------ Harvest rewards ------------

        _testHarvestWithUnderlying((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator, _targetAsset);

        // ------------ Withdraw ------------
        
        _testRedeemUnderlying(_asset, _sharesAlice, _sharesBob, _sharesCharlie, _concentrator);

        // ------------ Claim ------------

        _testClaim(_concentrator);
    }

    function _testWithdraw(address _asset, uint256 _amount, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Harvest ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator);

        // ------------ Withdraw ------------

        _testWithdrawInt(_sharesAlice, _sharesBob, _sharesCharlie, _concentrator);

        // ------------ Claim ------------

        _testClaim(_concentrator);
    }

    function _testRedeemUnderlyingAndClaim(address _asset, uint256 _amount, address _concentrator, address _underlyingAsset) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator);

        // ------------ Redeem underlying & Claim ------------
        
        _testRedeemUnderlyingAndClaimInt(_sharesAlice, _sharesBob, _sharesCharlie, _underlyingAsset, _concentrator);
    }

    function _testRedeemAndClaim(address _asset, uint256 _amount, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie, _concentrator);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie), _concentrator);

        // ------------ Redeem underlying & Claim ------------
        
        _testRedeemAndClaimInt(_sharesAlice, _sharesBob, _sharesCharlie, _concentrator);
    }

    function _testDepositNoAsset(uint256 _amount, address _asset, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);

        vm.startPrank(alice);
        
        IERC20(_asset).safeApprove(address(_localConcentrator), _amount);
        vm.expectRevert();
        _localConcentrator.deposit(_amount, address(alice));
        vm.expectRevert();
        _localConcentrator.mint(_amount, address(alice));
        vm.expectRevert();
        _localConcentrator.depositSingleUnderlying(_amount, _asset, address(alice), 0);

        vm.stopPrank();
    }

    function _testDepositWrongAsset(uint256 _amount, address _asset, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        
        vm.startPrank(alice);
        IERC20(_asset).safeApprove(address(_concentrator), _underlyingAlice);
        vm.expectRevert();
        _localConcentrator.depositSingleUnderlying(_underlyingAlice, _asset, address(alice), 0);

        vm.stopPrank();
    }

    function _testWithdrawNoShare(uint256 _amount, address _asset, address _concentrator) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        
        vm.startPrank(alice);
        IERC20(_asset).safeApprove(address(_concentrator), _underlyingAlice);
        uint256 _share = _localConcentrator.depositSingleUnderlying(_underlyingAlice, _asset, address(alice), 0);
        vm.stopPrank();
        assertEq(_share, IERC20(address(_concentrator)).balanceOf(alice), "testWithdrawNotOwner: E1");

        vm.startPrank(bob);
        
        vm.expectRevert();
        _localConcentrator.withdraw(_share, bob, alice);
        vm.expectRevert();
        _localConcentrator.withdraw(_share, bob, bob);
        vm.expectRevert();
        _localConcentrator.redeem(_share, bob, alice);
        vm.expectRevert();
        _localConcentrator.redeem(_share, bob, bob);
        vm.expectRevert();
        _localConcentrator.redeemSingleUnderlying(_share, _asset, bob, alice, 0);
        vm.expectRevert();
        _localConcentrator.redeemSingleUnderlying(_share, _asset, bob, bob, 0);
        
        vm.stopPrank();
    }

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

    function _testTransfer(address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);

        uint256 _sharesAlice = _localConcentrator.balanceOf(address(alice));
        uint256 _sharesBob = _localConcentrator.balanceOf(address(bob));
        uint256 _sharesCharlie = _localConcentrator.balanceOf(address(charlie));

        assertEq(_localConcentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testTransfer: E01");

        vm.prank(alice);
        _localConcentrator.transfer(address(yossi), _sharesAlice);
        vm.prank(bob);
        _localConcentrator.transfer(address(yossi), _sharesBob);
        vm.prank(charlie);
        _localConcentrator.transfer(address(yossi), _sharesCharlie);

        assertEq(_localConcentrator.balanceOf(address(alice)), 0, "_testTransfer: E1");
        assertEq(_localConcentrator.balanceOf(address(bob)), 0, "_testTransfer: E2");
        assertEq(_localConcentrator.balanceOf(address(charlie)), 0, "_testTransfer: E3");
        assertEq(_localConcentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testTransfer: E04");
        assertEq(_localConcentrator.balanceOf(address(yossi)), (_sharesAlice + _sharesBob + _sharesCharlie), "_testTransfer: E05");
    }

    function _testClaim(address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        address _compounder = _localConcentrator.compounder();
        
        assertEq(IERC20(_compounder).balanceOf(address(alice)), 0, "_testClaim: E01");
        assertEq(IERC20(_compounder).balanceOf(address(bob)), 0, "_testClaim: E02");
        assertEq(IERC20(_compounder).balanceOf(address(charlie)), 0, "_testClaim: E03");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testClaim: E004");
        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testClaim: E04");
        assertTrue(_localConcentrator.pendingReward(address(bob)) > 0, "_testClaim: E05");
        assertTrue(_localConcentrator.pendingReward(address(charlie)) > 0, "_testClaim: E06");
        assertTrue(IERC20(_compounder).balanceOf(_concentrator) > 0, "_testClaim: E006");
        
        uint256 _totalRewards = IERC20(_compounder).balanceOf(address(_localConcentrator));
        
        vm.prank(alice);
        uint256 _rewardsOutAlice = _localConcentrator.claim(address(alice));
        _totalRewards -= _rewardsOutAlice;

        assertEq(_rewardsOutAlice, IERC20(_compounder).balanceOf(address(alice)), "_testClaim: E1");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testClaim: E2");
        assertEq(IERC20(_compounder).balanceOf(address(_localConcentrator)), _totalRewards, "_testClaim: E007");

        vm.prank(bob);
        uint256 _rewardsOutBob = _localConcentrator.claim(address(bob));
        _totalRewards -= _rewardsOutBob;

        assertApproxEqAbs(_rewardsOutBob, IERC20(_compounder).balanceOf(address(alice)), 1e17, "_testClaim: E3");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testClaim: E4");
        assertEq(IERC20(_compounder).balanceOf(address(_localConcentrator)), _totalRewards, "_testClaim: E004");

        vm.prank(charlie);
        uint256 _rewardsOutCharlie = _localConcentrator.claim(address(charlie));
        _totalRewards -= _rewardsOutCharlie;

        assertApproxEqAbs(_rewardsOutCharlie, IERC20(_compounder).balanceOf(address(alice)), 1e17, "_testClaim: E5");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testClaim: E6");
        assertEq(IERC20(_compounder).balanceOf(address(_localConcentrator)), _totalRewards, "_testClaim: E006");

        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutBob, 1e19, "_testClaim: E7");
        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutCharlie, 1e19, "_testClaim: E8");
        assertApproxEqAbs(IERC20(_compounder).balanceOf(address(_localConcentrator)), 0, 1e10, "_testClaim: E008");
    }

    function _testMintInt(uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie, address _concentrator) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        // address _compounder = _localConcentrator.compounder();
        
        uint256 _lowestAsset = _assetsAlice < _assetsBob ? _assetsAlice : _assetsBob;
        _lowestAsset = _lowestAsset < _assetsCharlie ? _lowestAsset : _assetsCharlie;

        uint256 _dirtyTotalSupplyBefore = _localConcentrator.totalSupply();
        uint256 _dirtyTotalAssetsBefore = _localConcentrator.totalAssets();

        _sharesAlice = _localConcentrator.previewDeposit(_lowestAsset);
        assertEq(_sharesAlice, _lowestAsset, "_testMint: E01");
        vm.startPrank(alice);
        IERC20(address(_localConcentrator.asset())).safeApprove(address(_localConcentrator), _lowestAsset);
        uint256 _assetsAliceSent = _localConcentrator.mint(_sharesAlice, address(alice));
        vm.stopPrank();
        
        assertEq(IERC20(address(_localConcentrator)).balanceOf(address(alice)), _sharesAlice, "_testMintLP: E3");
        assertEq(_assetsAliceSent, _lowestAsset, "_testMintLP: E04");

        _sharesBob = _localConcentrator.previewDeposit(_lowestAsset);
        assertEq(_sharesBob, _lowestAsset, "_testMint: E01");
        vm.startPrank(bob);
        IERC20(address(_localConcentrator.asset())).safeApprove(address(_localConcentrator), _lowestAsset);
        uint256 _assetsBobSent = _localConcentrator.mint(_sharesBob, address(bob));
        vm.stopPrank();
        
        assertEq(IERC20(address(_localConcentrator)).balanceOf(address(bob)), _sharesBob, "_testMintLP: E6");
        assertEq(_assetsBobSent, _lowestAsset, "_testMintLP: E07");

        _sharesCharlie = _localConcentrator.previewDeposit(_lowestAsset);
        assertEq(_sharesCharlie, _lowestAsset, "_testMint: E01");
        vm.startPrank(charlie);
        IERC20(address(_localConcentrator.asset())).safeApprove(address(_localConcentrator), _lowestAsset);
        uint256 _assetsCharlieSent = _localConcentrator.mint(_sharesCharlie, address(charlie));
        vm.stopPrank();

        assertEq(IERC20(address(_localConcentrator)).balanceOf(address(charlie)), _sharesCharlie, "_testMintLP: E9");
        assertEq(_assetsCharlieSent, _lowestAsset, "_testMintLP: E010");

        uint256 _dirtyTotalSupply = (_sharesCharlie + _sharesBob + _sharesAlice) - _dirtyTotalSupplyBefore;
        uint256 _dirtyTotalAssets = (_assetsCharlieSent + _assetsBobSent + _assetsAliceSent) - _dirtyTotalAssetsBefore;

        assertEq(_localConcentrator.totalAssets(), _dirtyTotalAssets, "_testMintLP: E11");
        assertEq(_localConcentrator.totalSupply(), _dirtyTotalSupply, "_testMintLP: E12");
        assertEq(_sharesAlice, _sharesBob, "_testMintLP: E13");
        assertEq(_assetsAliceSent, _assetsBobSent, "_testMintLP: E14");
        assertEq(_assetsBobSent, _assetsCharlieSent, "_testMintLP: E15");
    }

    function _testRedeemInt(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie, address _concentrator) internal returns (uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        // address _compounder = _localConcentrator.compounder();
        
        uint256 _totalSupplyBefore = _localConcentrator.totalSupply();
        uint256 _totalAssetsBefore = _localConcentrator.totalAssets();

        uint256 _assetsAlice = _localConcentrator.previewRedeem(_sharesAlice);
        vm.startPrank(alice);
        _underlyingAlice = _localConcentrator.redeem(_sharesAlice, address(alice), address(alice));
        _totalSupplyBefore -= _sharesAlice;
        _totalAssetsBefore -= _assetsAlice;
        vm.stopPrank();
        
        assertEq(IERC20(address(_localConcentrator)).balanceOf(address(alice)), 0, "_testRedeemInt: E3");
        assertEq(_underlyingAlice, IERC20(address(_localConcentrator.asset())).balanceOf(address(alice)), "_testRedeemInt: E03");
        assertEq(_underlyingAlice, _assetsAlice, "_testRedeemInt: E04");
        assertEq(_localConcentrator.totalAssets(), _totalAssetsBefore, "_testRedeemInt: E05");
        assertEq(_localConcentrator.totalSupply(), _totalSupplyBefore, "_testRedeemInt: E06");

        uint256 _assetsBob = _localConcentrator.previewRedeem(_sharesBob);
        vm.startPrank(bob);
        _underlyingBob = _localConcentrator.redeem(_sharesBob, address(bob), address(bob));
        _totalSupplyBefore -= _sharesBob;
        _totalAssetsBefore -= _assetsBob;
        vm.stopPrank();
        
        assertEq(IERC20(address(_localConcentrator)).balanceOf(address(bob)), 0, "_testRedeemInt: E6");
        assertEq(_underlyingBob, _assetsBob, "_testRedeemInt: E07");
        assertEq(_localConcentrator.totalAssets(), _totalAssetsBefore, "_testRedeemInt: E08");
        assertEq(_localConcentrator.totalSupply(), _totalSupplyBefore, "_testRedeemInt: E09");
        assertEq(_underlyingBob, IERC20(address(_localConcentrator.asset())).balanceOf(address(bob)), "_testRedeemInt: E03");


        uint256 _assetsCharlie = _localConcentrator.previewRedeem(_sharesCharlie);
        vm.startPrank(charlie);
        _underlyingCharlie = _localConcentrator.redeem(_sharesCharlie, address(charlie), address(charlie));
        _totalSupplyBefore -= _sharesCharlie;
        _totalAssetsBefore -= _assetsCharlie;
        vm.stopPrank();

        assertEq(IERC20(address(_localConcentrator)).balanceOf(address(charlie)), 0, "_testRedeemInt: E9");
        assertEq(_assetsCharlie, _underlyingCharlie, "_testRedeemInt: E010");
        assertEq(_localConcentrator.totalAssets(), _totalAssetsBefore, "_testRedeemInt: E011");
        assertEq(_localConcentrator.totalSupply(), _totalSupplyBefore, "_testRedeemInt: E012");
        assertEq(_underlyingCharlie, IERC20(address(_localConcentrator.asset())).balanceOf(address(charlie)), "_testRedeemInt: E03");

        assertEq(_localConcentrator.totalAssets(), 0, "_testRedeemInt: E013");
        assertEq(_localConcentrator.totalSupply(), 0, "_testRedeemInt: E014");
    }

    function _testWithdrawInt(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie, address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        // address _compounder = _localConcentrator.compounder();

        uint256 _lowestShare = _sharesAlice < _sharesBob ? _sharesAlice : _sharesBob;
        _lowestShare = _lowestShare < _sharesCharlie ? _lowestShare : _sharesCharlie;

        uint256 _dirtyTotalSupply = _localConcentrator.totalSupply() - (_lowestShare * 3);
        uint256 _dirtyTotalAssetsBefore = _localConcentrator.totalAssets();
        
        vm.startPrank(alice);
        uint256 _assetsAlice = _localConcentrator.previewRedeem(_lowestShare);
        uint256 _sharesBurnAlice = _localConcentrator.withdraw(_assetsAlice, address(alice), address(alice));
        vm.stopPrank();

        assertEq(IERC20(address(_localConcentrator.asset())).balanceOf(address(alice)), _assetsAlice, "_testWithdrawLP: E1");
        assertApproxEqAbs(_sharesBurnAlice, _lowestShare, 1e16, "_testWithdrawLP: E2");
        assertApproxEqAbs(_localConcentrator.balanceOf(address(alice)), _sharesAlice - _lowestShare, 1e16, "_testWithdrawLP: E3");
        
        vm.startPrank(bob);
        uint256 _assetsBob = _localConcentrator.previewRedeem(_lowestShare);
        uint256 _sharesBurnBob = _localConcentrator.withdraw(_assetsBob, address(bob), address(bob));
        vm.stopPrank();
        
        assertEq(IERC20(address(_localConcentrator.asset())).balanceOf(address(bob)), _assetsBob, "_testWithdrawLP: E4");
        assertApproxEqAbs(_sharesBurnBob, _lowestShare, 1e16, "_testWithdrawLP: E5");
        assertApproxEqAbs(_localConcentrator.balanceOf(address(bob)), _sharesBob - _lowestShare, 1e16, "_testWithdrawLP: E6");
        
        vm.startPrank(charlie);
        uint256 _assetsCharlie = _localConcentrator.previewRedeem(_lowestShare);
        uint256 _sharesBurnCharlie = _localConcentrator.withdraw(_assetsCharlie, address(charlie), address(charlie));
        vm.stopPrank();
        
        assertEq(IERC20(address(_localConcentrator.asset())).balanceOf(address(charlie)), _assetsCharlie, "_testWithdrawLP: E7");
        assertApproxEqAbs(_sharesBurnCharlie, _lowestShare, 1e16, "_testWithdrawLP: E8");
        assertApproxEqAbs(_localConcentrator.balanceOf(address(charlie)), _sharesCharlie - _lowestShare, 1e16, "_testWithdrawLP: E9");
        
        uint256 _dirtyTotalAssets = _dirtyTotalAssetsBefore - (_assetsAlice + _assetsBob + _assetsCharlie);

        assertApproxEqAbs(_localConcentrator.totalAssets(), _dirtyTotalAssets, 1e16, "_testWithdrawLP: E10");
        assertApproxEqAbs(_localConcentrator.totalSupply(), _dirtyTotalSupply, 1e16, "_testWithdrawLP: E11");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnBob, 1e16, "_testWithdrawLP: E12");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnCharlie, 1e16, "_testWithdrawLP: E13");
    }

    function _testRedeemAndClaimInt(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie, address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        address _compounder = _localConcentrator.compounder();

        uint256 _lowestShare = _sharesAlice < _sharesBob ? _sharesAlice : _sharesBob;
        _lowestShare = _lowestShare < _sharesCharlie ? _lowestShare : _sharesCharlie;

        uint256 _dirtyTotalSupply = _localConcentrator.totalSupply() - (_lowestShare * 3);
        uint256 _dirtyTotalAssetsBefore = _localConcentrator.totalAssets();

        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testRedeemAndClaimInt: E1");
        assertTrue(_localConcentrator.pendingReward(address(bob)) > 0, "_testRedeemAndClaimInt: E2");
        assertTrue(_localConcentrator.pendingReward(address(charlie)) > 0, "_testRedeemAndClaimInt: E3");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testRedeemAndClaimInt: E4");
        assertTrue(_localConcentrator.balanceOf(address(alice)) > 0, "_testRedeemAndClaimInt: E5");
        assertTrue(_localConcentrator.balanceOf(address(bob)) > 0, "_testRedeemAndClaimInt: E6");
        assertTrue(_localConcentrator.balanceOf(address(charlie)) > 0, "_testRedeemAndClaimInt: E7");

        vm.startPrank(alice);
        (uint256 _assetsAlice, uint256 _rewards) = _localConcentrator.redeemAndClaim(_lowestShare, address(alice));
        vm.stopPrank();

        assertEq(IERC20(address(_localConcentrator.asset())).balanceOf(address(alice)), _assetsAlice, "_testRedeemAndClaimInt: E8");
        assertEq(IERC20(_compounder).balanceOf(address(alice)), _rewards, "_testRedeemAndClaimInt: E9");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testRedeemAndClaimInt: E11");

        vm.startPrank(bob);
        (uint256 _assetsBob, uint256 _rewardsBob) = _localConcentrator.redeemAndClaim(_lowestShare, address(bob));
        vm.stopPrank();

        assertEq(IERC20(address(_localConcentrator.asset())).balanceOf(address(bob)), _assetsBob, "_testRedeemAndClaimInt: E12");
        assertEq(IERC20(_compounder).balanceOf(address(bob)), _rewardsBob, "_testRedeemAndClaimInt: E13");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testRedeemAndClaimInt: E14");

        vm.startPrank(charlie);
        (uint256 _assetsCharlie, uint256 _rewardsCharlie) = _localConcentrator.redeemAndClaim(_lowestShare, address(charlie));
        vm.stopPrank();

        assertEq(IERC20(address(_localConcentrator.asset())).balanceOf(address(charlie)), _assetsCharlie, "_testRedeemAndClaimInt: E15");
        assertEq(IERC20(_compounder).balanceOf(address(charlie)), _rewardsCharlie, "_testRedeemAndClaimInt: E16");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testRedeemAndClaimInt: E17");

        uint256 _dirtyTotalAssets = _dirtyTotalAssetsBefore - (_assetsAlice + _assetsBob + _assetsCharlie);

        assertApproxEqAbs(_localConcentrator.totalAssets(), _dirtyTotalAssets, 1e16, "_testRedeemAndClaimInt: E18");
        assertApproxEqAbs(_localConcentrator.totalSupply(), _dirtyTotalSupply, 1e16, "_testRedeemAndClaimInt: E19");
    }

    function _testRedeemUnderlyingAndClaimInt(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie, address _underlyingAsset, address _concentrator) internal {
        AMMConcentratorBase _localConcentrator = AMMConcentratorBase(_concentrator);
        address _compounder = _localConcentrator.compounder();

        uint256 _lowestShare = _sharesAlice < _sharesBob ? _sharesAlice : _sharesBob;
        _lowestShare = _lowestShare < _sharesCharlie ? _lowestShare : _sharesCharlie;

        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testRedeemUnderlyingAndClaimInt: E1");
        assertTrue(_localConcentrator.pendingReward(address(bob)) > 0, "_testRedeemUnderlyingAndClaimInt: E2");
        assertTrue(_localConcentrator.pendingReward(address(charlie)) > 0, "_testRedeemUnderlyingAndClaimInt: E3");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testRedeemUnderlyingAndClaimInt: E4");
        assertTrue(_localConcentrator.balanceOf(address(alice)) > 0, "_testRedeemUnderlyingAndClaimInt: E5");
        assertTrue(_localConcentrator.balanceOf(address(bob)) > 0, "_testRedeemUnderlyingAndClaimInt: E6");
        assertTrue(_localConcentrator.balanceOf(address(charlie)) > 0, "_testRedeemUnderlyingAndClaimInt: E7");

        vm.startPrank(alice);
        (uint256 _underlyingAmount, uint256 _rewards) = _localConcentrator.redeemUnderlyingAndClaim(_lowestShare, _underlyingAsset, address(alice), 0);
        vm.stopPrank();

        assertEq(IERC20(_underlyingAsset).balanceOf(address(alice)), _underlyingAmount, "_testRedeemUnderlyingAndClaimInt: E8");
        assertEq(IERC20(_compounder).balanceOf(address(alice)), _rewards, "_testRedeemUnderlyingAndClaimInt: E9");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testRedeemUnderlyingAndClaimInt: E11");

        vm.startPrank(bob);
        (uint256 _underlyingAmount2, uint256 _rewards2) = _localConcentrator.redeemUnderlyingAndClaim(_lowestShare, _underlyingAsset, address(bob), 0);
        vm.stopPrank();

        assertEq(IERC20(_underlyingAsset).balanceOf(address(bob)), _underlyingAmount2, "_testRedeemUnderlyingAndClaimInt: E12");
        assertEq(IERC20(_compounder).balanceOf(address(bob)), _rewards2, "_testRedeemUnderlyingAndClaimInt: E13");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testRedeemUnderlyingAndClaimInt: E14");

        vm.startPrank(charlie);
        (uint256 _underlyingAmount3, uint256 _rewards3) = _localConcentrator.redeemUnderlyingAndClaim(_lowestShare, _underlyingAsset, address(charlie), 0);
        vm.stopPrank();

        assertEq(IERC20(_underlyingAsset).balanceOf(address(charlie)), _underlyingAmount3, "_testRedeemUnderlyingAndClaimInt: E15");
        assertEq(IERC20(_compounder).balanceOf(address(charlie)), _rewards3, "_testRedeemUnderlyingAndClaimInt: E16");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testRedeemUnderlyingAndClaimInt: E17");

        assertApproxEqAbs(_underlyingAmount, _underlyingAmount2, 1e20, "_testRedeemUnderlyingAndClaimInt: E18");
        assertApproxEqAbs(_underlyingAmount, _underlyingAmount3, 1e20, "_testRedeemUnderlyingAndClaimInt: E19");
        assertApproxEqAbs(_rewards, _rewards2, 1e18, "_testRedeemUnderlyingAndClaimInt: E20");
        assertApproxEqAbs(_rewards, _rewards3, 1e18, "_testRedeemUnderlyingAndClaimInt: E21");
    }

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
        
        assertEq(_localConcentrator.isPendingRewards(), false, "_testHarvestWithUnderlying: E1");
        assertEq(_localConcentrator.pendingReward(address(alice)), 0, "_testHarvestWithUnderlying: E1");
        assertEq(_localConcentrator.pendingReward(address(bob)), 0, "_testHarvestWithUnderlying: E2");
        assertEq(_localConcentrator.pendingReward(address(charlie)), 0, "_testHarvestWithUnderlying: E3");
        assertEq(_localConcentrator.accRewardPerShare(), 0, "_testHarvestWithUnderlying: E4");
        
        // Fast forward 1 month
        skip(216000);

        // assertEq(_localConcentrator.isPendingRewards(), true, "_testHarvestWithUnderlying: E01");
        
        uint256 _underlyingBefore = _localConcentrator.totalAssets();
        uint256 _rewardsBefore = IERC20(_localConcentrator.compounder()).balanceOf(address(_localConcentrator));
        vm.prank(harvester);
        uint256 _newUnderlying = CurveGlpConcentrator(payable(_concentrator)).harvest(address(harvester), _targetAsset, 0);

        address _rewardAsset = address(ERC4626(address(_localConcentrator.compounder())).asset());
        assertEq(_localConcentrator.isPendingRewards(), false, "_testHarvestWithUnderlying: E3");
        assertTrue(IERC20(_rewardAsset).balanceOf(platform) > 0, "_testHarvestWithUnderlying: E4");
        assertTrue(IERC20(_rewardAsset).balanceOf(harvester) > 0, "_testHarvestWithUnderlying: E5");
        assertEq(_localConcentrator.totalAssets(), _underlyingBefore, "_testHarvestWithUnderlying: E6");
        assertEq(_localConcentrator.totalSupply(), _totalShare, "_testHarvestWithUnderlying: E7");
        assertEq((IERC20(_localConcentrator.compounder()).balanceOf(address(_localConcentrator)) - _rewardsBefore), _newUnderlying, "_testHarvestWithUnderlying: E8");
        assertTrue(_newUnderlying > 0, "_testHarvestWithUnderlying: E9");
        assertTrue(_localConcentrator.accRewardPerShare() > 0, "_testHarvestWithUnderlying: E10");
        assertTrue(_localConcentrator.pendingReward(address(alice)) > 0, "_testHarvestWithUnderlying: E11");
        assertApproxEqAbs(_localConcentrator.pendingReward(address(alice)) , _localConcentrator.pendingReward(address(bob)), 1e17, "_testHarvestWithUnderlying: E12");
        assertApproxEqAbs(_localConcentrator.pendingReward(address(alice)) , _localConcentrator.pendingReward(address(charlie)), 1e17, "_testHarvestWithUnderlying: E13");
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