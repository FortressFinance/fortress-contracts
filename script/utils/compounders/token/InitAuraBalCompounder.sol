// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/compounders/balancer/AuraBalCompounder.sol";
import "script/utils/InitBase.sol";
import "src/utils/FortressSwap.sol";
import "src/utils/FortressRegistry.sol";

contract InitAuraBalCompounder is InitBase {
    
    function _initAuraBalCompounder(address _fortressRegistry, address _fortressSwap, address _platform) public returns (address) {

        // ------------------------- init fortress swap -------------------------

        FortressSwap _swap = FortressSwap(payable(_fortressSwap));

        // balancerETHBAL --> auraBAL
        if (!(_swap.routeExists(BALANCER_WETHBAL, auraBAL))) { 
            _poolType1[0] = 12;

            _poolAddress1[0] = BALANCER_ETHBAL_AURABAL;

            _fromList1[0] = BALANCER_WETHBAL;

            _toList1[0] = auraBAL;

            _swap.updateRoute(BALANCER_WETHBAL, auraBAL, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // auraBAL --> balancerETHBAL
        if (!(_swap.routeExists(auraBAL, BALANCER_WETHBAL))) { 
            _poolType1[0] = 12;

            _poolAddress1[0] = BALANCER_ETHBAL_AURABAL;

            _fromList1[0] = auraBAL;

            _toList1[0] = BALANCER_WETHBAL;

            _swap.updateRoute(auraBAL, BALANCER_WETHBAL, _poolType1, _poolAddress1, _fromList1, _toList1);
        }

        // ------------------------- init cvxCRV compounder -------------------------
        
        AuraBalCompounder auraBALCompounder = new AuraBalCompounder(_platform, address(_swap));

        // ------------------------- init registry -------------------------

        require(address(auraBALCompounder) != address(0), "InitCvxCrvCompounder: cvxCRVCompounder is the zero address");
        require(address(auraBAL) != address(0), "InitCvxCrvCompounder: cvxCRVCompounder is the zero address");
        FortressRegistry(_fortressRegistry).registerTokenCompounder(address(auraBALCompounder), auraBAL, "fort-auraBAL", "Fortress AuraBAL");

        return address(auraBALCompounder);
    }
}