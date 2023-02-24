// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "src/shared/interfaces/IConvexBasicRewards.sol";

// import "src/mainnet/compounders/balancer/AuraBalCompounder.sol";

// import "test/mainnet/concentrator/BaseTest.sol";

// import "script/mainnet/utils/concentrators/balancer/aurabal/InitWETHAURAConcentrator.sol";
contract testWETHAURAauraBALConcentrator {}
// contract testWETHAURAauraBALConcentrator is InitWETHAURAConcentrator, BaseTest {

//     using SafeERC20 for IERC20;

//     AuraBalCompounder auraBALCompounder;
//     AuraBalConcentrator WethAuraauraBalConcentrator;
    
//     function setUp() public {
        
//         _setUp();

//         auraBALCompounder = new AuraBalCompounder(owner, platform, address(fortressSwap));

//         address tempAddr = _initWETHAURAConcentrator(address(owner), address(fortressRegistry), address(fortressSwap), platform, address(auraBALCompounder));
//         WethAuraauraBalConcentrator = AuraBalConcentrator(payable(tempAddr));
//     }

//     // todo - add testWithdraw, testMint


//     function testCorrectFlowAURA(uint256 _amount) public {
//         // uint256 _amount = 1 ether;
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
//         // ------------ Get _asset ------------
        
//         uint256 _underlyingAlice = _getAssetFromETH(alice, AURA, _amount);
//         uint256 _underlyingBob = _getAssetFromETH(bob, AURA, _amount);
//         uint256 _underlyingCharlie = _getAssetFromETH(charlie, AURA, _amount);

//         // ------------ Deposit ------------

//         (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(AURA, _underlyingAlice, _underlyingBob, _underlyingCharlie);

//         // ------------ Harvest rewards ------------

//         _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

//         // ------------ Withdraw ------------

//         _testWithdrawUnderlying(AURA, _sharesAlice, _sharesBob, _sharesCharlie);

//         // ------------ Claim ------------

//         _testClaim();
//     }

//     function testCorrectFlowWETH(uint256 _amount) public {
//         // uint256 _amount = 1 ether;
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         // ------------ Get _asset ------------
        
//         uint256 _underlyingAlice = _getAssetFromETH(alice, WETH, _amount);
//         uint256 _underlyingBob = _getAssetFromETH(bob, WETH, _amount);
//         uint256 _underlyingCharlie = _getAssetFromETH(charlie, WETH, _amount);
        
//         // ------------ Deposit ------------

//         (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(WETH, _underlyingAlice, _underlyingBob, _underlyingCharlie);

//         // ------------ Harvest rewards ------------

//         _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

//         // ------------ Withdraw ------------

//         _testWithdrawUnderlying(AURA, _sharesAlice, _sharesBob, _sharesCharlie);

//         // ------------ Claim ------------

//         _testClaim();
//     }

//     function testDepositCap(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
//         address _asset = AURA; 
        
//         // ------------ Get _asset ------------
        
//         uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
//         uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
//         uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

//         // ------------ Deposit ------------

//         _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

//         // ------------ Harvest ------------
        
//         // Fast forward 1 month
//         skip(216000);

//         vm.prank(harvester);
//         WethAuraauraBalConcentrator.harvest(address(harvester), 0);

//         // ------------ Deposit Cap ------------

//         _testDepositCapInt(_asset);
//     }

//     function _testDepositCapInt(address _asset) internal {
//         assertEq(WethAuraauraBalConcentrator.depositCap(), 0, "_testDepositCap: E1");
//         assertEq(WethAuraauraBalConcentrator.platform(), address(platform), "_testDepositCap: E2");
//         assertEq(WethAuraauraBalConcentrator.swap(), address(fortressSwap), "_testDepositCap: E3");
//         assertEq(WethAuraauraBalConcentrator.owner(), address(owner), "_testDepositCap: E4");
//         assertEq(WethAuraauraBalConcentrator.maxDeposit(address(alice)), type(uint256).max, "_testDepositCap: E3");
//         assertEq(WethAuraauraBalConcentrator.maxMint(address(alice)), type(uint256).max, "_testDepositCap: E4");

