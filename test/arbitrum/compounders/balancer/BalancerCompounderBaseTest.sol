// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/arbitrum/compounders/balancer/BalancerArbiCompounder.sol";
import "src/shared/utils/YieldOptimizersRegistry.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "script/arbitrum/utils/AddressesArbi.sol";
import "src/arbitrum/utils/BalancerArbiOperations.sol";

import "src/shared/interfaces/ERC20.sol";
import "src/shared/interfaces/IWETH.sol";

contract BalancerArbiCompounderBaseTest is Test, AddressesArbi {

    using SafeERC20 for IERC20;

    address alice;
    address bob;
    address charlie;
    address yossi;
    address harvester;

    address owner = vm.envAddress("FORTRESS_MULTISIG_OWNER");
    address platform = vm.envAddress("FORTRESS_MULTISIG_PLATFORM");
    address deployer = vm.envAddress("FORTRESS_DEPLOYER_ADDRESS");

    uint256 arbitrumFork;
    
    BalancerArbiCompounder balancerCompounder;
    YieldOptimizersRegistry registry;
    BalancerArbiOperations ammOperations;
    FortressArbiSwap fortressSwap;

    function _setUp() internal {

        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);

        alice = address(0xFa0C696bC56AE0d256D34a307c447E80bf92Dd41);
        bob = address(0x864e4b0c28dF7E2f317FF339CebDB5224F47220e);
        charlie = address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc);
        yossi = address(0x77Ee01E3d0E05b4afF42105Fe004520421248261);
        harvester = address(0xBF93B898E8Eee7dd6915735eB1ea9BFc4b98BEc0);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(yossi, 100 ether);
        vm.deal(harvester, 100 ether);

        vm.startPrank(owner);
        ammOperations = new BalancerArbiOperations(address(deployer));
        fortressSwap = FortressArbiSwap(payable(FortressSwapV2));
        vm.stopPrank();
    }

    function _testSingleUnwrapped(address _asset, uint256 _amount) internal {
        
        // ------------ Get _asset ------------
        

        vm.startPrank(alice);
        _dealERC20(address(_asset), alice, _amount);
        IERC20(_asset).approve(_asset, _amount);
        vm.stopPrank();

        vm.startPrank(bob);
        _dealERC20(address(_asset), bob, _amount);
        IERC20(_asset).approve(_asset, _amount);
        vm.stopPrank();

        vm.startPrank(charlie);
        _dealERC20(address(_asset), charlie, _amount);
        IERC20(_asset).approve(_asset, _amount);
        vm.stopPrank();

        uint256 _underlyingAlice = IERC20(_asset).balanceOf(alice);
        uint256 _underlyingBob = IERC20(_asset).balanceOf(bob);
        uint256 _underlyingCharlie = IERC20(_asset).balanceOf(charlie);


        // // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrapped(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);
        
        // ------------ Harvest rewards ------------

        _testHarvest(_asset, (_sharesAlice + _sharesBob + _sharesCharlie));

        // // // // ------------ Withdraw ------------

        _testRedeemSingleUnwrapped(_asset, _sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testSingleUnwrappedETH(uint256 _amount) internal {
        
        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrappedETH(_amount);

        // ------------ Harvest rewards ------------

        _testHarvest(ETH, (_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Withdraw ------------

        _testRedeemSingleUnwrappedETH(_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testDepositCap(address _asset, uint256 _amount) internal {
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        _testDepositSingleUnwrapped(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest ------------
        
        // Fast forward 1 month
        skip(216000);

        (,, address _crvRewards) = balancerCompounder.boosterData();
        vm.prank(harvester);
        uint256 _rewards = balancerCompounder.harvest(address(harvester), _asset, 0);
        assertTrue(_rewards > 0, "_testHarvest: E3");

        // ------------ Deposit Cap ------------

        _testDepositCapInt(_asset);

        assertTrue(IConvexBasicRewardsArbi(_crvRewards).rewards(address(balancerCompounder)) == 0, "_testHarvest: E1");
    }

    function _testRedeem(address _asset, uint256 _amount) internal {
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrapped(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest(_asset, (_sharesAlice + _sharesBob + _sharesCharlie));
        
        // ------------ Redeem shares for LP ------------

        _testRedeem(_sharesAlice, _sharesBob, _sharesCharlie);

    }

    function _testWithdraw(address _asset, uint256 _amount) internal {
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrapped(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest(_asset, (_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Withdraw ------------

        _testWithdrawLP(_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testDeposit(uint256 _amount) internal {

        // ------------ Get _asset ------------

        address[] memory _underlyingAssets = balancerCompounder.getUnderlyingAssets();
        
        address _underlyingAsset;
        if (_underlyingAssets[0] != ETH) {
            _underlyingAsset = _underlyingAssets[0];
        } else {
            _underlyingAsset = _underlyingAssets[1];
        }

        uint256 _underlyingAlice = _getAssetFromETH(alice, _underlyingAsset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _underlyingAsset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _underlyingAsset, _amount);

        // ------------ DepositSingleUnwrapped ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrapped(_underlyingAsset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Redeem shares for LP ------------

        (uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie) = _testRedeem(_sharesAlice, _sharesBob, _sharesCharlie);

        // ------------ Deposit LP ------------

        _testDepositLP(_assetsAlice, _assetsBob, _assetsCharlie);
    }
    
    function _testMint(address _underlyingAsset, uint256 _amount) internal {

        // ------------ Get _underlyingAsset ------------

        uint256 _underlyingAlice = _getAssetFromETH(alice, _underlyingAsset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _underlyingAsset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _underlyingAsset, _amount);

        // ------------ DepositSingleUnwrapped ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrapped(_underlyingAsset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Redeem shares for LP ------------

        (uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie) = _testRedeem(_sharesAlice, _sharesBob, _sharesCharlie);

        // ------------ Mint shares ------------

        _testMintLP(_assetsAlice, _assetsBob, _assetsCharlie);
    }

    function _testNoAssetsDeposit(uint256 _assets) internal {
        vm.startPrank(alice);
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assets);
        vm.expectRevert();
        balancerCompounder.deposit(_assets, address(alice));
        vm.stopPrank();
    }

    function _testNoAssetsMint(uint256 _shares) internal {
        vm.startPrank(alice);
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), type(uint256).max);
        vm.expectRevert();
        balancerCompounder.mint(_shares, address(alice));
        vm.stopPrank();
    }

    function _testHarvestNoBounty(address _asset) internal {
        vm.startPrank(alice);
        vm.expectRevert();
        balancerCompounder.harvest(address(alice), _asset, 0);
        vm.stopPrank();
    }

    function _testSingleUnwrappedDepositWrongAsset(address _asset, uint256 _amount) internal {
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        
        vm.startPrank(alice);
        if (_asset != ETH) {
            IERC20(_asset).safeApprove(address(balancerCompounder), _underlyingAlice);
        }
        
        vm.expectRevert();
        balancerCompounder.depositUnderlying(_asset, address(alice), _underlyingAlice, 0);
        vm.stopPrank();
    }

    function _testNoSharesWithdraw(uint256 _amount, address _underlyingAsset) internal {
        
        // ------------ Get _underlyingAsset ------------

        uint256 _underlyingAlice = _getAssetFromETH(alice, _underlyingAsset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _underlyingAsset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _underlyingAsset, _amount);

        // ------------ DepositSingleUnwrapped ------------

        (uint256 _sharesAlice,,) = _testDepositSingleUnwrapped(_underlyingAsset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Withdraw too many assets ------------

        vm.startPrank(alice);
        uint256 _tooManyAssets = balancerCompounder.previewRedeem(_sharesAlice) + 1 ether;
        vm.expectRevert();
        balancerCompounder.withdraw(_tooManyAssets, address(alice), address(alice));
        vm.stopPrank();
    }

    function _testNoSharesRedeem(uint256 _amount, address _underlyingAsset) internal {
        
        // ------------ Get _underlyingAsset ------------

        uint256 _underlyingAlice = _getAssetFromETH(alice, _underlyingAsset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _underlyingAsset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _underlyingAsset, _amount);

        // ------------ DepositSingleUnwrapped ------------

        _testDepositSingleUnwrapped(_underlyingAsset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Redeem too many shares ------------

        vm.startPrank(alice);
        uint256 _tooManyShares = balancerCompounder.balanceOf(address(alice)) + 1 ether;
        vm.expectRevert();
        balancerCompounder.redeem(_tooManyShares, address(alice), address(alice));
        vm.stopPrank();
    }

    function _getAssetFromETH(address _owner, address _asset, uint256 _amount) internal returns (uint256 _assetOut) {
         if (_asset != WETH) {
            vm.prank(_owner);
            _assetOut = fortressSwap.swap{ value: _amount }(ETH, _asset, _amount);
            
            assertApproxEqAbs(IERC20(_asset).balanceOf(_owner), _assetOut, 5, "_getAssetFromETH: E1");
        } else {
            _wrapETH(_owner, _amount);
            _assetOut = _amount;
        }
    }

    function _depositSingleUnwrapped(address _owner, address _asset, uint256 _amount) internal returns (uint256 _share) {
        vm.startPrank(_owner);
        IERC20(_asset).safeApprove(address(balancerCompounder), _amount);
        _share = balancerCompounder.depositUnderlying(_asset, _owner, _amount, 0);
        vm.stopPrank();

        assertEq(_share, balancerCompounder.balanceOf(_owner), "_depositSingleUnwrapped: E1");
    }

    function _depositSingleUnwrappedETH(address _owner, uint256 _amount) internal returns (uint256 _share) {
        vm.startPrank(_owner);
        _share = balancerCompounder.depositUnderlying{ value: _amount }(ETH, _owner, _amount, 0);
        vm.stopPrank();

        assertEq(_share, balancerCompounder.balanceOf(_owner), "_depositSingleUnwrapped: E1");
    }

    function _testDepositSingleUnwrapped(address _asset, uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        _sharesAlice = _depositSingleUnwrapped(alice, _asset, _underlyingAlice);
        _sharesBob = _depositSingleUnwrapped(bob, _asset, _underlyingBob);
        _sharesCharlie = _depositSingleUnwrapped(charlie, _asset, _underlyingCharlie);
        
        assertEq(balancerCompounder.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositUnderlying: E1");
                
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e21, "_testDepositUnderlying: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e21, "_testDepositUnderlying: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testHarvest(address _asset, uint256 _totalShare) internal {
        (,, address _crvRewards) = balancerCompounder.boosterData();
        assertTrue(IConvexBasicRewardsArbi(_crvRewards).rewards(address(balancerCompounder)) == 0, "_testHarvest: E1");
        
        // Fast forward 1 month
        skip(216000);

        uint256 _underlyingBefore = balancerCompounder.totalAssets();
        vm.prank(harvester);
        uint256 _newUnderlying = balancerCompounder.harvest(address(harvester), _asset, 0);

        assertTrue(ERC20(balancerCompounder.asset()).balanceOf(platform) > 0, "_testHarvest: E4");
        assertTrue(ERC20(balancerCompounder.asset()).balanceOf(harvester) > 0, "_testHarvest: E5");
        assertTrue(balancerCompounder.totalAssets() == (_underlyingBefore + _newUnderlying), "_testHarvest: E6");
        assertTrue(balancerCompounder.totalSupply() == _totalShare, "_testHarvest: E7");
    }

    function _testRedeemSingleUnwrapped(address _asset, uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        vm.prank(alice);
        uint256 _tokenOutAlice = balancerCompounder.redeemUnderlying(_asset, address(alice), address(alice), _sharesAlice, 0);
        assertApproxEqAbs(_tokenOutAlice, IERC20(_asset).balanceOf(address(alice)), 1e15, "_testRedeemSingleUnwrapped: E1");
        assertEq(balancerCompounder.balanceOf(address(alice)), 0, "_testRedeemSingleUnwrapped: E2");

        vm.prank(bob);
        uint256 _tokenOutBob = balancerCompounder.redeemUnderlying(_asset, address(bob), address(bob), _sharesBob, 0);
        assertApproxEqAbs(_tokenOutBob, IERC20(_asset).balanceOf(address(bob)), 1e15, "_testRedeemSingleUnwrapped: E3");
        assertEq(balancerCompounder.balanceOf(address(bob)), 0, "_testRedeemSingleUnwrapped: E4");

        vm.prank(charlie);
        uint256 _tokenOutCharlie = balancerCompounder.redeemUnderlying(_asset, address(charlie), address(charlie), _sharesCharlie, 0);
        assertApproxEqAbs(_tokenOutCharlie, IERC20(_asset).balanceOf(address(charlie)), 1e15, "_testRedeemSingleUnwrapped: E5");
        assertEq(balancerCompounder.balanceOf(address(charlie)), 0, "_testRedeemSingleUnwrapped: E6");

        assertEq(balancerCompounder.totalAssets(), 0, "_testRedeemSingleUnwrapped: E7");
        assertEq(balancerCompounder.totalSupply(), 0, "_testRedeemSingleUnwrapped: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e21, "_testRedeemSingleUnwrapped: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e21, "_testRedeemSingleUnwrapped: E10");
    }

    function _testDepositSingleUnwrappedETH(uint256 _amount) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        _sharesAlice = _depositSingleUnwrappedETH(alice, _amount);
        _sharesBob = _depositSingleUnwrappedETH(bob, _amount);
        _sharesCharlie = _depositSingleUnwrappedETH(charlie, _amount);
        
        assertEq(balancerCompounder.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositSingleUnwrappedETH: E1");
        (,, address _crvRewards) = balancerCompounder.boosterData();
        assertEq(balancerCompounder.totalAssets(), IConvexBasicRewardsArbi(_crvRewards).balanceOf(address(balancerCompounder)), "_testDepositSingleUnwrappedETH: E2");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e17, "_testDepositSingleUnwrappedETH: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e17, "_testDepositSingleUnwrappedETH: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testWithdrawLP(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        
        uint256 _lowestShare = _sharesAlice < _sharesBob ? _sharesAlice : _sharesBob;
        _lowestShare = _lowestShare < _sharesCharlie ? _lowestShare : _sharesCharlie;

        uint256 _dirtyTotalSupply = balancerCompounder.totalSupply() - (_lowestShare * 3);
        uint256 _dirtyTotalAssetsBefore = balancerCompounder.totalAssets();
        
        vm.startPrank(alice);
        uint256 _assetsAlice = balancerCompounder.previewRedeem(_lowestShare);
        uint256 _sharesBurnAlice = balancerCompounder.withdraw(_assetsAlice, address(alice), address(alice));
        vm.stopPrank();

        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(alice)), _assetsAlice, "_testWithdrawLP: E1");
        assertApproxEqAbs(_sharesBurnAlice, _lowestShare, 1e16, "_testWithdrawLP: E2");
        assertApproxEqAbs(balancerCompounder.balanceOf(address(alice)), _sharesAlice - _lowestShare, 1e16, "_testWithdrawLP: E3");
        
        vm.startPrank(bob);
        uint256 _assetsBob = balancerCompounder.previewRedeem(_lowestShare);
        uint256 _sharesBurnBob = balancerCompounder.withdraw(_assetsBob, address(bob), address(bob));
        vm.stopPrank();
        
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(bob)), _assetsBob, "_testWithdrawLP: E4");
        assertApproxEqAbs(_sharesBurnBob, _lowestShare, 1e16, "_testWithdrawLP: E5");
        assertApproxEqAbs(balancerCompounder.balanceOf(address(bob)), _sharesBob - _lowestShare, 1e16, "_testWithdrawLP: E6");
        
        vm.startPrank(charlie);
        uint256 _assetsCharlie = balancerCompounder.previewRedeem(_lowestShare);
        uint256 _sharesBurnCharlie = balancerCompounder.withdraw(_assetsCharlie, address(charlie), address(charlie));
        vm.stopPrank();
        
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie)), _assetsCharlie, "_testWithdrawLP: E7");
        assertApproxEqAbs(_sharesBurnCharlie, _lowestShare, 1e16, "_testWithdrawLP: E8");
        assertApproxEqAbs(balancerCompounder.balanceOf(address(charlie)), _sharesCharlie - _lowestShare, 1e16, "_testWithdrawLP: E9");
        
        uint256 _dirtyTotalAssets = _dirtyTotalAssetsBefore - (_assetsAlice + _assetsBob + _assetsCharlie);

        assertApproxEqAbs(balancerCompounder.totalAssets(), _dirtyTotalAssets, 1e16, "_testWithdrawLP: E10");
        assertApproxEqAbs(balancerCompounder.totalSupply(), _dirtyTotalSupply, 1e16, "_testWithdrawLP: E11");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnBob, 1e16, "_testWithdrawLP: E12");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnCharlie, 1e16, "_testWithdrawLP: E13");
    }

    function _testMintLP(uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie) internal {
        
        uint256 _lowestAsset = _assetsAlice < _assetsBob ? _assetsAlice : _assetsBob;
        _lowestAsset = _lowestAsset < _assetsCharlie ? _lowestAsset : _assetsCharlie;

        uint256 _dirtyTotalSupplyBefore = balancerCompounder.totalSupply();
        uint256 _dirtyTotalAssetsBefore = balancerCompounder.totalAssets();

        uint256 _sharesAlice = balancerCompounder.previewDeposit(_lowestAsset);
        vm.startPrank(alice);
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _lowestAsset);
        uint256 _assetsAliceSent = balancerCompounder.mint(_sharesAlice, address(alice));
        vm.stopPrank();
        
        assertEq(IERC20(address(balancerCompounder)).balanceOf(address(alice)), _sharesAlice, "_testMintLP: E3");
        assertEq(_assetsAliceSent, _lowestAsset, "_testMintLP: E04");

        uint256 _sharesBob = balancerCompounder.previewDeposit(_lowestAsset);
        vm.startPrank(bob);
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _lowestAsset);
        uint256 _assetsBobSent = balancerCompounder.mint(_sharesBob, address(bob));
        vm.stopPrank();
        
        assertEq(IERC20(address(balancerCompounder)).balanceOf(address(bob)), _sharesBob, "_testMintLP: E6");
        assertEq(_assetsBobSent, _lowestAsset, "_testMintLP: E07");

        uint256 _sharesCharlie = balancerCompounder.previewDeposit(_lowestAsset);
        vm.startPrank(charlie);
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _lowestAsset);
        uint256 _assetsCharlieSent = balancerCompounder.mint(_sharesCharlie, address(charlie));
        vm.stopPrank();

        assertEq(IERC20(address(balancerCompounder)).balanceOf(address(charlie)), _sharesCharlie, "_testMintLP: E9");
        assertEq(_assetsCharlieSent, _lowestAsset, "_testMintLP: E010");

        uint256 _dirtyTotalSupply = (_sharesCharlie + _sharesBob + _sharesAlice) - _dirtyTotalSupplyBefore;
        uint256 _dirtyTotalAssets = (_assetsCharlieSent + _assetsBobSent + _assetsAliceSent) - _dirtyTotalAssetsBefore;

        assertEq(balancerCompounder.totalAssets(), _dirtyTotalAssets, "_testMintLP: E11");
        assertEq(balancerCompounder.totalSupply(), _dirtyTotalSupply, "_testMintLP: E12");
        assertEq(_sharesAlice, _sharesBob, "_testMintLP: E13");
        assertEq(_assetsAliceSent, _assetsBobSent, "_testMintLP: E14");
        assertEq(_assetsBobSent, _assetsCharlieSent, "_testMintLP: E15");
    }

    function _testRedeemSingleUnwrappedETH(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        
        uint256 _before = address(alice).balance;
        vm.prank(alice);
        uint256 _tokenOutAlice = balancerCompounder.redeemUnderlying(ETH, address(alice), address(alice), _sharesAlice, 0);
        uint256 _after = address(alice).balance - _before;
        assertEq(_tokenOutAlice, _after, "_testRedeemSingleUnwrappedETH: E1");
        assertEq(balancerCompounder.balanceOf(address(alice)), 0, "_testRedeemSingleUnwrappedETH: E2");

        _before = address(bob).balance;
        vm.prank(bob);
        uint256 _tokenOutBob = balancerCompounder.redeemUnderlying(ETH, address(bob), address(bob), _sharesBob, 0);
        _after = address(bob).balance - _before;
        assertEq(_tokenOutBob, _after, "_testRedeemSingleUnwrappedETH: E3");
        assertEq(balancerCompounder.balanceOf(address(bob)), 0, "_testRedeemSingleUnwrappedETH: E4");

        _before = address(charlie).balance;
        vm.prank(charlie);
        uint256 _tokenOutCharlie = balancerCompounder.redeemUnderlying(ETH, address(charlie), address(charlie), _sharesCharlie, 0);
        _after = address(charlie).balance - _before;
        assertEq(_tokenOutCharlie, _after, "_testRedeemSingleUnwrappedETH: E5");
        assertEq(balancerCompounder.balanceOf(address(charlie)), 0, "_testRedeemSingleUnwrappedETH: E6");

        assertEq(balancerCompounder.totalAssets(), 0, "_testRedeemSingleUnwrappedETH: E7");
        assertEq(balancerCompounder.totalSupply(), 0, "_testRedeemSingleUnwrappedETH: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e17, "_testRedeemSingleUnwrappedETH: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e17, "_testRedeemSingleUnwrappedETH: E10");
    }

    function _testRedeem(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal returns (uint256 _tokenOutAlice, uint256 _tokenOutBob, uint256 _tokenOutCharlie) {

        vm.prank(alice);
        _tokenOutAlice = balancerCompounder.redeem(_sharesAlice, address(alice), address(alice));
        assertEq(_tokenOutAlice, IERC20(address(balancerCompounder.asset())).balanceOf(address(alice)), "_testRedeem: E1");
        assertEq(balancerCompounder.balanceOf(address(alice)), 0, "_testRedeem: E2");

        vm.prank(bob);
        _tokenOutBob = balancerCompounder.redeem(_sharesBob, address(bob), address(bob));
        assertEq(_tokenOutBob, IERC20(address(balancerCompounder.asset())).balanceOf(address(bob)), "_testRedeem: E3");
        assertEq(balancerCompounder.balanceOf(address(bob)), 0, "_testRedeem: E4");

        vm.prank(charlie);
        _tokenOutCharlie = balancerCompounder.redeem(_sharesCharlie, address(charlie), address(charlie));
        assertEq(_tokenOutCharlie, IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie)), "_testRedeem: E5");
        assertEq(balancerCompounder.balanceOf(address(charlie)), 0, "_testRedeem: E6");

        assertEq(balancerCompounder.totalAssets(), 0, "_testRedeem: E7");
        assertEq(balancerCompounder.totalSupply(), 0, "_testRedeem: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e21, "_testRedeem: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e21, "_testRedeem: E10");

        return (_tokenOutAlice, _tokenOutBob, _tokenOutCharlie);
    }

    function _testDepositLP(uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie) internal {
        vm.startPrank(alice);
        assertTrue(IERC20(address(balancerCompounder.asset())).balanceOf(address(alice)) > 0, "_testDepositLP: E1");
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assetsAlice);
        uint256 _sharesAlice = balancerCompounder.deposit(_assetsAlice, address(alice));
        vm.stopPrank();
        assertEq(balancerCompounder.balanceOf(address(alice)), _sharesAlice, "_testDepositLP: E2");
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(alice)), 0, "_testDepositLP: E3");

        vm.startPrank(bob);
        assertTrue(IERC20(address(balancerCompounder.asset())).balanceOf(address(bob)) > 0, "_testDepositLP: E4");
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assetsBob);
        uint256 _sharesBob = balancerCompounder.deposit(_assetsBob, address(bob));
        vm.stopPrank();
        assertEq(balancerCompounder.balanceOf(address(bob)), _sharesBob, "_testDepositLP: E5");
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(bob)), 0, "_testDepositLP: E6");

        vm.startPrank(charlie);
        assertTrue(IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie)) > 0, "_testDepositLP: E7");
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assetsCharlie);
        uint256 _sharesCharlie = balancerCompounder.deposit(_assetsCharlie, address(charlie));
        vm.stopPrank();
        assertEq(balancerCompounder.balanceOf(address(charlie)), _sharesCharlie, "_testDepositLP: E5");
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie)), 0, "_testDepositLP: E6");

        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e20, "_testDepositLP: E8");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e20, "_testDepositLP: E9");
        assertEq(balancerCompounder.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositLP: E10");
        assertEq(balancerCompounder.totalAssets(), (_assetsAlice + _assetsBob + _assetsCharlie), "_testDepositLP: E11");
    }

    function _testDepositCapInt(address _asset) internal {
        (, uint256 _depositCap, address _platform, address _swap,, address _owner,,) = balancerCompounder.settings();
        assertEq(_depositCap, 0, "_testDepositCap: E1");
        assertEq(_platform, address(platform), "_testDepositCap: E2");
        assertEq(_swap, address(fortressSwap), "_testDepositCap: E3");
        assertEq(_owner, address(owner), "_testDepositCap: E4");
        assertEq(balancerCompounder.maxDeposit(address(alice)), type(uint256).max, "_testDepositCap: E3");
        assertEq(balancerCompounder.maxMint(address(alice)), type(uint256).max, "_testDepositCap: E4");

        vm.startPrank(owner);
        balancerCompounder.updateSettings("temp", address(platform), address(fortressSwap), address(ammOperations), address(owner), balancerCompounder.totalSupply(), balancerCompounder.getUnderlyingAssets());
        vm.stopPrank();
        
        (, _depositCap, _platform, _swap,, _owner,,) = balancerCompounder.settings();
        assertEq(_depositCap, balancerCompounder.totalSupply(), "_testDepositCap: E2");
        assertEq(balancerCompounder.maxDeposit(address(alice)), 0, "_testDepositCap: E3");
        assertEq(balancerCompounder.maxMint(address(alice)), 0, "_testDepositCap: E4");

        uint256 _amount = 1 ether;
        uint256 _balance = _getAssetFromETH(alice, _asset, _amount);
        vm.startPrank(alice);
        IERC20(_asset).safeApprove(address(balancerCompounder), _balance);
        vm.expectRevert();
        balancerCompounder.depositUnderlying(_asset, address(alice), _balance, 0);
        vm.stopPrank();
    }

    function _testFortressRegistry() internal {
        assertEq(YieldOptimizersRegistry(yieldOptimizersRegistry).getAmmCompounderVault(false, address(balancerCompounder.asset())), address(balancerCompounder), "_testFortressRegistry: E1");
        assertEq(YieldOptimizersRegistry(yieldOptimizersRegistry).getAmmCompounderUnderlyingAssets(false, address(balancerCompounder.asset())), balancerCompounder.getUnderlyingAssets(), "_testFortressRegistry: E2");
    }

    function _wrapETH(address _owner, uint256 _amount) internal {
        vm.prank(_owner);
        IWETH(WETH).deposit{ value: _amount }();
    }

    function _dealERC20(address _token, address _recipient , uint256 _amount) internal {
        deal({ token: address(_token), to: _recipient, give: _amount});
    }
}