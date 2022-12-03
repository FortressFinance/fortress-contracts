// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/compounders/curve/CvxCrvCompounder.sol";
import "script/utils/InitBase.sol";
import "src/utils/FortressSwap.sol";
import "src/utils/FortressRegistry.sol";

contract InitCvxCrvCompounder is InitBase {
    
    function _initCvxCrvCompounder(address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // CRV --> cvxCRV
        if (!(_swap.routeExists(CRV, cvxCRV))) { 
            _poolType1[0] = 2;

            _poolAddress1[0] = curveCRVcvxCRV;

            _fromList1[0] = CRV;

            _toList1[0] = cvxCRV;

            _swap.updateRoute(CRV, cvxCRV, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // cvxCRV --> CRV
        if (!(_swap.routeExists(cvxCRV, CRV))) { 
            _poolType1[0] = 2;

            _poolAddress1[0] = curveCRVcvxCRV;

            _fromList1[0] = cvxCRV;

            _toList1[0] = CRV;

            _swap.updateRoute(cvxCRV, CRV, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // CVX --> ETH
        if (!(_swap.routeExists(CVX, ETH))) { 
            _poolType1[0] = 5;

            _poolAddress1[0] = curveETHCVX;

            _fromList1[0] = CVX;

            _toList1[0] = ETH;

            _swap.updateRoute(CVX, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // USDT --> ETH
        if (!(_swap.routeExists(USDT, ETH))) { 
            _poolType1[0] = 4;

            _poolAddress1[0] = TRICRYPTO;
            
            _fromList1[0] = USDT;
            
            _toList1[0] = ETH;

            _swap.updateRoute(USDT, ETH, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ETH --> CRV
        if (!(_swap.routeExists(ETH, CRV))) { 
            _poolType1[0] = 5;

            _poolAddress1[0] = curveETHCRV;

            _fromList1[0] = ETH;

            _toList1[0] = CRV;

            _swap.updateRoute(ETH, CRV, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ------------------------- init cvxCRV compounder -------------------------
        
        CvxCrvCompounder cvxCRVCompounder = new CvxCrvCompounder(_platform, address(_swap));

        // ------------------------- init registry -------------------------

        require(address(cvxCRVCompounder) != address(0), "InitCvxCrvCompounder: cvxCRVCompounder is the zero address");
        require(address(cvxCRV) != address(0), "InitCvxCrvCompounder: cvxCRVCompounder is the zero address");
        FortressRegistry(_fortressRegistry).registerTokenCompounder(address(cvxCRVCompounder), cvxCRV, "fort-cvxCRV", "Fortress cvxCRV");

        return address(cvxCRVCompounder);
    }
}