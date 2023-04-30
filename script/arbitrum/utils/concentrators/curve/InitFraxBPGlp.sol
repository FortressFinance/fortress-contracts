// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/concentrators/curve/CurveGlpConcentrator.sol";
import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/FortressArbiRegistry.sol";
import "src/arbitrum/utils/CurveArbiOperations.sol";

contract InitFraxBPGlp is InitBaseArbi {
    
    function _initializeFraxBPGlp(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform, address _compounder, address _ammOperations) public returns (address) {
       
        _initSwapFraxBPGlp(_fortressSwap);
        
        // ------------------------- init TriCrypto compounder -------------------------

        uint256 _convexPid = 10;
        // uint256 _poolType = 1; 

        _asset = FRAXBP_LP;
        _symbol = "fctrFraxBP-fcGLP";
        _name = "Fortress Curve FraxBP Concentrating into fcGLP";

        _underlyingAssets2[0] = FRAX;
        _underlyingAssets2[1] = USDC;
        
        _rewardAssets1[0] = CRV;

        address _booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
        address _crvRewards = IConvexBoosterArbi(_booster).poolInfo(_convexPid).rewards;
        bytes memory _settingsConfig = abi.encode(curveStableDescription, address(_owner), address(_platform), address(_fortressSwap), address(_ammOperations));
        bytes memory _boosterConfig = abi.encode(_convexPid, _booster, _crvRewards, _rewardAssets1);

        CurveGlpConcentrator curveGlpConcentrator = new CurveGlpConcentrator(ERC20(_asset), _name, _symbol, _settingsConfig, _boosterConfig, _compounder, _underlyingAssets2, 1); // 1 is poolType

        // ------------------------- update reg target asset -------------------------

        YieldOptimizersRegistry(_fortressArbiRegistry).updateConcentratorsTargetAssets(address(0), address(0), _compounder, address(0));

        // ------------------------- init registry -------------------------

        YieldOptimizersRegistry(_fortressArbiRegistry).registerAmmConcentrator(true, address(curveGlpConcentrator), address(_compounder), address(_asset));

        // ------------------------- whitelist in ammOperations -------------------------

        CurveArbiOperations(payable(_ammOperations)).updateWhitelist(address(curveGlpConcentrator), true);

        return address(curveGlpConcentrator);
    }

    function _initSwapFraxBPGlp(address _fortressSwap) internal {

        FortressArbiSwap _swap = FortressArbiSwap(payable(_fortressSwap));

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
    }
}
