// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "script/mainnet/utils/AddRoutes.sol";
import "src/mainnet/utils/FortressRegistry.sol";
import "src/shared/interfaces/ERC20.sol";

contract TokenCompounderBaseTest is Test, AddRoutes {

    address owner;
    address alice;
    address bob;
    address charlie;
    address yossi;
    address harvester;
    address platform;

    uint256 amount;
    uint256 accumulatedAmount;
    uint256 accumulatedShares;
    uint256 shares;
    uint256 aliceAmountOut;
    uint256 bobAmountOut;
    uint256 charlieAmountOut;

    uint256 mainnetFork;
    
    FortressRegistry fortressRegistry;
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

        vm.startPrank(owner);
        fortressSwap = new FortressSwap(address(owner));
        fortressRegistry = new FortressRegistry();
        
        addRoutes(address(fortressSwap));
        vm.stopPrank();
    }

    function _getAssetFromETH(address _owner, address _asset, uint256 _amount) internal returns (uint256 _assetOut) {
        vm.prank(_owner);
        _assetOut = fortressSwap.swap{ value: _amount }(ETH, _asset, _amount);
        
        assertApproxEqAbs(IERC20(_asset).balanceOf(_owner), _assetOut, 5, "_getAssetFromETH: E1");
    }
}