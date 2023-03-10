// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// import "forge-std/Script.sol";
// import "forge-std/console.sol";

// import "src/mainnet/utils/FortressRegistry.sol";
// import "src/mainnet/utils/FortressSwap.sol";

// import "script/mainnet/utils/compounders/curve/InitCurveCompounders.sol";
// import "script/mainnet/utils/compounders/balancer/InitBalancerCompounders.sol";
// import "script/mainnet/utils/compounders/token/InitTokenCompounders.sol";

// import "script/mainnet/utils/concentrators/balancer/InitBalancerConcentrators.sol";
// import "script/mainnet/utils/concentrators/curve/InitCurveConcentrators.sol";
contract InitFortress {}
// contract InitFortress is Script, InitCurveCompounders, InitBalancerCompounders, InitTokenCompounders, InitBalancerConcentrators, InitCurveConcentrators {

//     function run() public {
        
//         uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
//         address owner = vm.envAddress("OWNER");
//         address platform = vm.envAddress("PLATFORM");

//         vm.startBroadcast(deployerPrivateKey);

//         FortressSwap fortressSwap = new FortressSwap(address(owner));
//         FortressRegistry fortressRegistry = new FortressRegistry();
        
//         // initialize Curve AMM Compounders
//         // address _frxEthCompounder = _initializeCurveCompounders(address(owner), address(fortressRegistry), address(fortressSwap), address(platform));

//         // initialize Balancer AMM Compounders
//         address _threeEthCompounder = _initializeBalancerCompounders(address(owner), address(fortressRegistry), address(fortressSwap), address(platform));

//         // initialize Token Compounders
//         (address _auraBalCompounder, address _cvxCrvCompounder) = _initializeTokenCompounders(address(owner), address(fortressRegistry), address(fortressSwap), address(platform));

//         // initialize Balancer auraBAL Concentrators
//         _initializeBalancerAuraBALConcentrators(address(owner), address(fortressRegistry), address(fortressSwap), address(platform), _auraBalCompounder);

//         // initialize Balancer ETH Concentrators
//         _initializeBalancerEthConcentrators(address(owner), address(fortressRegistry), address(fortressSwap), address(platform), _threeEthCompounder);

//         // initialize Curve cvxCRV Concentrators
//         _initializeCurveCvxCrvConcentrators(address(owner), address(fortressRegistry), address(fortressSwap), address(platform), _cvxCrvCompounder);

//         // initialize Curve ETH Concentrators
//         // _initializeCurveEthConcentrators(address(owner), address(fortressRegistry), address(fortressSwap), address(platform), _frxEthCompounder);

//         console.log("FortressRegistry address: ", address(fortressRegistry));

//         string memory path = "script/mainnet/utils/registry.txt";
//         // string memory data = string(abi.encodePacked("!", "FortressRegistry=", string(vm.toString(address(fortressRegistry))), "!" ));
//         string memory data = string(abi.encodePacked(string(vm.toString(address(fortressRegistry)))));
//         vm.writeFile(path, data);

//         vm.stopBroadcast();
//     }
// }