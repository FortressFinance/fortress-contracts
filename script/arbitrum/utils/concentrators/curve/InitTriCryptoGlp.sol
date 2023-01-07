// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/concentrators/curve/CurveGlpConcentrator.sol";
import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/FortressArbiRegistry.sol";

contract InitTriCryptoGlp is InitBaseArbi {
    
    function _initializeTriCryptoGlp(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform, address _compounder) public returns (address) {
       
        _initSwapTriCryptoGlp(_fortressSwap);
        
        // ------------------------- init TriCrypto compounder -------------------------

        uint256 _convexPid = 3;
        uint256 _poolType = 0; 

        _asset = TRICRYPTO_LP;
        _symbol = "fortGLP-TriCrypto";
        _name = "Fortress GLP Curve TriCrypto";

        _underlyingAssets3[0] = USDT;
        _underlyingAssets3[1] = WBTC;
        _underlyingAssets3[2] = WETH;

        _rewardAssets1[0] = CRV;

        CurveGlpConcentrator curveGlpConcentrator = new CurveGlpConcentrator(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _convexPid, _rewardAssets1, _underlyingAssets3, _compounder, _poolType);
        
        // ------------------------- init registry -------------------------

        FortressArbiRegistry(_fortressArbiRegistry).registerCurveGlpConcentrator(address(curveGlpConcentrator), _asset, _symbol, _name, _underlyingAssets3, _compounder);
        
        return address(curveGlpConcentrator);
    }

     function _initSwapTriCryptoGlp(address _fortressSwap) internal {

        FortressArbiSwap _swap = FortressArbiSwap(payable(_fortressSwap));

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
            _poolType1[0] = 14;

            _poolAddress1[0] = address(0);
            
            _fromList1[0] = ETH;
            
            _toList1[0] = USDC;

            _swap.updateRoute(ETH, USDC, _poolType1, _poolAddress1, _fromList1, _toList1);
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

        // ETH --> CRV
        if (!(_swap.routeExists(ETH, CRV))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_CRVWETH;

            _fromList1[0] = ETH;
            
            _toList1[0] = CRV;

            _swap.updateRoute(ETH, CRV, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // CRV --> WETH
        if (!(_swap.routeExists(CRV, WETH))) {
            _poolType1[0] = 0;

            _poolAddress1[0] = UNIV3_CRVWETH;

            _fromList1[0] = CRV;
            
            _toList1[0] = WETH;

            _swap.updateRoute(CRV, WETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // CRV --> USDC
        if (!(_swap.routeExists(CRV, USDC))) {
            _poolType2[0] = 0;
            _poolType2[1] = 14;

            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = address(0);

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

        // CRV --> LINK
        if (!(_swap.routeExists(CRV, LINK))) {
            _poolType2[0] = 0;
            _poolType2[1] = 14;

            _poolAddress2[0] = UNIV3_CRVWETH;
            _poolAddress2[1] = address(0);

            _fromList2[0] = CRV;
            _fromList2[1] = WETH;
            
            _toList2[0] = WETH;
            _toList2[1] = LINK;

            _swap.updateRoute(CRV, LINK, _poolType2, _poolAddress2, _fromList2, _toList2);
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
     }
}
