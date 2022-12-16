// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/mainnet/compounders/balancer/BalancerCompounder.sol";
import "src/mainnet/utils/FortressRegistry.sol";
import "script/mainnet/utils/AddRoutes.sol";
import "src/shared/interfaces/ERC20.sol";
import "src/shared/interfaces/IWETH.sol";

contract BalancerCompounderBaseTest is Test, AddRoutes {
    using SafeERC20 for IERC20;

    address owner;
    address alice;
    address bob;
    address charlie;
    address yossi;
    address harvester;
    address platform;

    uint256 mainnetFork;
    uint256 arbitrumFork;

    FortressRegistry fortressRegistry;
    BalancerCompounder balancerCompounder;
    FortressSwap fortressSwap;

    function _setUp() internal {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        
        owner = address(0x16cAD91E1928F994816EbC5e759d8562aAc65ab2);
        alice = address(0xFa0C696bC56AE0d256D34a307c447E80bf92Dd41);
        bob = address(0x864e4b0c28dF7E2f317FF339CebDB5224F47220e);
        charlie = address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc);
        yossi = address(0x77Ee01E3d0E05b4afF42105Fe004520421248261);
        platform = address(0x9cbD8440E5b8f116082a0F4B46802DB711592fAD);
        harvester = address(0xBF93B898E8Eee7dd6915735eB1ea9BFc4b98BEc0);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(yossi, 100 ether);
        vm.deal(harvester, 100 ether);

        fortressSwap = new FortressSwap(address(owner));

        vm.startPrank(owner);
        fortressRegistry = new FortressRegistry();
        addRoutes(address(fortressSwap));
        vm.stopPrank();
    }

    function _testSingleUnwrapped(address _asset, uint256 _amount) internal {
        
        // ------------ Get _asset ------------
        
        uint256 _underlyingAlice = _getAssetFromETH(alice, _asset, _amount);
        uint256 _underlyingBob = _getAssetFromETH(bob, _asset, _amount);
        uint256 _underlyingCharlie = _getAssetFromETH(charlie, _asset, _amount);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositSingleUnwrapped(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest(_asset, (_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Withdraw ------------
        require(_sharesAlice > 0, "Alice has no shares");
        require(_sharesBob > 0, "Bob has no shares");
        require(_sharesCharlie > 0, "Charlie has no shares");
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

    function _testMintLP(uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie) internal {
        uint256 _sharesAlice = balancerCompounder.previewDeposit(_assetsAlice);
        vm.startPrank(alice);
        uint256 _before = IERC20(address(balancerCompounder.asset())).balanceOf(address(alice));
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assetsAlice);
        _assetsAlice = balancerCompounder.mint(_sharesAlice, address(alice));
        vm.stopPrank();
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(alice)), 0, "_testMintLP: E2");
        assertEq(IERC20(address(balancerCompounder)).balanceOf(address(alice)), _sharesAlice, "_testMintLP: E3");
        assertEq(_before - _assetsAlice, 0, "_testMintLP: E4");

        uint256 _sharesBob = balancerCompounder.previewDeposit(_assetsBob);
        vm.startPrank(bob);
        _before = IERC20(address(balancerCompounder.asset())).balanceOf(address(bob));
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assetsBob);
        _assetsBob = balancerCompounder.mint(_sharesBob, address(bob));
        vm.stopPrank();
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(bob)), 0, "_testMintLP: E5");
        assertEq(IERC20(address(balancerCompounder)).balanceOf(address(bob)), _sharesBob, "_testMintLP: E6");
        assertEq(_before - _assetsBob, 0, "_testMintLP: E7");

        uint256 _sharesCharlie = balancerCompounder.previewDeposit(_assetsCharlie);
        vm.startPrank(charlie);
        _before = IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie));
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assetsCharlie);
        _assetsCharlie = balancerCompounder.mint(_sharesCharlie, address(charlie));
        vm.stopPrank();
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie)), 0, "_testMintLP: E8");
        assertEq(IERC20(address(balancerCompounder)).balanceOf(address(charlie)), _sharesCharlie, "_testMintLP: E9");
        assertEq(_before - _assetsCharlie, 0, "_testMintLP: E10");

        assertEq(balancerCompounder.totalAssets(), _assetsAlice + _assetsBob + _assetsCharlie, "_testMintLP: E11");
        assertEq(balancerCompounder.totalSupply(), _sharesAlice + _sharesBob + _sharesCharlie, "_testMintLP: E12");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e21, "_testMintLP: E13");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e21, "_testMintLP: E14");
    }

    function _testWithdrawLP(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        vm.startPrank(alice);
        uint256 _assets = balancerCompounder.previewRedeem(_sharesAlice);
        uint256 _sharesBurnAlice = balancerCompounder.withdraw(_assets, address(alice), address(alice));
        vm.stopPrank();
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(alice)), _assets, "_testWithdrawLP: E1");
        assertApproxEqAbs(_sharesBurnAlice, _sharesAlice, 1e17, "_testWithdrawLP: E2");
        assertApproxEqAbs(balancerCompounder.balanceOf(address(alice)), 0, 1e17, "_testWithdrawLP: E3");

        vm.startPrank(bob);
        _assets = balancerCompounder.previewRedeem(_sharesBob);
        uint256 _sharesBurnBob = balancerCompounder.withdraw(_assets, address(bob), address(bob));
        vm.stopPrank();
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(bob)), _assets, "_testWithdrawLP: E4");
        assertApproxEqAbs(_sharesBurnBob, _sharesBob, 1e17, "_testWithdrawLP: E5");
        assertApproxEqAbs(balancerCompounder.balanceOf(address(bob)), 0, 1e17, "_testWithdrawLP: E6");

        vm.startPrank(charlie);
        _assets = balancerCompounder.previewRedeem(_sharesCharlie);
        uint256 _sharesBurnCharlie = balancerCompounder.withdraw(_assets, address(charlie), address(charlie));
        vm.stopPrank();
        assertEq(IERC20(address(balancerCompounder.asset())).balanceOf(address(charlie)), _assets, "_testWithdrawLP: E7");
        assertApproxEqAbs(_sharesBurnCharlie, _sharesCharlie, 1e17, "_testWithdrawLP: E8");
        assertApproxEqAbs(balancerCompounder.balanceOf(address(charlie)), 0, 1e17, "_testWithdrawLP: E9");

        assertApproxEqAbs(balancerCompounder.totalAssets(), 0, 1e20, "_testWithdrawLP: E10");
        assertApproxEqAbs(balancerCompounder.totalSupply(), 0, 1e17, "_testWithdrawLP: E11");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnBob, 1e20, "_testWithdrawLP: E12");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnCharlie, 1e20, "_testWithdrawLP: E13");
    }

    function _testNoAssetsDeposit(uint256 _assets) internal {
        vm.startPrank(alice);
        IERC20(address(balancerCompounder.asset())).safeApprove(address(balancerCompounder), _assets);
        vm.expectRevert();
        balancerCompounder.deposit(_assets, address(alice));
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
        balancerCompounder.depositSingleUnderlying(_underlyingAlice, _asset, address(alice), 0);
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
        _share = balancerCompounder.depositSingleUnderlying(_amount, _asset, _owner, 0);
        vm.stopPrank();

        assertEq(_share, balancerCompounder.balanceOf(_owner), "_depositSingleUnwrapped: E1");
    }

    function _depositSingleUnwrappedETH(address _owner, uint256 _amount) internal returns (uint256 _share) {
        vm.startPrank(_owner);
        _share = balancerCompounder.depositSingleUnderlying{ value: _amount }(_amount, ETH, _owner, 0);
        vm.stopPrank();

        assertEq(_share, balancerCompounder.balanceOf(_owner), "_depositSingleUnwrapped: E1");
    }

    function _testDepositSingleUnwrapped(address _asset, uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        _sharesAlice = _depositSingleUnwrapped(alice, _asset, _underlyingAlice);
        _sharesBob = _depositSingleUnwrapped(bob, _asset, _underlyingBob);
        _sharesCharlie = _depositSingleUnwrapped(charlie, _asset, _underlyingCharlie);
        
        assertEq(balancerCompounder.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositUnderlying: E1");
        // (,,,,,address crvRewards,,) = balancerCompounder.poolInfo();
        assertEq(balancerCompounder.totalAssets(), IConvexBasicRewards(balancerCompounder.crvRewards()).balanceOf(address(balancerCompounder)), "_testDepositUnderlying: E2");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e20, "_testDepositUnderlying: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e20, "_testDepositUnderlying: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testHarvest(address _asset, uint256 _totalShare) internal {
        // (,,,,,address crvRewards,,) = balancerCompounder.poolInfo();
        assertTrue(IConvexBasicRewards(balancerCompounder.crvRewards()).earned(address(balancerCompounder)) == 0, "_testHarvest: E1");

        // Fast forward 1 month
        skip(216000);

        assertTrue(IConvexBasicRewards(balancerCompounder.crvRewards()).earned(address(balancerCompounder)) > 0, "_testHarvest: E2");
        
        uint256 _underlyingBefore = balancerCompounder.totalAssets();
        vm.prank(harvester);
        uint256 _newUnderlying = balancerCompounder.harvest(address(harvester), _asset, 0);

        assertTrue(IConvexBasicRewards(balancerCompounder.crvRewards()).earned(address(balancerCompounder)) == 0, "_testHarvest: E3");
        assertTrue(ERC20(balancerCompounder.asset()).balanceOf(platform) > 0, "_testHarvest: E4");
        assertTrue(ERC20(balancerCompounder.asset()).balanceOf(harvester) > 0, "_testHarvest: E5");
        assertTrue(balancerCompounder.totalAssets() == (_underlyingBefore + _newUnderlying), "_testHarvest: E6");
        assertTrue(balancerCompounder.totalSupply() == _totalShare, "_testHarvest: E7");
    }

    function _testRedeemSingleUnwrapped(address _asset, uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        vm.prank(alice);
        uint256 _tokenOutAlice = balancerCompounder.redeemSingleUnderlying(_sharesAlice, _asset, address(alice), address(alice), 0);
        assertEq(_tokenOutAlice, IERC20(_asset).balanceOf(address(alice)), "_testRedeemSingleUnwrapped: E1");
        assertEq(balancerCompounder.balanceOf(address(alice)), 0, "_testRedeemSingleUnwrapped: E2");

        vm.prank(bob);
        uint256 _tokenOutBob = balancerCompounder.redeemSingleUnderlying(_sharesBob, _asset, address(bob), address(bob), 0);
        assertEq(_tokenOutBob, IERC20(_asset).balanceOf(address(bob)), "_testRedeemSingleUnwrapped: E3");
        assertEq(balancerCompounder.balanceOf(address(bob)), 0, "_testRedeemSingleUnwrapped: E4");

        vm.prank(charlie);
        uint256 _tokenOutCharlie = balancerCompounder.redeemSingleUnderlying(_sharesCharlie, _asset, address(charlie), address(charlie), 0);
        assertEq(_tokenOutCharlie, IERC20(_asset).balanceOf(address(charlie)), "_testRedeemSingleUnwrapped: E5");
        assertEq(balancerCompounder.balanceOf(address(charlie)), 0, "_testRedeemSingleUnwrapped: E6");

        assertEq(balancerCompounder.totalAssets(), 0, "_testRedeemSingleUnwrapped: E7");
        assertEq(balancerCompounder.totalSupply(), 0, "_testRedeemSingleUnwrapped: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e20, "_testRedeemSingleUnwrapped: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e20, "_testRedeemSingleUnwrapped: E10");
    }

    function _testDepositSingleUnwrappedETH(uint256 _amount) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        _sharesAlice = _depositSingleUnwrappedETH(alice, _amount);
        _sharesBob = _depositSingleUnwrappedETH(bob, _amount);
        _sharesCharlie = _depositSingleUnwrappedETH(charlie, _amount);
        
        assertEq(balancerCompounder.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositSingleUnwrappedETH: E1");
        // (,,,,,address crvRewards,,) = balancerCompounder.poolInfo();
        assertEq(balancerCompounder.totalAssets(), IConvexBasicRewards(balancerCompounder.crvRewards()).balanceOf(address(balancerCompounder)), "_testDepositSingleUnwrappedETH: E2");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e17, "_testDepositSingleUnwrappedETH: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e17, "_testDepositSingleUnwrappedETH: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }

    function _testRedeemSingleUnwrappedETH(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        
        uint256 _before = address(alice).balance;
        vm.prank(alice);
        uint256 _tokenOutAlice = balancerCompounder.redeemSingleUnderlying(_sharesAlice, ETH, address(alice), address(alice), 0);
        uint256 _after = address(alice).balance - _before;
        assertEq(_tokenOutAlice, _after, "_testRedeemSingleUnwrappedETH: E1");
        assertEq(balancerCompounder.balanceOf(address(alice)), 0, "_testRedeemSingleUnwrappedETH: E2");

        _before = address(bob).balance;
        vm.prank(bob);
        uint256 _tokenOutBob = balancerCompounder.redeemSingleUnderlying(_sharesBob, ETH, address(bob), address(bob), 0);
        _after = address(bob).balance - _before;
        assertEq(_tokenOutBob, _after, "_testRedeemSingleUnwrappedETH: E3");
        assertEq(balancerCompounder.balanceOf(address(bob)), 0, "_testRedeemSingleUnwrappedETH: E4");

        _before = address(charlie).balance;
        vm.prank(charlie);
        uint256 _tokenOutCharlie = balancerCompounder.redeemSingleUnderlying(_sharesCharlie, ETH, address(charlie), address(charlie), 0);
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
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e20, "_testRedeem: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e20, "_testRedeem: E10");

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

    function _testFortressRegistry() internal {
        assertEq(fortressRegistry.getBalancerCompounder(address(balancerCompounder.asset())), address(balancerCompounder), "_testFortressRegistry: E1");
        assertEq(fortressRegistry.getBalancerCompounderUnderlyingAssets(address(balancerCompounder.asset())), balancerCompounder.getUnderlyingAssets(), "_testFortressRegistry: E2");
    }

    function _wrapETH(address _owner, uint256 _amount) internal {
        vm.prank(_owner);
        IWETH(WETH).deposit{ value: _amount }();
    }

    function _unwrapETH(uint256 _amount) internal {
        IWETH(WETH).withdraw(_amount);
    }
}