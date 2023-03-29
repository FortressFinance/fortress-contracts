// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "src/shared/utils/YieldOptimizersRegistry.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
// import "src/arbitrum/utils/FortressArbiSwap.sol";
import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";
import "script/arbitrum/utils/compounders/curve/InitCurveCompounders.sol";
import "script/arbitrum/utils/concentrators/curve/InitCurveGlpConcentrators.sol";
import "src/arbitrum/utils/CurveArbiOperations.sol";

contract InitFortress is Script, InitGlpCompounder, InitCurveCompounders, InitCurveGlpConcentrators {

    function run() public {
        
        // uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        // address deployer = vm.envAddress("DEPLOYER");
        address deployer = vm.envAddress("DEPLOYER");
        // address platform = vm.envAddress("PLATFORM");
        address platform = owner;

        vm.startBroadcast(deployerPrivateKey);

        FortressArbiSwap _fortressSwap = new FortressArbiSwap(address(deployer));
        YieldOptimizersRegistry _yieldOptimizersRegistry = new YieldOptimizersRegistry(address(deployer));
        CurveArbiOperations _ammOperations = new CurveArbiOperations(address(deployer));
        // address _fortressSwap = FortressSwapV1;
        
        console.log("_fortressSwap address: ", address(_fortressSwap));
        console.log("_yieldOptimizersRegistry address: ", address(_yieldOptimizersRegistry));
        console.log("_ammOperations address: ", address(_ammOperations));
        
        // initialize GLP Compounder
        address _glpCompounder = _initializeGlpCompounder(address(owner), address(platform), address(_yieldOptimizersRegistry), address(_fortressSwap));
        console.log("GlpCompounder address: ", _glpCompounder);

        // update YieldOptimizersRegistry 
        YieldOptimizersRegistry(_yieldOptimizersRegistry).updateConcentratorsTargetAssets(address(0), address(0), address(_glpCompounder), address(0));

        // initialize Curve AMM Compounders Arbitrum
        _initializeCurveCompounders(address(owner), address(_yieldOptimizersRegistry), address(_fortressSwap), address(platform), address(_ammOperations));

        // initialize Curve GLP AMM Concentrators Arbitrum
        // _initializeCurveConcentrators(address(owner), address(_yieldOptimizersRegistry), address(_fortressSwap), address(platform), address(_glpCompounder), address(_ammOperations));
        
        string memory path = "script/arbitrum/utils/arbi-registry.txt";
        string memory data = string(abi.encodePacked(string(vm.toString(address(_yieldOptimizersRegistry)))));
        vm.writeFile(path, data);

        path = "script/arbitrum/utils/addresses.txt";
        data = string(abi.encodePacked("!", "_yieldOptimizersRegistry=", string(vm.toString(address(_yieldOptimizersRegistry))), "!", "_fortressSwap=", string(vm.toString(address(_fortressSwap))), "!", "GlpCompounder=", string(vm.toString(address(_glpCompounder))), "!"));
        vm.writeFile(path, data);

        vm.stopBroadcast();
    }
}

// arbitrum mainnet:
// _fortressSwap address:  0xBbF847A344ceBC46DD226dc2682A703ebe37eB9e
//   _yieldOptimizersRegistry address:  0x03605C3A3dAf860774448df807742c0d0e49460C
//   _ammOperations address:  0x860b5691C95a2698bAd732E88F95C2e947AA4aDB
//   GlpCompounder address:  0x86eE39B28A7fDea01b53773AEE148884Db311B46



// ---- Notes ----

// forge script script/arbitrum/InitFortressArbi.s.sol:InitFortress --rpc-url $RPC_URL --broadcast
// cast call COMPUNDER_ADDRESS "balanceOf(address)(uint256)" 0x24aDB12fE4b03b780989B5D7C5A5114b2fc45F01 --rpc-url RPC_URL
// cast call REG_ADDRESS "getTokenCompounder(address)(address)" 0x24aDB12fE4b03b780989B5D7C5A5114b2fc45F01 --rpc-url RPC_URL
// https://abi.hashex.org/ - for constructor
// forge flatten --output GlpCompounder.sol src/arbitrum/compounders/gmx/GlpCompounder.sol
// forge verify-contract --verifier-url https://arbiscan.io/ 0x03605C3A3dAf860774448df807742c0d0e49460C src/arbitrum/utils/FortressArbiRegistry.sol:FortressArbiRegistry