//         vm.startPrank(owner);
//         WethAuraauraBalConcentrator.updateInternalUtils(address(auraBALCompounder), address(platform), address(fortressSwap), address(owner), WethAuraauraBalConcentrator.totalSupply());
//         vm.stopPrank();
        
//         assertEq(WethAuraauraBalConcentrator.depositCap(), WethAuraauraBalConcentrator.totalSupply(), "_testDepositCap: E2");
//         assertEq(WethAuraauraBalConcentrator.maxDeposit(address(alice)), 0, "_testDepositCap: E3");
//         assertEq(WethAuraauraBalConcentrator.maxMint(address(alice)), 0, "_testDepositCap: E4");

//         uint256 _amount = 1 ether;
//         uint256 _balance = _getAssetFromETH(alice, _asset, _amount);
//         vm.startPrank(alice);
//         IERC20(_asset).safeApprove(address(WethAuraauraBalConcentrator), _balance);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.depositSingleUnderlying(_balance, _asset, address(alice), 0);
//         vm.stopPrank();
//     }

//     function testDepositNoAsset(uint256 _amount) public {
//         vm.startPrank(alice);
        
//         IERC20(AURA).safeApprove(address(WethAuraauraBalConcentrator), _amount);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.depositSingleUnderlying(_amount, AURA, alice, 0);

//         vm.stopPrank();
//     }

//     function testDepositWrongAsset(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
//         uint256 _underlyingAlice = _getAssetFromETH(alice, BAL, _amount);
        
//         vm.startPrank(alice);
//         IERC20(BAL).safeApprove(address(WethAuraauraBalConcentrator), _underlyingAlice);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.depositSingleUnderlying(_underlyingAlice, BAL, alice, 0);

//         vm.stopPrank();
//     }

//     function testWrongWithdraw(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
//         uint256 _underlyingAlice = _getAssetFromETH(alice, AURA, _amount);
        
//         vm.startPrank(alice);
//         IERC20(AURA).safeApprove(address(WethAuraauraBalConcentrator), _underlyingAlice);
//         uint256 _share = WethAuraauraBalConcentrator.depositSingleUnderlying(_underlyingAlice, AURA, alice, 0);
//         vm.stopPrank();
//         assertEq(_share, IERC20(address(WethAuraauraBalConcentrator)).balanceOf(alice), "testWithdrawNotOwner: E1");

//         vm.startPrank(bob);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.redeem(_share, bob, alice);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.redeem(_share, bob, bob);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.redeemSingleUnderlying(_share, AURA, bob, alice, 0);
//         vm.expectRevert();
//         WethAuraauraBalConcentrator.redeemSingleUnderlying(_share, AURA, bob, bob, 0);
//         vm.stopPrank();
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- internal functions -------------------------------------
//     // ------------------------------------------------------------------------------------------

//     function _depositSingleUnderlyingAsset(address _owner, address _asset, uint256 _amount) internal returns (uint256 _share) {
//         vm.startPrank(_owner);
//         if (_asset != ETH) {
//             IERC20(_asset).safeApprove(address(WethAuraauraBalConcentrator), _amount);
//             _share = WethAuraauraBalConcentrator.depositSingleUnderlying(_amount, _asset, _owner, 0);
//         } else {
//             _share = WethAuraauraBalConcentrator.depositSingleUnderlying{value: _amount}(_amount, _asset, _owner, 0);
//         }
//         vm.stopPrank();

//         assertEq(_share, WethAuraauraBalConcentrator.balanceOf(_owner), "_depositSingleUnderlyingAsset: E1");
//     }

