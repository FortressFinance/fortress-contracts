// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "src/arbitrum/utils/FortressArbiSwap.sol";
// import "src/arbitrum/utils/FortressArbiRegistry.sol";
import "src/shared/utils/YieldOptimizersRegistry.sol";

import "src/shared/interfaces/IWETH.sol";

contract BaseTest is Test {

    address BASE_WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    address owner;
    address alice;
    address bob;
    address charlie;
    address yossi;
    address harvester;
    address platform;
    address johnnyGlpOwner;

    uint256 amount;
    uint256 accumulatedAmount;
    uint256 accumulatedShares;
    uint256 shares;
    uint256 aliceAmountOut;
    uint256 bobAmountOut;
    uint256 charlieAmountOut;

    uint256 arbiFork;
    
    YieldOptimizersRegistry fortressRegistry;
    FortressArbiSwap fortressSwap;

    function _setUp() internal {
        
        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
        arbiFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbiFork);

        owner = address(0x16cAD91E1928F994816EbC5e759d8562aAc65ab2);
        alice = address(0xFa0C696bC56AE0d256D34a307c447E80bf92Dd41);
        bob = address(0x864e4b0c28dF7E2f317FF339CebDB5224F47220e);
        charlie = address(0xe81557e0a10f59b5FA9CE6d3e128b5667D847FBc);
        yossi = address(0x77Ee01E3d0E05b4afF42105Fe004520421248261);
        johnnyGlpOwner = address(0x5C1E6bA712e9FC3399Ee7d5824B6Ec68A0363C02);
        platform = address(0x9cbD8440E5b8f116082a0F4B46802DB711592fAD);
        harvester = address(0xBF93B898E8Eee7dd6915735eB1ea9BFc4b98BEc0);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        vm.deal(yossi, 100 ether);
        vm.deal(harvester, 100 ether);
        vm.deal(johnnyGlpOwner, 100 ether);

        vm.startPrank(owner);
        fortressSwap = new FortressArbiSwap(address(owner));
        fortressRegistry = new YieldOptimizersRegistry(address(owner));
        vm.stopPrank();
    }

    function _wrapETH(address _owner, uint256 _amount) internal {
        vm.prank(_owner);
        IWETH(BASE_WETH).deposit{ value: _amount }();
    }

    function _unwrapETH(uint256 _amount) internal {
        IWETH(BASE_WETH).withdraw(_amount);
    }

    function _dealERC20(address _token, address _recipient, uint256 _amount) internal {
        deal({ token: address(_token), to: _recipient, give: _amount});

        assertEq(IERC20(_token).balanceOf(_recipient), _amount, "ERROR: dealERC20");
    }
}