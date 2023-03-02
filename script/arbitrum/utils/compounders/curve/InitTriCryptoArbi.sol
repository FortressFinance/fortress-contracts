// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "src/arbitrum/compounders/curve/CurveArbiCompounder.sol";
// import "script/arbitrum/utils/InitBase.sol";
// import "src/arbitrum/utils/FortressArbiSwap.sol";

// contract InitTriCryptoArbi is InitBaseArbi {

//     function _initializeTriCrypto(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform) public returns (address) {

//         _initSwapTriCrypto(_fortressSwap);
        
//         // ------------------------- init TriCrypto compounder -------------------------
        
//         uint256 _convexPid = 3;
//         uint256 _poolType = 0; 
//         address _asset = TRICRYPTO_LP;
//         // string memory _symbol = "fortTriCrypto";
//         // string memory _name = "Fortress Curve TriCrypto";

//         address[] memory _rewardAssets = new address[](1);
//         _rewardAssets[0] = CRV;
//         // _rewardAssets[1] = CVX;

//         // NOTE - make sure the order of underlying assets is the same as in Curve contract (Backend requirment) 
//         address[] memory _underlyingAssets = new address[](3);
//         _underlyingAssets[0] = USDT;
//         _underlyingAssets[1] = WBTC;
//         _underlyingAssets[2] = WETH;

//         CurveArbiCompounder curveCompounder = new CurveArbiCompounder(ERC20(_asset), "Fortress Compounding TriCrypto", "fcTriCrypto", curveCryptoDescription, _owner, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);

//         // ------------------------- init registry -------------------------

//         YieldOptimizersRegistry(_fortressArbiRegistry).registerAmmCompounder(true, address(curveCompounder), address(_asset));
        
//         return address(curveCompounder);
//     }

//      function _initSwapTriCrypto(address _fortressSwap) internal {

//         FortressArbiSwap _swap = FortressArbiSwap(payable(_fortressSwap));

//         // ETH --> wBTC 
//         if (!(_swap.routeExists(ETH, WBTC))) {
//             _poolType1[0] = 4;

//             _poolAddress1[0] = CURVE_TRICRYPTO;
            
//             _fromList1[0] = ETH;
            
//             _toList1[0] = WBTC;
            
//             _swap.updateRoute(ETH, WBTC, _poolType1, _poolAddress1, _fromList1, _toList1);
//         }

//         // ETH --> USDT
//         if (!(_swap.routeExists(ETH, USDT))) {
//             _poolType1[0] = 4;

//             _poolAddress1[0] = CURVE_TRICRYPTO;
            
//             _fromList1[0] = ETH;
            
//             _toList1[0] = USDT;

//             _swap.updateRoute(ETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
//         }

//         // ETH --> USDC
//         if (!(_swap.routeExists(ETH, USDC))) {
//             _poolType1[0] = 0;

//             _poolAddress1[0] = UNIV3_USDCWETH;
            
//             _fromList1[0] = ETH;
            
//             _toList1[0] = USDC;

//             _swap.updateRoute(ETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
//         }

//         // CRV --> WBTC
//         if (!(_swap.routeExists(CRV, WBTC))) {
//             _poolType2[0] = 0;
//             _poolType2[1] = 4;

//             _poolAddress2[0] = UNIV3_CRVWETH;
//             _poolAddress2[1] = CURVE_TRICRYPTO;

//             _fromList2[0] = CRV;
//             _fromList2[1] = WETH;
            
//             _toList2[0] = WETH;
//             _toList2[1] = WBTC;

//             _swap.updateRoute(CRV, WBTC, _poolType2, _poolAddress2, _fromList2, _toList2);
//         }

//         // CRV --> WETH
//         if (!(_swap.routeExists(CRV, WETH))) {
//             _poolType1[0] = 0;

//             _poolAddress1[0] = UNIV3_CRVWETH;

//             _fromList1[0] = CRV;
            
//             _toList1[0] = WETH;

//             _swap.updateRoute(CRV, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
//         }

//         // CRV --> ETH
//         if (!(_swap.routeExists(CRV, ETH))) {
//             _poolType1[0] = 0;

//             _poolAddress1[0] = UNIV3_CRVWETH;

//             _fromList1[0] = CRV;
            
//             _toList1[0] = ETH;

//             _swap.updateRoute(CRV, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
//         }

//         // CRV --> USDT
//         if (!(_swap.routeExists(CRV, USDT))) {
//             _poolType2[0] = 0;
//             _poolType2[1] = 4;

//             _poolAddress2[0] = UNIV3_CRVWETH;
//             _poolAddress2[1] = CURVE_TRICRYPTO;

//             _fromList2[0] = CRV;
//             _fromList2[1] = WETH;
            
//             _toList2[0] = WETH;
//             _toList2[1] = USDT;

//             _swap.updateRoute(CRV, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);
//         }
//      }
// }
