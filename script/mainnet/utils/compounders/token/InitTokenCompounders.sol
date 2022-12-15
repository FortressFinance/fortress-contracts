// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/mainnet/utils/compounders/token/InitAuraBalCompounder.sol";
import "script/mainnet/utils/compounders/token/InitCvxCrvCompounder.sol";

contract InitTokenCompounders is InitAuraBalCompounder, InitCvxCrvCompounder {

    function _initializeTokenCompounders(address _owner, address _fortressRegistry, address _fortressSwap, address _platform) internal returns (address _auraBalCompounder, address _cvxCrvCompounder) {
        
        // ------------------------- auraBAL -------------------------
        _auraBalCompounder = _initAuraBalCompounder(_owner, _fortressRegistry, _fortressSwap, _platform);

        // ------------------------- cvxCRV -------------------------
        _cvxCrvCompounder = _initCvxCrvCompounder(_owner, _fortressRegistry, _fortressSwap, _platform);
    }
}
