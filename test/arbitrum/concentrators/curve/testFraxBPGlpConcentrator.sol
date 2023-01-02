// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/curve/BaseCurveGlpConcentratorTest.sol";

import "script/arbitrum/utils/compounders/gmx/InitGlpCompounder.sol";
import "script/arbitrum/utils/concentrators/curve/InitFraxBPGlp.sol";

import "src/arbitrum/concentrators/curve/CurveGlpConcentrator.sol";
import "src/arbitrum/compounders/gmx/GlpCompounder.sol";

contract testFraxBPGlpConcentrator is BaseCurveGlpConcentratorTest, InitGlpCompounder, InitFraxBPGlp {

    using SafeERC20 for IERC20;

    GlpCompounder glpCompounder;
    CurveGlpConcentrator glpConcentrator;
    
    function setUp() public {
        
        _setUp();

        vm.startPrank(owner);
        
        address tempAddr = _initializeGlpCompounder(address(owner), platform, address(fortressRegistry), address(fortressSwap));
        glpCompounder = GlpCompounder(payable(tempAddr)); 
        
        tempAddr = _initializeFraxBPGlp(address(owner), address(fortressRegistry), address(fortressSwap), platform, address(glpCompounder));
        glpConcentrator = CurveGlpConcentrator(payable(tempAddr));

        vm.stopPrank();
    }

    function testCorrectFlowUSDC(uint256 _amount) public {
        _testCorrectFlow(USDC, _amount, address(glpConcentrator));
    }

    function testCorrectFlowFRAX(uint256 _amount) public {
        _testCorrectFlow(FRAX, _amount, address(glpConcentrator));
    }

    function testCorrectFlowHarvestSingleWETH(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(FRAX, _amount, address(payable(glpConcentrator)), WETH);
    }

    function testRedeemUnderlyingAndClaimFRAX(uint256 _amount) public {
        _testRedeemUnderlyingAndClaim(FRAX, _amount, address(payable(glpConcentrator)), FRAX);
    }

    function testRedeemUnderlyingAndClaimUSDC(uint256 _amount) public {
        _testRedeemUnderlyingAndClaim(USDC, _amount, address(payable(glpConcentrator)), USDC);
    }

    function testMint(uint256 _amount) public {
        _testMint(USDC, _amount, address(glpConcentrator), WETH);
    }

    function testWithdraw(uint256 _amount) public {
        _testWithdraw(USDC, _amount, address(payable(glpConcentrator)));
    }

    function testRedeemAndClaim(uint256 _amount) public {
        _testRedeemAndClaim(USDC, _amount, address(payable(glpConcentrator)));
    }

    function testTransfer(uint256 _amount) public {
        _testCorrectFlowTransfer(USDC, _amount, address(payable(glpConcentrator)));
    }

    function testDepositNoAsset(uint256 _amount) public {
        _testDepositNoAsset(_amount, USDC, address(payable(glpConcentrator)));
    }

    function testDepositWrongAsset(uint256 _amount) public {
        _testDepositWrongAsset(_amount, USDC, address(payable(glpConcentrator)));
    }

    function testWithdrawNoShare(uint256 _amount) public {
        _testWithdrawNoShare(_amount, USDC, address(payable(glpConcentrator)));
    }
}
