// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/gmx/GlpCompounder.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "script/arbitrum/utils/InitBase.sol";

contract InitGlpCompounder is InitBaseArbi {
    
    function _initializeGlpCompounder(address _owner, address _platform, address _registry, address _swap) public returns (address) {

        _initSwapGlp(_swap);

        address sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;

        _underlyingAssets5[0] = WETH;
        _underlyingAssets5[1] = ETH;
        _underlyingAssets5[2] = FRAX;
        _underlyingAssets5[3] = USDC;
        _underlyingAssets5[4] = USDT;

        GlpCompounder _glpCompounder = new GlpCompounder(cryptoDescription, _owner, _platform, _swap, _underlyingAssets5);
        
        YieldOptimizersRegistry(_registry).registerTokenCompounder(address(_glpCompounder), sGLP);
        
        return address(_glpCompounder);
    }

    function _initSwapGlp(address _fortressSwap) internal {

        FortressArbiSwap _swap = FortressArbiSwap(payable(_fortressSwap));

        // // WETH --> LINK 
        // if (!(_swap.routeExists(WETH, LINK))) {
        //     _poolType1[0] = 14;
            
        //     _poolAddress1[0] = address(0);
            
        //     _fromList1[0] = WETH;
            
        //     _toList1[0] = LINK;

        //     _swap.updateRoute(WETH, LINK, _poolType1, _poolAddress1, _fromList1, _toList1);
        // }

        // WETH --> FRAX
        if (!(_swap.routeExists(WETH, FRAX))) {
            _poolType1[0] = 14;
            
            _poolAddress1[0] = address(0);
            
            _fromList1[0] = WETH;
            
            _toList1[0] = FRAX;

            _swap.updateRoute(WETH, FRAX, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> USDC
        if (!(_swap.routeExists(WETH, USDC))) {
            _poolType1[0] = 14;
            
            _poolAddress1[0] = address(0);
            
            _fromList1[0] = WETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(WETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // WETH --> USDT
        if (!(_swap.routeExists(WETH, USDT))) {
            _poolType1[0] = 14;
            
            _poolAddress1[0] = address(0);
            
            _fromList1[0] = WETH;
            
            _toList1[0] = USDT;

            _swap.updateRoute(WETH, USDT, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // // WETH --> WBTC
        // if (!(_swap.routeExists(WETH, WBTC))) {
        //     _poolType1[0] = 14;
            
        //     _poolAddress1[0] = address(0);
            
        //     _fromList1[0] = WETH;
            
        //     _toList1[0] = WBTC;

        //     _swap.updateRoute(WETH, WBTC, _poolType1, _poolAddress1, _fromList1, _toList1);
        // }

        // // WETH --> wstETH
        // if (!(_swap.routeExists(WETH, WSTETH))) {
        //     _poolType1[0] = 12;
            
        //     _poolAddress1[0] = BALANCER_WSTETHWETH;
            
        //     _fromList1[0] = WETH;
            
        //     _toList1[0] = WSTETH;

        //     _swap.updateRoute(WETH, WSTETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        // }

        // // wstETH --> WETH
        // if (!(_swap.routeExists(WSTETH, WETH))) {
        //     _poolType1[0] = 12;
            
        //     _poolAddress1[0] = BALANCER_WSTETHWETH;
            
        //     _fromList1[0] = WSTETH;
            
        //     _toList1[0] = WETH;

        //     _swap.updateRoute(WSTETH, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        // }
    }
}