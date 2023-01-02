// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/FortressArbiRegistry.sol";

import "script/arbitrum/utils/AddressesArbi.sol";

import "src/shared/interfaces/IWETH.sol";

abstract contract BaseTest is Test, AddressesArbi {

    using SafeERC20 for IERC20;

    address owner;
    address alice;
    address bob;
    address charlie;
    address yossi;
    address harvester;
    address platform;

    uint256 arbitrumFork;

    uint256 platformFeePercentage = 25000000; // 2.5%
    uint256 harvestBountyPercentage = 25000000; // 2.5%
    uint256 withdrawFeePercentage = 1000000; // 0.1%

    FortressArbiSwap fortressSwap;
    FortressArbiRegistry fortressRegistry;
    
    function _setUp() internal {
        
        // --------------------------------- set env ---------------------------------
        
        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        
        vm.selectFork(arbitrumFork);
        
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
        fortressSwap = new FortressArbiSwap(address(owner));
        fortressRegistry = new FortressArbiRegistry(address(owner));
        vm.stopPrank();
    }

    function _getAssetFromETH(address _owner, address _asset, uint256 _amount) internal returns (uint256 _assetOut) {
        vm.prank(_owner);

        if (_asset == WETH) {
            IWETH(WETH).deposit{ value: _amount }();
            _assetOut = _amount;
            require(_assetOut > 0, "BaseTest: E1");
            assertEq(IERC20(_asset).balanceOf(_owner), _assetOut, "BaseTest: E2");
        } else {
            _assetOut = fortressSwap.swap{ value: _amount }(ETH, _asset, _amount);
        }
        
        assertEq(IERC20(_asset).balanceOf(_owner), _assetOut, "_getAssetFromETH: E1");
    }
}