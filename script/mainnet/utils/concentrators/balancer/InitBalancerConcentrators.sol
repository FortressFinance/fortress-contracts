// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/mainnet/utils/concentrators/balancer/aurabal/InitWETHAURAConcentrator.sol";
import "script/mainnet/utils/concentrators/balancer/eth/InitWETHAURAEthConcentrator.sol";

contract InitBalancerConcentrators is InitWETHAURAConcentrator, InitWETHAURAEthConcentrator {

    function _initializeBalancerAuraBALConcentrators(address _owner, address _fortressRegistry, address _fortressSwap, address _platform, address _compounder) internal {
        
        // ------------------------- auraBAL Concentrators -------------------------
        
        // WETH/AURA
        _initWETHAURAConcentrator(_owner, _fortressRegistry, _fortressSwap, _platform, _compounder);
    }

    function _initializeBalancerEthConcentrators(address _owner, address _fortressRegistry, address _fortressSwap, address _platform, address _compounder) internal {
            
            // ------------------------- eth Concentrators -------------------------
            
            // WETH/AURA
            _initWETHAURAEthConcentrator(_owner, _fortressRegistry, _fortressSwap, _platform, _compounder);
    }
}
