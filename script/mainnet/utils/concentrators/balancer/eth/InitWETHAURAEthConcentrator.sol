// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "src/mainnet/concentrators/balancer/BalancerEthConcentrator.sol";
// import "src/mainnet/utils/FortressSwap.sol";
// import "src/mainnet/utils/FortressRegistry.sol";
// import "script/mainnet/utils/Addresses.sol";

// import "script/mainnet/utils/InitBase.sol";
contract InitWETHAURAEthConcentrator {}
// contract InitWETHAURAEthConcentrator is InitBase {

//     function _initWETHAURAEthConcentrator(address _owner, address _fortressRegistry, address _fortressSwap, address _platform, address _compounder) public returns (address) {

//         // ------------------------- init fortress swap -------------------------

//         FortressSwap _swap = FortressSwap(payable(_fortressSwap));

//         // AURA --> BAL
//         if (!(_swap.routeExists(AURA, BAL))) { 
//             _poolType2[0] = 12;
//             _poolType2[1] = 12;

//             _poolAddress2[0] = BALANCER_WETHAURA;
//             _poolAddress2[1] = BALANCER_WETHBAL;

//             _fromList2[0] = AURA;
//             _fromList2[1] = WETH;

//             _toList2[0] = WETH;
//             _toList2[1] = BAL;

//             _swap.updateRoute(AURA, BAL, _poolType2, _poolAddress2, _fromList2, _toList2);
//         }

//         // ------------------------- init WETH/AURA compounder -------------------------
        
//         _boosterPoolId = 0;
//         _asset = BALANCER_WETHAURA;
//         _symbol = "fortress-bWETHAURA";
//         _name = "Fortress Balancer WETH/AURA";

//         _rewardAssets2[0] = BAL;
//         _rewardAssets2[1] = AURA;

//         _underlyingAssets2[0] = AURA;
//         _underlyingAssets2[1] = WETH;

//         BalancerEthConcentrator ETHConcentrator = new BalancerEthConcentrator(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _boosterPoolId, _rewardAssets2, _underlyingAssets2, _compounder);

//         // ------------------------- init registry -------------------------

//         FortressRegistry(_fortressRegistry).registerBalancerEthConcentrator(address(ETHConcentrator), _asset, _symbol, _name, _underlyingAssets2, _compounder);

//         return address(ETHConcentrator);
//     }
// }