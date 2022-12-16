// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// import "forge-std/Script.sol";
import "lib/forge-std/src/Script.sol";
// import "forge-std/console.sol";
import "lib/forge-std/src/console.sol";

import "src/arbitrum/utils/FortressArbiRegistry.sol";
import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";

contract InitFortress is Script, InitGlpCompounder {

    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address platform = vm.envAddress("PLATFORM");

        vm.startBroadcast(deployerPrivateKey);

        // FortressSwap fortressSwap = new FortressSwap(address(owner));
        FortressArbiRegistry _fortressArbiRegistry = new FortressArbiRegistry(address(owner));
        
        // initialize GLP Compounder
        address _glpCompounder = _initializeGlpCompounder(address(owner), address(platform), address(_fortressArbiRegistry));

        console.log("GlpCompounder address: ", address(_glpCompounder));

        string memory path = "script/arbitrum/utils/glp-compounder.txt";
        // string memory data = string(abi.encodePacked("!", "FortressRegistry=", string(vm.toString(address(fortressRegistry))), "!" ));
        string memory data = string(abi.encodePacked(string(vm.toString(address(_glpCompounder)))));
        vm.writeFile(path, data);

        path = "script/arbitrum/utils/arbi-registry.txt";
        data = string(abi.encodePacked(string(vm.toString(address(_fortressArbiRegistry)))));
        vm.writeFile(path, data);

        vm.stopBroadcast();
    }
}