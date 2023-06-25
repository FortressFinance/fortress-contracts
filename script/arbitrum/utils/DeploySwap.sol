// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "src/arbitrum/utils/FortressArbiSwap.sol";
import "script/arbitrum/utils/InitBase.sol";

contract DeploySwap is Script, InitBaseArbi {
    
    function run() public {
        
        uint256 deployerPrivateKey = vm.envUint("GBC_DEPLOYER_PRIVATE_KEY");
        address deployer = vm.envAddress("GBC_DEPLOYER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        FortressArbiSwap _fortressSwap = new FortressArbiSwap(address(deployer));

        _addRoutes(_fortressSwap);

        console.log("----------------------");
        console.log("----------------------");
        console.log("FortressArbiSwap: ", address(_fortressSwap));
        console.log("----------------------");
        console.log("----------------------");

        vm.stopBroadcast();
    }

    function _addRoutes(FortressArbiSwap _swap) internal {
        
        // CRV --> USDC
        if (!(_swap.routeExists(CRV, USDC))) {
            _poolType2[0] = 0;
            _poolType2[1] = 0;
            
            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = UNIV3_USDCWETH;
            
            _fromList2[0] = CRV;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = USDC;

            _swap.updateRoute(CRV, USDC, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // CRV --> USDT
        if (!(_swap.routeExists(CRV, USDT))) {
            _poolType2[0] = 0;
            _poolType2[1] = 4;

            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = CURVE_TRICRYPTO;

            _fromList2[0] = CRV;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = USDT;

            _swap.updateRoute(CRV, USDT, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // CRV --> WBTC
        if (!(_swap.routeExists(CRV, WBTC))) {
            _poolType2[0] = 0;
            _poolType2[1] = 4;

            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = CURVE_TRICRYPTO;

            _fromList2[0] = CRV;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = WBTC;

            _swap.updateRoute(CRV, WBTC, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // CRV --> FRAX
        if (!(_swap.routeExists(CRV, FRAX))) {
            _poolType3[0] = 0;
            _poolType3[1] = 0;
            _poolType3[2] = 2;
            
            _poolAddress3[0] = UNIV3_CRVWETH;
            _poolAddress3[1] = UNIV3_USDCWETH;
            _poolAddress3[2] = CURVE_FRAXBP;
            
            _fromList3[0] = CRV;
            _fromList3[1] = WETH;
            _fromList3[2] = USDC;
            
            _toList3[0] = WETH;
            _toList3[1] = USDC;
            _toList3[2] = FRAX;

            _swap.updateRoute(CRV, FRAX, _poolType3, _poolAddress3, _fromList3, _toList3);
        }

        // CRV --> WETH
        if (!(_swap.routeExists(CRV, WETH))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_CRVWETH;

            _fromList1[0] = CRV;
            
            _toList1[0] = WETH;

            _swap.updateRoute(CRV, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // CRV --> ETH
        if (!(_swap.routeExists(CRV, ETH))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_CRVWETH;

            _fromList1[0] = CRV;
            
            _toList1[0] = ETH;

            _swap.updateRoute(CRV, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> USDC
        if (!(_swap.routeExists(ETH, USDC))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(ETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> USDT
        if (!(_swap.routeExists(ETH, USDT))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDT;

            _swap.updateRoute(ETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> wBTC 
        if (!(_swap.routeExists(ETH, WBTC))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = WBTC;
            
            _swap.updateRoute(ETH, WBTC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> USDT
        if (!(_swap.routeExists(ETH, USDT))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDT;

            _swap.updateRoute(ETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> USDC
        if (!(_swap.routeExists(ETH, USDC))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(ETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> FRAX
        if (!(_swap.routeExists(ETH, FRAX))) {
            _poolType2[0] = 0;
            _poolType2[1] = 2;

            _poolAddress2[0] = UNIV3_USDCWETH;
            _poolAddress2[1] = CURVE_FRAXBP;

            _fromList2[0] = ETH;
            _fromList2[1] = USDC;
            
            _toList2[0] = USDC;
            _toList2[1] = FRAX;

            _swap.updateRoute(ETH, FRAX, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // WETH --> USDC
        if (!(_swap.routeExists(WETH, USDC))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = WETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(WETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> USDT
        if (!(_swap.routeExists(WETH, USDT))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = WETH;
            
            _toList1[0] = USDT;

            _swap.updateRoute(WETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> wBTC 
        if (!(_swap.routeExists(WETH, WBTC))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = WETH;
            
            _toList1[0] = WBTC;
            
            _swap.updateRoute(WETH, WBTC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> USDT
        if (!(_swap.routeExists(WETH, USDT))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = WETH;
            
            _toList1[0] = USDT;

            _swap.updateRoute(WETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> USDC
        if (!(_swap.routeExists(WETH, USDC))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = WETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(WETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> FRAX
        if (!(_swap.routeExists(WETH, FRAX))) {
            _poolType2[0] = 0;
            _poolType2[1] = 2;

            _poolAddress2[0] = UNIV3_USDCWETH;
            _poolAddress2[1] = CURVE_FRAXBP;

            _fromList2[0] = WETH;
            _fromList2[1] = USDC;
            
            _toList2[0] = USDC;
            _toList2[1] = FRAX;

            _swap.updateRoute(WETH, FRAX, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // USDC --> WETH
        if (!(_swap.routeExists(USDC, WETH))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = USDC;
            
            _toList1[0] = WETH;

            _swap.updateRoute(USDC, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // USDT --> WETH
        if (!(_swap.routeExists(USDT, WETH))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = USDT;
            
            _toList1[0] = WETH;

            _swap.updateRoute(USDT, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WBTC --> WETH
        if (!(_swap.routeExists(WBTC, WETH))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = WBTC;
            
            _toList1[0] = WETH;
            
            _swap.updateRoute(WBTC, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> USDT
        if (!(_swap.routeExists(USDT, WETH))) {
            _poolType1[0] = 4;

            _poolAddress1[0] = CURVE_TRICRYPTO;
            
            _fromList1[0] = USDT;
            
            _toList1[0] = WETH;

            _swap.updateRoute(USDT, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // USDC --> WETH
        if (!(_swap.routeExists(USDC, WETH))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_USDCWETH;
            
            _fromList1[0] = USDC;
            
            _toList1[0] = WETH;

            _swap.updateRoute(USDC, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // FRAX --> WETH
        if (!(_swap.routeExists(FRAX, WETH))) {
            _poolType2[0] = 2;
            _poolType2[1] = 0;

            _poolAddress2[0] = CURVE_FRAXBP;
            _poolAddress2[1] = UNIV3_USDCWETH;

            _fromList2[0] = FRAX;
            _fromList2[1] = USDC;
            
            _toList2[0] = USDC;
            _toList2[1] = WETH;

            _swap.updateRoute(FRAX, WETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }
    }
}