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

    function testCorrectFlowWBTC(uint256 _amount) public {
        _testCorrectFlow(WBTC, _amount, address(glpConcentrator));
    }

    function testCorrectFlowWETH(uint256 _amount) public {
        _testCorrectFlow(WETH, _amount, address(glpConcentrator));
    }

    function testCorrectFlowHarvestSingleUSDT(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(USDT, _amount, address(payable(glpConcentrator)), WETH);
    }
    
    function testCorrectFlowHarvestSingleWBTC(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(WBTC, _amount, address(payable(glpConcentrator)), WBTC);
    }

    // function testCorrectFlowHarvestSingleWETH(uint256 _amount) public {
    //     _testCorrectFlowHarvestWithUnderlying(WETH, _amount, address(payable(glpConcentrator)), USDT);
    // }

    // function testCorrectFlowHarvestSingleWETHUSDC(uint256 _amount) public {
    //     _testCorrectFlowHarvestWithUnderlying(WETH, _amount, address(payable(glpConcentrator)), USDC);
    // }

    // function testCorrectFlowHarvestSingleWETHFRAX() public {
    //     // vm.assume(_amount > 0.01 ether && _amount < 1 ether);
    //     uint256 _amount = 1 ether;

    //     _testCorrectFlowHarvestWithUnderlying(WETH, _amount, address(payable(glpConcentrator)), FRAX);
    // }

    function testRedeemUnderlyingAndClaimUSDT(uint256 _amount) public {
        _testRedeemUnderlyingAndClaim(USDT, _amount, address(payable(glpConcentrator)), USDT);
    }

    function testDepositCap(uint256 _amount) public {
        _testDepositCap(USDT, _amount, address(payable(glpConcentrator)));
    }

    function testMint(uint256 _amount) public {
        _testMint(USDT, _amount, address(glpConcentrator), WETH);
    }

    function testWithdraw(uint256 _amount) public {
        _testWithdraw(USDT, _amount, address(payable(glpConcentrator)));
    }

    function testRedeemAndClaim(uint256 _amount) public {
        _testRedeemAndClaim(USDT, _amount, address(payable(glpConcentrator)));
    }

    function testTransfer(uint256 _amount) public {
        _testCorrectFlowTransfer(USDT, _amount, address(payable(glpConcentrator)));
    }

    function testDepositNoAsset(uint256 _amount) public {
        _testDepositNoAsset(_amount, USDT, address(payable(glpConcentrator)));
    }

    function testDepositWrongAsset(uint256 _amount) public {
        _testDepositWrongAsset(_amount, CRV, address(payable(glpConcentrator)));
    }

    function testWithdrawNoShare(uint256 _amount) public {
        _testWithdrawNoShare(_amount, USDT, address(payable(glpConcentrator)));
    }
}
