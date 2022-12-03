// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/compounders/curve/CurveCompounder.sol";
import "script/utils/InitBase.sol";
import "src/utils/FortressSwap.sol";
import "src/utils/FortressRegistry.sol";

contract InitETHfrxETH is InitBase {
    
    function _initializeETHfrxETH(address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // CRV --> ETH
        if (!(_swap.routeExists(CRV, ETH))) {
            _poolType1[0] = 5;

            _poolAddress1[0] = curveETHCRV;

            _fromList1[0] = CRV;

            _toList1[0] = ETH;

            _swap.updateRoute(CRV, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }
        
        // CVX --> ETH
        if (!(_swap.routeExists(CVX, ETH))) {
            _poolType1[0] = 5;

            _poolAddress1[0] = curveETHCVX;

            _fromList1[0] = CVX;

            _toList1[0] = ETH;

            _swap.updateRoute(CVX, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // CVX --> frxETH
        if (!(_swap.routeExists(CVX, frxETH))) {
            _poolType2[0] = 5;
            _poolType2[1] = 2;

            _poolAddress2[0] = curveETHCVX;
            _poolAddress2[1] = curveETHfrxETH;

            _fromList2[0] = CVX;
            _fromList2[1] = ETH;

            _toList2[0] = ETH;
            _toList2[1] = frxETH;

            _swap.updateRoute(CVX, frxETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // CRV --> frxETH
        if (!(_swap.routeExists(CRV, frxETH))) {
            _poolType2[0] = 5;
            _poolType2[1] = 2;

            _poolAddress2[0] = curveETHCRV;
            _poolAddress2[1] = curveETHfrxETH;

            _fromList2[0] = CRV;
            _fromList2[1] = ETH;

            _toList2[0] = ETH;
            _toList2[1] = frxETH;

            _swap.updateRoute(CRV, frxETH, _poolType2, _poolAddress2, _fromList2, _toList2);
        }

        // ETH --> frxETH
        if (!(_swap.routeExists(ETH, frxETH))) {
            _poolType1[0] = 2;

            _poolAddress1[0] = curveETHfrxETH;
            
            _fromList1[0] = ETH;
            
            _toList1[0] = frxETH;

            _swap.updateRoute(ETH, frxETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // frxETH --> ETH
        if (!(_swap.routeExists(frxETH, ETH))) {
            _poolType1[0] = 2;

            _poolAddress1[0] = curveETHfrxETH;
            
            _fromList1[0] = frxETH;
            
            _toList1[0] = ETH;

            _swap.updateRoute(frxETH, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ------------------------- init frxETH compounder -------------------------
        
        uint256 _convexPid = 128;
        uint256 _poolType = 5;
        address _asset = frxETHCRV;
        string memory _symbol = "fort-comp-cfrxETH";
        string memory _name = "Fortress Curve Compounder frxETH/ETH";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;

        // NOTE - make sure the order of underlying assets is the same as in Curve contract (Backend requirment) 
        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = frxETH;
        _underlyingAssets[1] = ETH;

        CurveCompounder curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, _platform, address(_fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        
        // ------------------------- init registry -------------------------

        FortressRegistry(_fortressRegistry).registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);

        return address(curveCompounder);
    }
}