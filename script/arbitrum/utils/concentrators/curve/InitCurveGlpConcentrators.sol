// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "script/arbitrum/utils/concentrators/curve/InitTriCryptoGlp.sol";
import "script/arbitrum/utils/concentrators/curve/InitFraxBPGlp.sol";

contract InitCurveGlpConcentrators is InitTriCryptoGlp, InitFraxBPGlp {
    
    function _initializeCurveConcentrators(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform, address _compounder, address _ammOperations) internal {
        
        // ------------------------- TriCrypto -------------------------
        
        _initializeTriCryptoGlp(_owner, _fortressArbiRegistry, _fortressSwap, _platform, _compounder, _ammOperations);

        // ------------------------- FraxBP -------------------------

        // _initializeFraxBPGlp(_owner, _fortressArbiRegistry, _fortressSwap, _platform, _compounder);
    }
}
