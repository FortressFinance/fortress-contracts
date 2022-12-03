// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/utils/compounders/curve/InitPETH.sol";
import "script/utils/compounders/curve/InitFXScvxFXS.sol";
import "script/utils/compounders/curve/InitETHfrxETH.sol";

contract InitCurveCompounders is InitPETH, InitFXScvxFXS, InitETHfrxETH {

    function _initializeCurveCompounders(address _fortressFactory, address _fortressSwap, address _platform) internal returns (address frxEthCompounder) {
        
        // ------------------------- pETH/ETH -------------------------
        _initializePETH(_fortressFactory, _fortressSwap, _platform);

        // ------------------------- cvxFXS/FXS -------------------------
        _initializeFXScvxFXS(_fortressFactory, _fortressSwap, _platform);

        // ------------------------- ETH/frxETH -------------------------
        frxEthCompounder = _initializeETHfrxETH(_fortressFactory, _fortressSwap, _platform);
    }
}
