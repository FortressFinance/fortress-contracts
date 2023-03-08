// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "script/arbitrum/utils/compounders/curve/InitTriCryptoArbi.sol";
import "script/arbitrum/utils/compounders/curve/InitCurveBPArbi.sol";
import "script/arbitrum/utils/compounders/curve/InitFraxBPArbi.sol";

contract InitCurveCompounders is InitTriCryptoArbi, InitCurveBPArbi, InitFraxBPArbi {
    
    function _initializeCurveCompounders(address _owner, address _fortressArbiRegistry, address _fortressSwap, address _platform, address _ammOperations) internal {
        
        // ------------------------- TriCrypto -------------------------
        
        _initializeTriCrypto(_owner, _fortressArbiRegistry, _fortressSwap, _platform, _ammOperations);

        // // ------------------------- Crv BP -------------------------

        _initializeCurveBP(_owner, _fortressArbiRegistry, _fortressSwap, _platform, _ammOperations);

        // // ------------------------- Frax BP -------------------------

        // _initializeFraxBP(_owner, _fortressArbiRegistry, _fortressSwap, _platform);
    }
}
