// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

contract InitGlpCompounder {
    
    function _initializeGlpCompounder(address _owner, address _platform) public returns (address) {

        GlpCompounder _glpCompounder = new GlpCompounder(_owner, _platform, address(0));
        
        return address(_glpCompounder);
    }
}