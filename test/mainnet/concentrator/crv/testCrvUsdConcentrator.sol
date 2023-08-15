// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CrvUsdConcentrator} from "src/mainnet/crv-concentrator/CrvUSDConcentrator.sol";
import {BaseTest, SafeERC20, IERC20} from "test/arbitrum/concentrators/BaseTest.sol";
import {FortressSwap} from "src/mainnet/utils/FortressSwap.sol";
import "src/shared/interfaces/ERC20.sol";

contract TestCrvUsdConcentrator is BaseTest {

    using SafeERC20 for IERC20;

    CrvUsdConcentrator concentrator;
    FortressSwap _fortressSwap;

    address constant _STYCRV = 0x27B5739e22ad9033bcBf192059122d163b60349D;
    address constant _YCRV = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b;
    address constant _CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant _CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E; 

    function setUp() public {
        
        // --------------------------------- set env ---------------------------------
        
        string memory MAINNET_RPC_URL = "https://mainnet.infura.io/v3/3420f721c3d8404d8d7ce9dd6fec61d5";//vm.envString("MAINNET_RPC_URL");
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        
        // --------------------------------- set accounts ---------------------------------
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

        vm.startPrank(owner);
        
        _fortressSwap = new FortressSwap(payable(owner));
        _addSwapRoutes();

        address[] memory _underlyingAssets2 = new address[](2);

        address asset = _STYCRV;
        string memory symbol = "ST-YCRV-crvUSD";
        string memory name = "Fortress ST-YCRV Concentrating to crvUSD";
        _underlyingAssets2[0] = _CRV;
        _underlyingAssets2[1] = _YCRV;
        string memory curveCryptoDescription = "Curve,Crypto";

        bytes memory _settingsConfig = abi.encode(curveCryptoDescription, address(owner), address(platform), address(_fortressSwap));
        concentrator = new CrvUsdConcentrator(ERC20(asset), name, symbol, _settingsConfig, _underlyingAssets2);

        vm.stopPrank();
    }

    function testCorrectFlowCRV(uint256 _amount) public {
        _testCorrectFlow(_CRV, _amount);
    }

    function testCorrectFlowYCRV(uint256 _amount) public {
        _testCorrectFlow(_YCRV, _amount);
    }

    function testDepositCap(uint256 _amount) public {
        _testDepositCap(_CRV, _amount);
    }

    function testMint(uint256 _amount) public {
        _testMint(_YCRV, _amount);
    }

    function testWithdraw(uint256 _amount) public {
        _testWithdraw(_YCRV, _amount);
    }

    function testTransfer(uint256 _amount) public {
        _testCorrectFlowTransfer(_YCRV, _amount);
    }

    function testDepositNoAsset(uint256 _amount) public {
        _testDepositNoAsset(_amount, _CRV);
    }

    function testDepositWrongAsset(uint256 _amount) public {
        _testDepositWrongAsset(_amount, _CRVUSD);
    }

    function testWithdrawNoShare(uint256 _amount) public {
        _testWithdrawNoShare(_amount, _CRV);
    }    
    
    function _testCorrectFlow(address _asset, uint256 _amount) public {
        vm.assume(_amount > 0.1 ether && _amount < 5 ether);
    
        // ------------ Get _asset ------------

        _dealERC20(address(_asset), alice, _amount);
        _dealERC20(address(_asset), bob, _amount);
        _dealERC20(address(_asset), charlie, _amount);

        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        uint256 _underlyingBob = ERC20(_asset).balanceOf(bob);
        uint256 _underlyingCharlie = ERC20(_asset).balanceOf(charlie);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

        assertEq(concentrator.totalAssets(), ERC20(_STYCRV).balanceOf(address(concentrator)), "_testCorrectFlow:_testHarvest: E1");

        // ------------ Withdraw ------------
        
        (uint256 _tokenOutAlice, uint256 _tokenOutBob, uint256 _tokenOutCharlie) = _testRedeemUnderlying(_asset, _sharesAlice, _sharesBob, _sharesCharlie);

        assertApproxEqAbs((_underlyingAlice + _underlyingBob + _underlyingCharlie), (_tokenOutAlice + _tokenOutBob + _tokenOutCharlie), 1e20, "_testCorrectFlow: E1");
        assertApproxEqAbs(_underlyingAlice, _tokenOutAlice,  1e17, "_testCorrectFlow: E2");
        assertApproxEqAbs(_underlyingBob, _tokenOutBob,  1e17,"_testCorrectFlow: E3");
        assertApproxEqAbs(_underlyingCharlie, _tokenOutCharlie,   1e17, "_testCorrectFlow: E4");

        // ------------ Claim ------------

        _testClaim();
    }

    function _testCorrectFlowTransfer(address _asset, uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        _dealERC20(address(_asset), alice, _amount);
        _dealERC20(address(_asset), bob, _amount);
        _dealERC20(address(_asset), charlie, _amount);

        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        uint256 _underlyingBob = ERC20(_asset).balanceOf(bob);
        uint256 _underlyingCharlie = ERC20(_asset).balanceOf(charlie);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest rewards ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Transfer ------------
        
        _testTransfer();

        // ------------ Claim ------------

        _testClaim();
    }

    function _testDepositUnderlying(address _asset, uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        
        assertEq(concentrator.totalCRV(), 0 , "_depositSingleUnderlyingAsset: E0");

        _sharesAlice = _depositSingleUnderlyingAsset(alice, _asset, _underlyingAlice, address(concentrator));
        _sharesBob = _depositSingleUnderlyingAsset(bob, _asset, _underlyingBob, address(concentrator));
        _sharesCharlie = _depositSingleUnderlyingAsset(charlie, _asset, _underlyingCharlie, address(concentrator));
        
        assertEq(concentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testDepositUnderlying: E1");
        assertEq((_underlyingAlice + _underlyingBob + _underlyingCharlie), concentrator.totalCRV(), "_testDepositUnderlying: E2");
        assertApproxEqAbs(_sharesAlice, _sharesBob, 1e20, "_testDepositUnderlying: E3");
        assertApproxEqAbs(_sharesAlice, _sharesCharlie, 1e20, "_testDepositUnderlying: E4");

        return (_sharesAlice, _sharesBob, _sharesCharlie);
    }
    
    function _depositSingleUnderlyingAsset(address _owner, address _asset, uint256 _amount, address _concentrator) internal returns (uint256 _share) {

        vm.startPrank(_owner);

        uint256 _shareBefore = concentrator.totalSupply();
        
        if (_asset != ETH) {
            IERC20(_asset).safeApprove(address(_concentrator), _amount);
            _share = concentrator.depositUnderlying(_asset, _owner, _amount);
        } else {
            _share = concentrator.depositUnderlying{value: _amount}(_asset, _owner, _amount);
        }
        vm.stopPrank();

        uint256 _totalShare = _shareBefore + _share;

        assertEq(_share, concentrator.balanceOf(_owner), "_depositSingleUnderlyingAsset: E1");
        assertEq(_share, IERC20(_concentrator).balanceOf(_owner), "_depositSingleUnderlyingAsset: E2");
        assertEq(concentrator.totalSupply(), _totalShare, "_depositSingleUnderlyingAsset: E3");
    }

    function _testHarvest(uint256 _totalShare) internal {
        
        assertEq(concentrator.pendingReward(address(alice)), 0, "_testHarvest: E1");
        assertEq(concentrator.pendingReward(address(bob)), 0, "_testHarvest: E2");
        assertEq(concentrator.pendingReward(address(charlie)), 0, "_testHarvest: E3");
        assertEq(concentrator.accRewardPerShare(), 0, "_testHarvest: E4");
        assertTrue(concentrator.totalAssets() > 0, "_testHarvest: E04");

        // Fast forward 1 month
        skip(216000);

        uint256 _assetsBefore = concentrator.totalAssets();
        uint256 _rewardsBefore = IERC20(_CRVUSD).balanceOf(address(concentrator));
        vm.prank(harvester);
        uint256 _newUnderlying = concentrator.harvest(address(harvester), 0);

        assertTrue(concentrator.pendingReward(address(alice)) > 0, "_testHarvest: E001");
        assertTrue(concentrator.pendingReward(address(bob)) > 0, "_testHarvest: E02");
        assertTrue(concentrator.pendingReward(address(charlie)) > 0, "_testHarvest: E03");
        assertTrue(concentrator.accRewardPerShare() > 0, "_testHarvest: E04");
        
        address _rewardAsset = address(_YCRV);
        assertTrue(IERC20(_rewardAsset).balanceOf(platform) > 0, "_testHarvest: E4");
        assertTrue(IERC20(_rewardAsset).balanceOf(harvester) > 0, "_testHarvest: E5");
        assertTrue(concentrator.totalAssets() < _assetsBefore, "_testHarvest: E6");
        assertEq(concentrator.totalSupply(), _totalShare, "_testHarvest: E7");
        assertEq((IERC20(_CRVUSD).balanceOf(address(concentrator)) - _rewardsBefore), _newUnderlying, "_testHarvest: E8");
        assertTrue(_newUnderlying > 0, "_testHarvest: E9");
        assertApproxEqAbs(concentrator.pendingReward(address(alice)) , concentrator.pendingReward(address(bob)), 1e17, "_testHarvest: E10");
        assertApproxEqAbs(concentrator.pendingReward(address(alice)) , concentrator.pendingReward(address(charlie)), 1e17, "_testHarvest: E11");
    }
    
    function _testRedeemUnderlying(address _asset, uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal returns (uint256 _tokenOutAlice, uint256 _tokenOutBob, uint256 _tokenOutCharlie) {

        assertEq(concentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testRedeemUnderlying: E01");
        assertEq(concentrator.totalAssets(), concentrator.previewRedeem(_sharesCharlie + _sharesBob+ _sharesAlice), "_testRedeemUnderlying: EXTRA01");

        uint256 _balanceBefore = address(alice).balance;
        vm.prank(alice);
        _tokenOutAlice = concentrator.redeemUnderlying(_asset, address(alice), address(alice), _sharesAlice, 0);

        if (_asset == ETH) {
            assertEq(_tokenOutAlice, address(alice).balance - _balanceBefore, "_testWithdrawUnderlying: E01");
        } else {
            assertEq(_tokenOutAlice, IERC20(_asset).balanceOf(address(alice)), "_testWithdrawUnderlying: E1");
        }
        
        assertEq(concentrator.balanceOf(address(alice)), 0, "_testWithdrawUnderlying: E2");
        assertEq(concentrator.totalSupply(), (_sharesBob + _sharesCharlie), "_testRedeemUnderlying: E02");
        assertEq(concentrator.totalAssets(), concentrator.previewRedeem(_sharesCharlie + _sharesBob), "_testRedeemUnderlying: EXTRA02");
        _balanceBefore = address(bob).balance;
        vm.prank(bob);
        _tokenOutBob = concentrator.redeemUnderlying(_asset, address(bob), address(bob), _sharesBob, 0);
        
        if (_asset == ETH) {
            assertEq(_tokenOutBob, address(bob).balance - _balanceBefore, "_testWithdrawUnderlying: E03");
        } else {
            assertEq(_tokenOutBob, IERC20(_asset).balanceOf(address(bob)), "_testWithdrawUnderlying: E3");
        }

        assertEq(concentrator.balanceOf(address(bob)), 0, "_testWithdrawUnderlying: E4");
        assertEq(concentrator.totalSupply(), _sharesCharlie, "_testRedeemUnderlying: E04");
        assertEq(concentrator.balanceOf(address(charlie)), _sharesCharlie, "_testRedeemUnderlying: EXTRA1");
        assertEq(concentrator.totalAssets(), concentrator.previewRedeem(_sharesCharlie), "_testRedeemUnderlying: EXTRA03");

        _balanceBefore = address(charlie).balance;

        vm.prank(charlie);
        _tokenOutCharlie = concentrator.redeemUnderlying(_asset, address(charlie), address(charlie), _sharesCharlie, 0);
        
        if (_asset == ETH) {
            assertEq(_tokenOutCharlie, address(charlie).balance - _balanceBefore, "_testWithdrawUnderlying: E005");
        } else {
            assertEq(_tokenOutCharlie, IERC20(_asset).balanceOf(address(charlie)), "_testWithdrawUnderlying: E05");
        }

        assertEq(concentrator.balanceOf(address(charlie)), 0, "_testWithdrawUnderlying: E6");

        assertEq(concentrator.totalAssets(), 0, "_testWithdrawUnderlying: E7");
        assertEq(concentrator.totalSupply(), 0, "_testWithdrawUnderlying: E8");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutBob, 1e20, "_testWithdrawUnderlying: E9");
        assertApproxEqAbs(_tokenOutAlice, _tokenOutCharlie, 1e20, "_testWithdrawUnderlying: E10");

        return (_tokenOutAlice, _tokenOutBob, _tokenOutCharlie);
    }
    
    function _testClaim() internal {
        
        assertEq(IERC20(_CRVUSD).balanceOf(address(alice)), 0, "_testClaim: E01");
        assertEq(IERC20(_CRVUSD).balanceOf(address(bob)), 0, "_testClaim: E02");
        assertEq(IERC20(_CRVUSD).balanceOf(address(charlie)), 0, "_testClaim: E03");
        assertTrue(concentrator.accRewardPerShare() > 0, "_testClaim: E004");
        assertTrue(concentrator.pendingReward(address(alice)) > 0, "_testClaim: E04");
        assertTrue(concentrator.pendingReward(address(bob)) > 0, "_testClaim: E05");
        assertTrue(concentrator.pendingReward(address(charlie)) > 0, "_testClaim: E06");
        assertTrue(IERC20(_CRVUSD).balanceOf(address(concentrator)) > 0, "_testClaim: E006");
        
        uint256 _totalRewards = IERC20(_CRVUSD).balanceOf(address(concentrator));
        
        vm.prank(alice);
        uint256 _rewardsOutAlice = concentrator.claim(address(0), address(alice));
        _totalRewards -= _rewardsOutAlice;

        assertEq(_rewardsOutAlice, IERC20(_CRVUSD).balanceOf(address(alice)), "_testClaim: E1");
        assertEq(concentrator.pendingReward(address(alice)), 0, "_testClaim: E2");
        assertEq(IERC20(_CRVUSD).balanceOf(address(concentrator)), _totalRewards, "_testClaim: E007");

        vm.prank(bob);
        uint256 _rewardsOutBob = concentrator.claim(address(0), address(bob));
        _totalRewards -= _rewardsOutBob;

        assertApproxEqAbs(_rewardsOutBob, IERC20(_CRVUSD).balanceOf(address(alice)), 1e17, "_testClaim: E3");
        assertEq(concentrator.pendingReward(address(bob)), 0, "_testClaim: E4");
        assertEq(IERC20(_CRVUSD).balanceOf(address(concentrator)), _totalRewards, "_testClaim: E004");

        vm.prank(charlie);
        uint256 _rewardsOutCharlie = concentrator.claim(address(0), address(charlie));
        _totalRewards -= _rewardsOutCharlie;

        assertApproxEqAbs(_rewardsOutCharlie, IERC20(_CRVUSD).balanceOf(address(alice)), 1e17, "_testClaim: E5");
        assertEq(concentrator.pendingReward(address(charlie)), 0, "_testClaim: E6");
        assertEq(IERC20(_CRVUSD).balanceOf(address(concentrator)), _totalRewards, "_testClaim: E006");

        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutBob, 1e19, "_testClaim: E7");
        assertApproxEqAbs(_rewardsOutAlice, _rewardsOutCharlie, 1e19, "_testClaim: E8");
        assertApproxEqAbs(IERC20(_CRVUSD).balanceOf(address(concentrator)), 0, 1e10, "_testClaim: E008");
    }

    function _testDepositCap(address _asset, uint256 _amount) internal {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        _dealERC20(address(_asset), alice, _amount);
        _dealERC20(address(_asset), bob, _amount);
        _dealERC20(address(_asset), charlie, _amount);

        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        uint256 _underlyingBob = ERC20(_asset).balanceOf(bob);
        uint256 _underlyingCharlie = ERC20(_asset).balanceOf(charlie);

        // ------------ Deposit ------------

        _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest ------------
        
        // Fast forward 1 month
        skip(216000);

        vm.prank(harvester);
        concentrator.harvest(address(harvester), 0);

        // ------------ Deposit Cap ------------

        _testDepositCapInt(_asset);
    }

    function _testDepositCapInt(address _asset) internal {
        (, uint256 _depositCap, address _platform, address _swap, address _owner,,,) = concentrator.settings();

        assertEq(_depositCap, 0, "_testDepositCap: E1");
        assertEq(_platform, address(platform), "_testDepositCap: E2");
        assertEq(_swap, address(_fortressSwap), "_testDepositCap: E3");
        assertEq(_owner, address(owner), "_testDepositCap: E4");
        assertEq(concentrator.maxDeposit(address(alice)), type(uint256).max, "_testDepositCap: E5");
        assertEq(concentrator.maxMint(address(alice)), type(uint256).max, "_testDepositCap: E6");

        vm.startPrank(owner);
        concentrator.updateSettings(address(platform), address(fortressSwap), address(owner), concentrator.totalSupply(), concentrator.getUnderlyingAssets());
        vm.stopPrank();
        
        (, _depositCap,,,,,,) = concentrator.settings();
        assertEq(_depositCap, concentrator.totalSupply(), "_testDepositCap: E7");
        assertEq(concentrator.maxDeposit(address(alice)), 0, "_testDepositCap: E8");
        assertEq(concentrator.maxMint(address(alice)), 0, "_testDepositCap: E9");

        uint256 _amount = 1 ether;
        _dealERC20(address(_asset), alice, _amount);
        vm.startPrank(alice);
        IERC20(_asset).safeApprove(address(concentrator), _amount);
        vm.expectRevert();
        concentrator.depositUnderlying(_asset, address(alice), _amount);
        vm.stopPrank();
    } 

    function _testTransfer() internal {

        uint256 _sharesAlice = concentrator.balanceOf(address(alice));
        uint256 _sharesBob = concentrator.balanceOf(address(bob));
        uint256 _sharesCharlie = concentrator.balanceOf(address(charlie));

        assertEq(concentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testTransfer: E01");

        vm.prank(alice);
        concentrator.transfer(address(yossi), _sharesAlice);
        vm.prank(bob);
        concentrator.transfer(address(yossi), _sharesBob);
        vm.prank(charlie);
        concentrator.transfer(address(yossi), _sharesCharlie);

        assertEq(concentrator.balanceOf(address(alice)), 0, "_testTransfer: E1");
        assertEq(concentrator.balanceOf(address(bob)), 0, "_testTransfer: E2");
        assertEq(concentrator.balanceOf(address(charlie)), 0, "_testTransfer: E3");
        assertEq(concentrator.totalSupply(), (_sharesAlice + _sharesBob + _sharesCharlie), "_testTransfer: E04");
        assertEq(concentrator.balanceOf(address(yossi)), (_sharesAlice + _sharesBob + _sharesCharlie), "_testTransfer: E05");
    }

    function _testMint(address _asset, uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        _dealERC20(address(_asset), alice, _amount);
        _dealERC20(address(_asset), bob, _amount);
        _dealERC20(address(_asset), charlie, _amount);

        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        uint256 _underlyingBob = ERC20(_asset).balanceOf(bob);
        uint256 _underlyingCharlie = ERC20(_asset).balanceOf(charlie);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Redeem ------------

        (_underlyingAlice, _underlyingBob, _underlyingCharlie) = _testRedeemInt(_sharesAlice, _sharesBob, _sharesCharlie); 

        // ------------ Mint ------------

        (_sharesAlice, _sharesBob, _sharesCharlie) = _testMintInt(_underlyingAlice, _underlyingBob, _underlyingCharlie);
        
        // ------------ Harvest rewards ------------

         _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

        // // ------------ Withdraw ------------
        
        _testRedeemUnderlying(_asset, _sharesAlice, _sharesBob, _sharesCharlie);

        // // ------------ Claim ------------

        _testClaim();
    }

    function _testWithdraw(address _asset, uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        // ------------ Get _asset ------------
        
        _dealERC20(address(_asset), alice, _amount);
        _dealERC20(address(_asset), bob, _amount);
        _dealERC20(address(_asset), charlie, _amount);

        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        uint256 _underlyingBob = ERC20(_asset).balanceOf(bob);
        uint256 _underlyingCharlie = ERC20(_asset).balanceOf(charlie);

        // ------------ Deposit ------------

        (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) = _testDepositUnderlying(_asset, _underlyingAlice, _underlyingBob, _underlyingCharlie);

        // ------------ Harvest ------------

        _testHarvest((_sharesAlice + _sharesBob + _sharesCharlie));

        // ------------ Withdraw ------------

        _testWithdrawInt(_sharesAlice, _sharesBob, _sharesCharlie);

        // ------------ Claim ------------

        _testClaim();
    }
   
    function _testRedeemInt(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal returns (uint256 _underlyingAlice, uint256 _underlyingBob, uint256 _underlyingCharlie) {
        
        uint256 _totalSupplyBefore = concentrator.totalSupply();
        uint256 _totalAssetsBefore = concentrator.totalAssets();

        uint256 _assetsAlice = concentrator.previewRedeem(_sharesAlice);
        vm.startPrank(alice);
        _underlyingAlice = concentrator.redeem(_sharesAlice, address(alice), address(alice));
        _totalSupplyBefore -= _sharesAlice;
        _totalAssetsBefore -= _assetsAlice;
        vm.stopPrank();
        
        assertEq(_underlyingAlice, IERC20(address(concentrator.asset())).balanceOf(address(alice)), "_testRedeemInt: E03");
        assertEq(_underlyingAlice, _assetsAlice, "_testRedeemInt: E04");
        assertEq(concentrator.totalAssets(), _totalAssetsBefore, "_testRedeemInt: E05");
        assertEq(concentrator.totalSupply(), _totalSupplyBefore, "_testRedeemInt: E06");

        uint256 _assetsBob = concentrator.previewRedeem(_sharesBob);
        vm.startPrank(bob);
        _underlyingBob = concentrator.redeem(_sharesBob, address(bob), address(bob));
        _totalSupplyBefore -= _sharesBob;
        _totalAssetsBefore -= _assetsBob;
        vm.stopPrank();
        
        assertEq(IERC20(address(concentrator)).balanceOf(address(bob)), 0, "_testRedeemInt: E6");
        assertEq(_underlyingBob, _assetsBob, "_testRedeemInt: E07");
        assertEq(concentrator.totalAssets(), _totalAssetsBefore, "_testRedeemInt: E08");
        assertEq(concentrator.totalSupply(), _totalSupplyBefore, "_testRedeemInt: E09");
        assertEq(_underlyingBob, IERC20(address(concentrator.asset())).balanceOf(address(bob)), "_testRedeemInt: E03");


        uint256 _assetsCharlie = concentrator.previewRedeem(_sharesCharlie);
        vm.startPrank(charlie);
        _underlyingCharlie = concentrator.redeem(_sharesCharlie, address(charlie), address(charlie));
        _totalSupplyBefore -= _sharesCharlie;
        _totalAssetsBefore -= _assetsCharlie;
        vm.stopPrank();

        assertEq(IERC20(address(concentrator)).balanceOf(address(charlie)), 0, "_testRedeemInt: E9");
        assertEq(_assetsCharlie, _underlyingCharlie, "_testRedeemInt: E010");
        assertEq(concentrator.totalAssets(), _totalAssetsBefore, "_testRedeemInt: E011");
        assertEq(concentrator.totalSupply(), _totalSupplyBefore, "_testRedeemInt: E012");
        assertEq(_underlyingCharlie, IERC20(address(concentrator.asset())).balanceOf(address(charlie)), "_testRedeemInt: E03");

        assertEq(concentrator.totalAssets(), 0, "_testRedeemInt: E013");
        assertEq(concentrator.totalSupply(), 0, "_testRedeemInt: E014");
    }
   
    function _testMintInt(uint256 _assetsAlice, uint256 _assetsBob, uint256 _assetsCharlie) internal returns (uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) {
        
        uint256 _lowestAsset = _assetsAlice < _assetsBob ? _assetsAlice : _assetsBob;
        _lowestAsset = _lowestAsset < _assetsCharlie ? _lowestAsset : _assetsCharlie;

        uint256 _dirtyTotalSupplyBefore = concentrator.totalSupply();
        uint256 _dirtyTotalAssetsBefore = concentrator.totalAssets();

        _sharesAlice = concentrator.previewDeposit(_lowestAsset);
        assertEq(_sharesAlice, _lowestAsset, "_testMint: E01");
        vm.startPrank(alice);
        IERC20(address(concentrator.asset())).safeApprove(address(concentrator), _lowestAsset);
        uint256 _assetsAliceSent = concentrator.mint(_sharesAlice, address(alice));
        vm.stopPrank();
        
        assertEq(IERC20(address(concentrator)).balanceOf(address(alice)), _sharesAlice, "_testMintLP: E3");
        assertEq(_assetsAliceSent, _lowestAsset, "_testMintLP: E04");

        _sharesBob = concentrator.previewDeposit(_lowestAsset);
        assertEq(_sharesBob, _lowestAsset, "_testMint: E01");
        vm.startPrank(bob);
        IERC20(address(concentrator.asset())).safeApprove(address(concentrator), _lowestAsset);
        uint256 _assetsBobSent = concentrator.mint(_sharesBob, address(bob));
        vm.stopPrank();
        
        assertEq(IERC20(address(concentrator)).balanceOf(address(bob)), _sharesBob, "_testMintLP: E6");
        assertEq(_assetsBobSent, _lowestAsset, "_testMintLP: E07");

        _sharesCharlie = concentrator.previewDeposit(_lowestAsset);
        assertEq(_sharesCharlie, _lowestAsset, "_testMint: E01");
        vm.startPrank(charlie);
        IERC20(address(concentrator.asset())).safeApprove(address(concentrator), _lowestAsset);
        uint256 _assetsCharlieSent = concentrator.mint(_sharesCharlie, address(charlie));
        vm.stopPrank();

        assertEq(IERC20(address(concentrator)).balanceOf(address(charlie)), _sharesCharlie, "_testMintLP: E9");
        assertEq(_assetsCharlieSent, _lowestAsset, "_testMintLP: E010");

        uint256 _dirtyTotalSupply = (_sharesCharlie + _sharesBob + _sharesAlice) - _dirtyTotalSupplyBefore;
        uint256 _dirtyTotalAssets = (_assetsCharlieSent + _assetsBobSent + _assetsAliceSent) - _dirtyTotalAssetsBefore;

        assertEq(concentrator.totalAssets(), _dirtyTotalAssets, "_testMintLP: E11");
        assertEq(concentrator.totalSupply(), _dirtyTotalSupply, "_testMintLP: E12");
        assertEq(_sharesAlice, _sharesBob, "_testMintLP: E13");
        assertEq(_assetsAliceSent, _assetsBobSent, "_testMintLP: E14");
        assertEq(_assetsBobSent, _assetsCharlieSent, "_testMintLP: E15");
    }
   
    function _testWithdrawInt(uint256 _sharesAlice, uint256 _sharesBob, uint256 _sharesCharlie) internal {
        
        uint256 _lowestShare = _sharesAlice < _sharesBob ? _sharesAlice : _sharesBob;
        _lowestShare = _lowestShare < _sharesCharlie ? _lowestShare : _sharesCharlie;

        uint256 _dirtyTotalSupply = concentrator.totalSupply() - (_lowestShare * 3);
        uint256 _dirtyTotalAssetsBefore = concentrator.totalAssets();
        
        vm.startPrank(alice);
        uint256 _assetsAlice = concentrator.previewRedeem(_lowestShare);
        uint256 _sharesBurnAlice = concentrator.withdraw(_assetsAlice, address(alice), address(alice));
        vm.stopPrank();

        assertEq(IERC20(address(concentrator.asset())).balanceOf(address(alice)), _assetsAlice, "_testWithdrawLP: E1");
        assertApproxEqAbs(_sharesBurnAlice, _lowestShare, 1e16, "_testWithdrawLP: E2");
        assertApproxEqAbs(concentrator.balanceOf(address(alice)), _sharesAlice - _lowestShare, 1e16, "_testWithdrawLP: E3");
        
        vm.startPrank(bob);
        uint256 _assetsBob = concentrator.previewRedeem(_lowestShare);
        uint256 _sharesBurnBob = concentrator.withdraw(_assetsBob, address(bob), address(bob));
        vm.stopPrank();
        
        assertEq(IERC20(address(concentrator.asset())).balanceOf(address(bob)), _assetsBob, "_testWithdrawLP: E4");
        assertApproxEqAbs(_sharesBurnBob, _lowestShare, 1e16, "_testWithdrawLP: E5");
        assertApproxEqAbs(concentrator.balanceOf(address(bob)), _sharesBob - _lowestShare, 1e16, "_testWithdrawLP: E6");
        
        vm.startPrank(charlie);
        uint256 _assetsCharlie = concentrator.previewRedeem(_lowestShare);
        uint256 _sharesBurnCharlie = concentrator.withdraw(_assetsCharlie, address(charlie), address(charlie));
        vm.stopPrank();
        
        assertEq(IERC20(address(concentrator.asset())).balanceOf(address(charlie)), _assetsCharlie, "_testWithdrawLP: E7");
        assertApproxEqAbs(_sharesBurnCharlie, _lowestShare, 1e16, "_testWithdrawLP: E8");
        assertApproxEqAbs(concentrator.balanceOf(address(charlie)), _sharesCharlie - _lowestShare, 1e16, "_testWithdrawLP: E9");
        
        uint256 _dirtyTotalAssets = _dirtyTotalAssetsBefore - (_assetsAlice + _assetsBob + _assetsCharlie);

        assertApproxEqAbs(concentrator.totalAssets(), _dirtyTotalAssets, 1e16, "_testWithdrawLP: E10");
        assertApproxEqAbs(concentrator.totalSupply(), _dirtyTotalSupply, 1e16, "_testWithdrawLP: E11");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnBob, 1e16, "_testWithdrawLP: E12");
        assertApproxEqAbs(_sharesBurnAlice, _sharesBurnCharlie, 1e16, "_testWithdrawLP: E13");
    }


    function _dealERC20(address _token, address _recipient , uint256 _amount) internal {
        deal({ token: address(_token), to: _recipient, give: _amount});
    }

    function _testDepositNoAsset(uint256 _amount, address _asset) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        vm.startPrank(alice);
        
        IERC20(_asset).safeApprove(address(concentrator), _amount);
        vm.expectRevert();
        concentrator.deposit(_amount, address(alice));
        vm.expectRevert();
        concentrator.mint(_amount, address(alice));
        vm.expectRevert();
        concentrator.depositUnderlying(_asset, address(alice), _amount);

        vm.stopPrank();
    }

    function _testDepositWrongAsset(uint256 _amount, address _asset) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        _dealERC20(address(_asset), alice, _amount);
        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        
        vm.startPrank(alice);
        IERC20(_asset).safeApprove(address(concentrator), _underlyingAlice);
        vm.expectRevert();
        concentrator.depositUnderlying(_asset, address(alice), _underlyingAlice);

        vm.stopPrank();
    }

    function _testWithdrawNoShare(uint256 _amount, address _asset) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        _dealERC20(address(_asset), alice, _amount);
        uint256 _underlyingAlice = ERC20(_asset).balanceOf(alice);
        
        vm.startPrank(alice);
        IERC20(_asset).safeApprove(address(concentrator), _underlyingAlice);
        uint256 _share = concentrator.depositUnderlying(_asset, address(alice), _underlyingAlice);
        vm.stopPrank();
        assertEq(_share, IERC20(address(concentrator)).balanceOf(alice), "testWithdrawNotOwner: E1");

        vm.startPrank(bob);
        
        vm.expectRevert();
        concentrator.withdraw(_share, bob, alice);
        vm.expectRevert();
        concentrator.withdraw(_share, bob, bob);
        vm.expectRevert();
        concentrator.redeem(_share, bob, alice);
        vm.expectRevert();
        concentrator.redeem(_share, bob, bob);
        vm.expectRevert();
        concentrator.redeemUnderlying(_asset, bob, alice, _share, 0);
        vm.expectRevert();
        concentrator.redeemUnderlying(_asset, bob, bob, _share, 0);
        
        vm.stopPrank();
    }

    function _addSwapRoutes() internal {

        if (!(_fortressSwap.routeExists(_YCRV, _CRVUSD))) {

            uint256[] memory _poolType = new uint256[](2);
            address[] memory _poolAddress = new address[](2);
            address[] memory _fromList = new address[](2);
            address[] memory _toList = new address[](2);

            _poolType[0] = 2;
            _poolType[1] = 4;

            _poolAddress[0] = 0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5;
            _poolAddress[1] = 0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14;

            _fromList[0] = _YCRV;
            _fromList[1] = _CRV;

            _toList[0] = _CRV;
            _toList[1] = _CRVUSD;

            _fortressSwap.updateRoute(_YCRV, _CRVUSD, _poolType, _poolAddress, _fromList, _toList);
        }
        
        if (!(_fortressSwap.routeExists(_YCRV, _CRV))) {
            uint256[] memory _poolType = new uint256[](1);
            address[] memory _poolAddress = new address[](1);
            address[] memory _fromList = new address[](1);
            address[] memory _toList = new address[](1);

            _poolType[0] = 2;
            
            _poolAddress[0] = 0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5;
            
            _fromList[0] = _YCRV;
            
            _toList[0] = _CRV;
            
            _fortressSwap.updateRoute(_YCRV, _CRV, _poolType, _poolAddress, _fromList, _toList);
        }
    }
}
