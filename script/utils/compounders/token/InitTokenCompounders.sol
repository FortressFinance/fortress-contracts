// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/utils/compounders/token/InitAuraBalCompounder.sol";
import "script/utils/compounders/token/InitCvxCrvCompounder.sol";

contract InitTokenCompounders is InitAuraBalCompounder, InitCvxCrvCompounder {

    function _initializeTokenCompounders(address _fortressFactory, address _fortressSwap, address _platform) internal returns (address _auraBalCompounder, address _cvxCrvCompounder) {
        
        // ------------------------- auraBAL -------------------------
        _auraBalCompounder = _initAuraBalCompounder(_fortressFactory, _fortressSwap, _platform);

        // ------------------------- cvxCRV -------------------------
        _cvxCrvCompounder = _initCvxCrvCompounder(_fortressFactory, _fortressSwap, _platform);
    }
}
