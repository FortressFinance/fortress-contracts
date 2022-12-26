// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/curve/CurveArbiCompounder.sol";
import "script/arbitrum/utils/InitBase.sol";
import "src/arbitrum/utils/FortressArbiSwap.sol";
import "src/arbitrum/utils/FortressArbiRegistry.sol";

contract InitFraxBPArbi is InitBaseArbi {

    function _initializeFraxBP(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform) public returns (address) {

        _initSwapFraxBP(_fortressSwap);
        
        // ------------------------- init TriCrypto compounder -------------------------
        
        // vst/frax - 0
        // usdc/usdt - 1
        // crvEURSUSD - 4
        uint256 _convexPid = 5;
        uint256 _poolType = 1; 
        address _asset = FRAXBP_LP;
        string memory _symbol = "fortFraxBP";
        string memory _name = "Fortress Curve FraxBP";

        address[] memory _rewardAssets = new address[](1);
        _rewardAssets[0] = CRV;
        // _rewardAssets[1] = CVX;

        // NOTE - make sure the order of underlying assets is the same as in Curve contract (Backend requirment) 
        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = FRAX;
        _underlyingAssets[1] = USDC;

        CurveArbiCompounder curveCompounder = new CurveArbiCompounder(ERC20(_asset), _name, _symbol, _owner, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        
        // ------------------------- init registry -------------------------

        FortressArbiRegistry(_fortressArbiRegistry).registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);
        
        return address(curveCompounder);
    }

    function _initSwapFraxBP(address _fortressSwap) internal {

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
