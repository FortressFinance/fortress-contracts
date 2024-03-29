// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/concentrators/curve/CurveGlpConcentrator.sol";
import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/FortressArbiRegistry.sol";
import "src/arbitrum/utils/CurveArbiOperations.sol";


// 2CRV    _convexPid=7 https://arbiscan.io/address/0x7f90122BF0700F9E7e1F688fe926940E8839F353

contract InitTriCryptoGlp is InitBaseArbi {
    
    function _initializeTriCryptoGlp(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform, address _compounder, address _ammOperations) public returns (address) {
       
        _initSwapTriCryptoGlp(_fortressSwap);
        
        // ------------------------- init TriCrypto compounder -------------------------

        uint256 _convexPid = 8;
        uint256 _poolType = 0; 

        _asset = TRICRYPTO_LP;
        _symbol = "fctrTriCrypto-fcGLP";
        _name = "Fortress Curve TriCrypto Concentrating to fcGLP";

        _underlyingAssets4[0] = USDT;
        _underlyingAssets4[1] = WBTC;
        _underlyingAssets4[2] = WETH;
        _underlyingAssets4[3] = ETH;

        _rewardAssets1[0] = CRV;

        address _booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
        address _crvRewards = IConvexBoosterArbi(_booster).poolInfo(_convexPid).rewards;
        bytes memory _settingsConfig = abi.encode(curveCryptoDescription, address(_owner), address(_platform), address(_fortressSwap), address(_ammOperations));
        bytes memory _boosterConfig = abi.encode(_convexPid, _booster, _crvRewards, _rewardAssets1);

        CurveGlpConcentrator curveGlpConcentrator = new CurveGlpConcentrator(ERC20(_asset), _name, _symbol, _settingsConfig, _boosterConfig, _compounder, _underlyingAssets4, _poolType);
        
        // ------------------------- update reg target asset -------------------------

        YieldOptimizersRegistry(_fortressArbiRegistry).updateConcentratorsTargetAssets(address(0), address(0), _compounder, address(0));

        // ------------------------- init registry -------------------------

        YieldOptimizersRegistry(_fortressArbiRegistry).registerAmmConcentrator(true, address(curveGlpConcentrator), address(_compounder), address(_asset));

        // ------------------------- whitelist in ammOperations -------------------------

        CurveArbiOperations(payable(_ammOperations)).updateWhitelist(address(curveGlpConcentrator), true);

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
