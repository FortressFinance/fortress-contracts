// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "src/mainnet/utils/FortressRegistry.sol";
import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";

contract InitFortress is Script, InitGlpCompounder {

    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address platform = vm.envAddress("PLATFORM");

        vm.startBroadcast(deployerPrivateKey);

        // FortressSwap fortressSwap = new FortressSwap(address(owner));
        // FortressRegistry fortressRegistry = new FortressRegistry();
        
        // initialize GLP Compounder
        address _glpCompounder = _initializeGlpCompounder(address(owner), address(platform));

        console.log("GlpCompounder address: ", address(_glpCompounder));

        string memory path = "script/arbitrum/utils/glp-compounder.txt";
        // string memory data = string(abi.encodePacked("!", "FortressRegistry=", string(vm.toString(address(fortressRegistry))), "!" ));
        string memory data = string(abi.encodePacked(string(vm.toString(address(_glpCompounder)))));
        vm.writeFile(path, data);

        vm.stopBroadcast();
    }
}