// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/utils/concentrators/balancer/aurabal/InitWETHAURAConcentrator.sol";
import "script/utils/concentrators/balancer/eth/InitWETHAURAEthConcentrator.sol";

contract InitBalancerConcentrators is InitWETHAURAConcentrator, InitWETHAURAEthConcentrator {

    function _initializeBalancerAuraBALConcentrators(address _fortressFactory, address _fortressSwap, address _platform, address _compounder) internal {
        
        // ------------------------- auraBAL Concentrators -------------------------
        
        // WETH/AURA
        _initWETHAURAConcentrator(_fortressFactory, _fortressSwap, _platform, _compounder);
    }

    function _initializeBalancerEthConcentrators(address _fortressFactory, address _fortressSwap, address _platform, address _compounder) internal {
            
            // ------------------------- eth Concentrators -------------------------
            
            // WETH/AURA
            _initWETHAURAEthConcentrator(_fortressFactory, _fortressSwap, _platform, _compounder);
    }
}
