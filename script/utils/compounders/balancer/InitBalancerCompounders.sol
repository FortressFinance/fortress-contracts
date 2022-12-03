// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "script/utils/compounders/balancer/InitWETHrETH.sol";
import "script/utils/compounders/balancer/InitWETHwstETH.sol";
import "script/utils/compounders/balancer/InitThreeETH.sol";

contract InitBalancerCompounders is InitWETHrETH, InitWETHwstETH, InitThreeETH {

    function _initializeBalancerCompounders(address _fortressFactory, address _fortressSwap, address _platform) internal returns (address _threeEthCompounder) {
        
        // ------------------------- rETH/WETH -------------------------
        _initializeWETHrETH(_fortressFactory, _fortressSwap, _platform);

        // ------------------------- wstETH/WETH -------------------------
        _initializeWETHwstETH(_fortressFactory, _fortressSwap, _platform);

        // ------------------------- 3ETH -------------------------
        _threeEthCompounder = _initializeThreeETH(_fortressFactory, _fortressSwap, _platform);
    }
}
