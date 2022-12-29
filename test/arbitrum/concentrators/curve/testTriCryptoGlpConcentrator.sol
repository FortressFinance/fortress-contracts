// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/curve/BaseCurveGlpConcentratorTest.sol";

import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";
import "script/arbitrum/utils/concentrators/curve/InitTriCryptoGlp.sol";

import "src/arbitrum/concentrators/curve/CurveGlpConcentrator.sol";
import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

contract testTriCryptoGlpConcentrator is BaseCurveGlpConcentratorTest, InitGlpCompounder, InitTriCryptoGlp {

    using SafeERC20 for IERC20;

    GlpCompounder glpCompounder;
    CurveGlpConcentrator glpConcentrator;
    
    function setUp() public {
        
        _setUp();

        vm.startPrank(owner);
        
        address tempAddr = _initializeGlpCompounder(address(owner), platform, address(fortressRegistry), address(fortressSwap));
        glpCompounder = GlpCompounder(payable(tempAddr)); 
        
        tempAddr = _initializeTriCryptoGlp(address(owner), address(fortressRegistry), address(fortressSwap), platform, address(glpCompounder));
        glpConcentrator = CurveGlpConcentrator(payable(tempAddr));

        vm.stopPrank();
    }

    function testTesty(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        assertTrue(true);
        _testCorrectFlow(USDT, _amount, address(glpConcentrator));
    }
}