//     function _testDepositUnderlying(address _asset, uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
//         _sharesAlice = _depositSingleUnderlyingAsset(alice, _asset, _underlyingAlice);
//         _sharesBob = _depositSingleUnderlyingAsset(bob, _asset, _underlyingBob);
//         _sharesCharlie = _depositSingleUnderlyingAsset(charlie, _asset, _underlyingCharlie);
        
//         assertEq(WethAuraauraBalConcentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositUnderlying: E1");
//         assertEq(WethAuraauraBalConcentrator.totalAssets(), IConvexBasicRewards(WethAuraauraBalConcentrator.crvRewards()).balanceOf(address(WethAuraauraBalConcentrator)), "_testDepositUnderlying: E2");
//         assertApproxEqAbs(_sharesAlice, _sharesBob, 1e19, "_testDepositUnderlying: E3");
//         assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e19, "_testDepositUnderlying: E4");

//         return (_sharesAlice, _sharesBob, _sharesCharlie);
//     }

//     function _testHarvest(uint256 _totalShare) internal {
//         assertTrue(IConvexBasicRewards(WethAuraauraBalConcentrator.crvRewards()).earned(address(WethAuraauraBalConcentrator)) == 0, "_testHarvest: E1");
//         assertEq(WethAuraauraBalConcentrator.pendingReward(address(alice)), 0, "_testHarvest: E01");
//         assertEq(WethAuraauraBalConcentrator.pendingReward(address(alice)) , WethAuraauraBalConcentrator.pendingReward(address(bob)), "_testHarvest: E02");
//         assertEq(WethAuraauraBalConcentrator.pendingReward(address(alice)) , WethAuraauraBalConcentrator.pendingReward(address(charlie)), "_testHarvest: E03");
//         assertEq(WethAuraauraBalConcentrator.accRewardPerShare(), 0, "_testHarvest: E04");
        
//         // Fast forward 1 month
//         skip(216000);

//         assertTrue(IConvexBasicRewards(WethAuraauraBalConcentrator.crvRewards()).earned(address(WethAuraauraBalConcentrator)) > 0, "_testHarvest: E2");
        
//         uint256 _underlyingBefore = WethAuraauraBalConcentrator.totalAssets();
//         uint256 _rewardsBefore = IERC20(address(auraBALCompounder)).balanceOf(address(WethAuraauraBalConcentrator));
//         vm.prank(harvester);
//         uint256 _newUnderlying = WethAuraauraBalConcentrator.harvest(address(harvester), 0);

//         assertTrue(IConvexBasicRewards(WethAuraauraBalConcentrator.crvRewards()).earned(address(WethAuraauraBalConcentrator)) == 0, "_testHarvest: E3");
//         assertTrue(IERC20(auraBAL).balanceOf(platform) > 0, "_testHarvest: E4");
//         assertTrue(IERC20(auraBAL).balanceOf(harvester) > 0, "_testHarvest: E5");
//         assertEq(WethAuraauraBalConcentrator.totalAssets(), _underlyingBefore, "_testHarvest: E6");
//         assertEq(WethAuraauraBalConcentrator.totalSupply(), _totalShare, "_testHarvest: E7");
//         assertEq((IERC20(address(auraBALCompounder)).balanceOf(address(WethAuraauraBalConcentrator)) - _rewardsBefore), _newUnderlying, "_testHarvest: E8");
//         assertTrue(_newUnderlying > 0, "_testHarvest: E9");
//         assertTrue(WethAuraauraBalConcentrator.accRewardPerShare() > 0, "_testHarvest: E10");
//         assertTrue(WethAuraauraBalConcentrator.pendingReward(address(alice)) > 0, "_testHarvest: E11");
//         assertApproxEqAbs(WethAuraauraBalConcentrator.pendingReward(address(alice)) , WethAuraauraBalConcentrator.pendingReward(address(bob)), 1e17, "_testHarvest: E12");
//         assertApproxEqAbs(WethAuraauraBalConcentrator.pendingReward(address(alice)) , WethAuraauraBalConcentrator.pendingReward(address(charlie)), 1e17, "_testHarvest: E13");
//     }

