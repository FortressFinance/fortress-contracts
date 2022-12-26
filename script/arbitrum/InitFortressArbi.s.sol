// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "src/arbitrum/utils/FortressArbiRegistry.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";
import "script/arbitrum/utils/compounders/curve/InitCurveCompounders.sol";

contract InitFortress is Script, InitGlpCompounder, InitCurveCompounders {

    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address platform = vm.envAddress("PLATFORM");

        vm.startBroadcast(deployerPrivateKey);

        FortressArbiSwap _fortressSwap = new FortressArbiSwap(address(owner));
        FortressArbiRegistry _fortressArbiRegistry = new FortressArbiRegistry(address(owner));
        
        console.log("FortressArbiSwap address: ", address(_fortressSwap));
        console.log("FortressArbiRegistry address: ", address(_fortressArbiRegistry));
        
        // initialize GLP Compounder
        _initializeGlpCompounder(address(owner), address(platform), address(_fortressArbiRegistry), address(_fortressSwap));
        
        // initialize Curve AMM Compounders Arbitrum
        _initializeCurveCompounders(address(owner), address(_fortressArbiRegistry), address(_fortressSwap), address(platform));
        
        string memory path = "script/arbitrum/utils/arbi-registry.txt";
        string memory data = string(abi.encodePacked(string(vm.toString(address(_fortressArbiRegistry)))));
        vm.writeFile(path, data);

        vm.stopBroadcast();
    }
}