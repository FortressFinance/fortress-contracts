// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";

import "script/arbitrum/utils/compounders/balancer/InitWstETHwETH.sol";
import "src/arbitrum/utils/BalancerArbiOperations.sol";

contract InitBalancerCompounders is Script, InitWstETHwETHArbi {
    
    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("FORTRESS_DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("FORTRESS_MULTISIG_OWNER");
        address deployer = vm.envAddress("FORTRESS_DEPLOYER_ADDRESS");
        address platform = vm.envAddress("FORTRESS_MULTISIG_PLATFORM");

        address yieldOptimizersRegistry = yieldOptimizersRegistry;
        address fortressArbiSwap = FortressSwapV2;

        vm.startBroadcast(deployerPrivateKey);

        // ------------------------- BalancerArbiOperations -------------------------

        BalancerArbiOperations _balancerAmmOperations = new BalancerArbiOperations(deployer);

        // ------------------------- wstETH/wETH compounder -------------------------
        
        address _wstETHwETHVault = _initializeWstETHwETH(owner, yieldOptimizersRegistry, fortressArbiSwap, platform, address(_balancerAmmOperations));

        console.log("Balancer compounders initialized");
        console.log("_balancerAmmOperations: ", address(_balancerAmmOperations));
        console.log("_wstETHwETHVault: ", _wstETHwETHVault);

        vm.stopBroadcast();
    }
}
