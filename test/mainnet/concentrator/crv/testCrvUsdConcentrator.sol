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

    function _testCorrectFlow(address _asset, uint256 _amount) public {
        vm.assume(_amount > 0.1 ether && _amount < 10 ether);
        
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

        // ------------ Withdraw ------------
        
        (uint256 _tokenOutAlice, uint256 _tokenOutBob, uint256 _tokenOutCharlie) = _testRedeemUnderlying(_asset, _sharesAlice, _sharesBob, _sharesCharlie);

        // assertApproxEqAbs((_underlyingAlice + _underlyingBob + _underlyingCharlie), (_tokenOutAlice + _tokenOutBob + _tokenOutCharlie), 1e20, "_testCorrectFlow: E1");
        // assertApproxEqAbs(_underlyingAlice, _tokenOutAlice,  1e17, "_testCorrectFlow: E2");
        // assertApproxEqAbs(_underlyingBob, _tokenOutBob,  1e17,"_testCorrectFlow: E3");
        // assertApproxEqAbs(_underlyingCharlie, _tokenOutCharlie,   1e17, "_testCorrectFlow: E4");

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

    function _dealERC20(address _token, address _recipient , uint256 _amount) internal {
        deal({ token: address(_token), to: _recipient, give: _amount});
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
