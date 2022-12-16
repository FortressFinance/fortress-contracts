// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

import "script/arbitrum/utils/InitBase.sol";

contract InitGlpCompounder is InitBase {
    
    function _initializeGlpCompounder(address _owner, address _platform, address _registry) public returns (address) {

        /// @notice The address of sGLP token.
        address sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;

        GlpCompounder _glpCompounder = new GlpCompounder(_owner, _platform, address(0));

        FortressArbiRegistry(_registry).registerTokenCompounder(address(_glpCompounder), sGLP, "fortGLP", "Fortress GLP");
        
        return address(_glpCompounder);
    }
}