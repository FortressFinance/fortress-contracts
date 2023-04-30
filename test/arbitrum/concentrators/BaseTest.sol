// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {CurveArbiOperations} from "src/arbitrum/utils/CurveArbiOperations.sol";
import {FortressArbiSwap} from "src/arbitrum/utils/FortressArbiSwap.sol";
import {YieldOptimizersRegistry} from "src/shared/utils/YieldOptimizersRegistry.sol";

import {AddressesArbi} from "script/arbitrum/utils/AddressesArbi.sol";

import {IWETH} from "src/shared/interfaces/IWETH.sol";

abstract contract BaseTest is Test, AddressesArbi {

    using SafeERC20 for IERC20;

    address owner;
    address alice;
    address bob;
    address charlie;
    address yossi;
    address harvester;
    address platform;
    address compounder;

    uint256 arbitrumFork;

    uint256 platformFeePercentage = 25000000; // 2.5%
    uint256 harvestBountyPercentage = 25000000; // 2.5%
    uint256 withdrawFeePercentage = 1000000; // 0.1%

    CurveArbiOperations ammOperations;
    FortressArbiSwap fortressSwap;
    YieldOptimizersRegistry fortressRegistry;
    
    function _setUp() internal {
        
        // --------------------------------- set env ---------------------------------
        
        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        
        vm.selectFork(arbitrumFork);
        
        // --------------------------------- set accounts ---------------------------------

        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        yossi = makeAddr("yossi");
        platform = makeAddr("platform");
        harvester = makeAddr("harvester");

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(yossi, 100 ether);
        vm.deal(harvester, 100 ether);

        vm.startPrank(owner);
        ammOperations = new CurveArbiOperations(address(owner));
        
        fortressSwap = new FortressArbiSwap(address(owner));
        fortressRegistry = new YieldOptimizersRegistry(address(owner));
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