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
        // address deployer = vm.envAddress("DEPLOYER");
        // address platform = vm.envAddress("PLATFORM");
        address platform = owner;

        vm.startBroadcast(deployerPrivateKey);

        // FortressArbiSwap _fortressSwap = new FortressArbiSwap(address(deployer));
        // address _fortressSwap = 0xd2DA200a79AbC6526EABACF98F8Ea4C26F34796F;
        address _fortressSwap = FortressSwapV1;
        // address _fortressArbiRegistry = 0x5D21D171b265E5212B3E673759C971537b6a0d01;
        address _fortressArbiRegistry = FortressRegistryV1;
        
        console.log("FortressArbiSwap address: ", address(_fortressSwap));
        console.log("FortressArbiRegistry address: ", address(_fortressArbiRegistry));
        
        // initialize GLP Compounder
        address _GlpCompounder = _initializeGlpCompounder(address(owner), address(platform), address(_fortressArbiRegistry), address(_fortressSwap));
        console.log("GlpCompounder address: ", _GlpCompounder);

        // initialize Curve AMM Compounders Arbitrum
        _initializeCurveCompounders(address(owner), address(_fortressArbiRegistry), address(_fortressSwap), address(platform));
        
        string memory path = "script/arbitrum/utils/arbi-registry.txt";
        string memory data = string(abi.encodePacked(string(vm.toString(address(_fortressArbiRegistry)))));
        vm.writeFile(path, data);

        path = "script/arbitrum/utils/addresses.txt";
        data = string(abi.encodePacked("!", "FortressRegistry=", string(vm.toString(address(_fortressArbiRegistry))), "!", "FortressSwap=", string(vm.toString(address(_fortressSwap))), "!", "GlpCompounder=", string(vm.toString(address(_GlpCompounder))), "!"));
        vm.writeFile(path, data);

        vm.stopBroadcast();
    }
}



// ---- Notes ----

// forge script script/arbitrum/InitFortressArbi.s.sol:InitFortress --rpc-url $RPC_URL --broadcast
// cast call COMPUNDER_ADDRESS "balanceOf(address)(uint256)" 0x24aDB12fE4b03b780989B5D7C5A5114b2fc45F01 --rpc-url RPC_URL
// cast call REG_ADDRESS "getTokenCompounder(address)(address)" 0x24aDB12fE4b03b780989B5D7C5A5114b2fc45F01 --rpc-url RPC_URL
// https://abi.hashex.org/ - for constructor
// forge flatten --output GlpCompounder.sol src/arbitrum/compounders/gmx/GlpCompounder.sol