//     function _testWithdrawUnderlying(address _asset, uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
//         vm.prank(alice);
//         uint256 _tokenOutAlice = WethAuraauraBalConcentrator.redeemSingleUnderlying(_sharesAlice, _asset, address(alice), address(alice), 0);
//         assertEq(_tokenOutAlice, IERC20(_asset).balanceOf(address(alice)), "_testWithdrawUnderlying: E1");
//         assertEq(WethAuraauraBalConcentrator.balanceOf(address(alice)), 0, "_testWithdrawUnderlying: E2");
        
//         vm.prank(bob);
//         uint256 _tokenOutBob = WethAuraauraBalConcentrator.redeemSingleUnderlying(_sharesBob, _asset, address(bob), address(bob), 0);
//         assertEq(_tokenOutBob, IERC20(_asset).balanceOf(address(bob)), "_testWithdrawUnderlying: E3");
//         assertEq(WethAuraauraBalConcentrator.balanceOf(address(bob)), 0, "_testWithdrawUnderlying: E4");

//         vm.prank(charlie);
//         uint256 _tokenOutCharlie = WethAuraauraBalConcentrator.redeemSingleUnderlying(_sharesCharlie, _asset, address(charlie), address(charlie), 0);
//         assertEq(_tokenOutCharlie, IERC20(_asset).balanceOf(address(charlie)), "_testWithdrawUnderlying: E5");
//         assertEq(WethAuraauraBalConcentrator.balanceOf(address(charlie)), 0, "_testWithdrawUnderlying: E6");

//         assertEq(WethAuraauraBalConcentrator.totalAssets(), 0, "_testWithdrawUnderlying: E7");
//         assertEq(WethAuraauraBalConcentrator.totalSupply(), 0, "_testWithdrawUnderlying: E8");
//         assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e20, "_testWithdrawUnderlying: E9");
//         assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e20, "_testWithdrawUnderlying: E10");
//     }

//     function _testClaim() internal {
//         vm.prank(alice);
//         uint256 _rewardsOutAlice = WethAuraauraBalConcentrator.claim(address(alice));
//         assertTrue(_rewardsOutAlice > 0, "_testClaim: E01");
//         assertEq(_rewardsOutAlice, IERC20(address(auraBALCompounder)).balanceOf(address(alice)), "_testClaim: E1");
//         assertEq(WethAuraauraBalConcentrator.pendingReward(address(alice)), 0, "_testClaim: E2");

//         vm.prank(bob);
//         uint256 _rewardsOutBob = WethAuraauraBalConcentrator.claim(address(bob));
//         assertTrue(_rewardsOutBob > 0, "_testClaim: E02");
//         assertEq(_rewardsOutBob, IERC20(address(auraBALCompounder)).balanceOf(address(bob)), "_testClaim: E3");
//         assertEq(WethAuraauraBalConcentrator.pendingReward(address(bob)), 0, "_testClaim: E4");

//         vm.prank(charlie);
//         uint256 _rewardsOutCharlie = WethAuraauraBalConcentrator.claim(address(charlie));
//         assertTrue(_rewardsOutCharlie > 0, "_testClaim: E03");
//         assertEq(_rewardsOutCharlie, IERC20(address(auraBALCompounder)).balanceOf(address(charlie)), "_testClaim: E5");
//         assertEq(WethAuraauraBalConcentrator.pendingReward(address(charlie)), 0, "_testClaim: E6");

//         assertApproxEqAbs(_rewardsOutAlice, _rewardsOutBob, 1e19, "_testClaim: E7");
//         assertApproxEqAbs(_rewardsOutAlice, _rewardsOutCharlie, 1e19, "_testClaim: E8");
//     } 
// }