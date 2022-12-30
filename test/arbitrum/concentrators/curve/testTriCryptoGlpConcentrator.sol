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

    function testCorrectFlowUSDT(uint256 _amount) public {
        _testCorrectFlow(USDT, _amount, address(glpConcentrator));
    }

    function testCorrectFlowHarvestSingleUSDT(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(USDT, _amount, address(payable(glpConcentrator)), WETH);
    }

    function testMint(uint256 _amount) public {
        _testMint(USDT, _amount, address(glpConcentrator), WETH);
    }

    function testWithdraw(uint256 _amount) public {
        _testWithdraw(USDT, _amount, address(payable(glpConcentrator)));
    }

    function testRedeemUnderlyingAndClaimUSDT(uint256 _amount) public {
        _testRedeemUnderlyingAndClaim(USDT, _amount, address(payable(glpConcentrator)), USDT);
    }
}
