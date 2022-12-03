// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/utils/concentrators/curve/cvxcrv/InitTricryptoConcentrator.sol";
import "script/utils/concentrators/curve/eth/InitTricryptoEthConcentrator.sol";

contract InitCurveConcentrators is InitTricryptoConcentrator, InitTricryptoEthConcentrator {

    function _initializeCurveCvxCrvConcentrators(address _fortressFactory, address _fortressSwap, address _platform, address _compounder) internal {
        
        // Tricrypto - WETH/USDT/WBTC
        _initTricryptoConcentrator(_fortressFactory, _fortressSwap, _platform, _compounder);
    }

    function _initializeCurveEthConcentrators(address _fortressFactory, address _fortressSwap, address _platform, address _compounder) internal {
        
        // Tricrypto - ETH/USDT/WBTC
        _initTricryptoEthConcentrator(_fortressFactory, _fortressSwap, _platform, _compounder);
    }
}
