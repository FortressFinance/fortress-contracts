// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "src/shared/utils/YieldOptimizersRegistry.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";
import "script/arbitrum/utils/compounders/curve/InitCurveCompounders.sol";
import "script/arbitrum/utils/concentrators/curve/InitCurveGlpConcentrators.sol";

contract InitFortress is Script, InitGlpCompounder, InitCurveCompounders, InitCurveGlpConcentrators {

    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        address deployer = vm.envAddress("DEPLOYER");
        // address platform = vm.envAddress("PLATFORM");
        address platform = owner;

        vm.startBroadcast(deployerPrivateKey);

        FortressArbiSwap _fortressSwap = new FortressArbiSwap(address(deployer));
        YieldOptimizersRegistry _yieldOptimizersRegistry = new YieldOptimizersRegistry(address(deployer));
        // address _fortressSwap = FortressSwapV1;
        
        console.log("_fortressSwap address: ", address(_fortressSwap));
        console.log("_yieldOptimizersRegistry address: ", address(_yieldOptimizersRegistry));
        
        // initialize GLP Compounder
        address _GlpCompounder = _initializeGlpCompounder(address(owner), address(platform), address(_yieldOptimizersRegistry), address(_fortressSwap));
        console.log("GlpCompounder address: ", _GlpCompounder);

        // initialize Curve AMM Compounders Arbitrum
        _initializeCurveCompounders(address(owner), address(_yieldOptimizersRegistry), address(_fortressSwap), address(platform));

        // initialize Curve GLP AMM Concentrators Arbitrum
        // _initializeCurveConcentrators(address(owner), address(_fortressArbiRegistry), address(_fortressSwap), address(platform), address(_GlpCompounder));
        
        string memory path = "script/arbitrum/utils/arbi-registry.txt";
        string memory data = string(abi.encodePacked(string(vm.toString(address(_yieldOptimizersRegistry)))));
        vm.writeFile(path, data);

        path = "script/arbitrum/utils/addresses.txt";
        data = string(abi.encodePacked("!", "_yieldOptimizersRegistry=", string(vm.toString(address(_yieldOptimizersRegistry))), "!", "_fortressSwap=", string(vm.toString(address(_fortressSwap))), "!", "GlpCompounder=", string(vm.toString(address(_GlpCompounder))), "!"));
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