// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";

import "script/arbitrum/utils/compounders/balancer/InitWstETHwETH.sol";
import "src/arbitrum/utils/BalancerArbiOperations.sol";

contract InitBalancerCompounders is Script, InitWstETHwETHArbi {
    
    function run() internal {
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address deployer = vm.envAddress("DEPLOYER");

        address platform = 0xBF73FEBB672CC5B8707C2D75cB49B0ee2e2C9DaA;
        address yieldOptimizersRegistry = 0x03605C3A3dAf860774448df807742c0d0e49460C;
        address fortressArbiSwap = 0xd2DA200a79AbC6526EABACF98F8Ea4C26F34796F;

        vm.startBroadcast(deployerPrivateKey);

        // ------------------------- BalancerArbiOperations -------------------------

        BalancerArbiOperations _ammOperations = new BalancerArbiOperations(owner);

        // ------------------------- wstETH/wETH compounder -------------------------
        
        _initializeWstETHwETH(owner, yieldOptimizersRegistry, fortressArbiSwap, platform, address(_ammOperations));

        vm.stopBroadcast();
    }
}
