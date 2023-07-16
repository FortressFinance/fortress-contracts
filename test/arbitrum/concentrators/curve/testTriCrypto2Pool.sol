// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/concentrators/curve/BaseCurveConcentratorTest.sol";

import {InitTriCrypto2Pool} from "script/arbitrum/utils/concentrators/curve/InitTriCrypto2Pool.sol";

import {TriCryptoTo2Pool} from "src/arbitrum/concentrators/curve/TriCryptoTo2Pool.sol";
import {CurveArbiCompounder} from "src/arbitrum/compounders/curve/CurveArbiCompounder.sol";

contract testTriCrypto2Pool is BaseCurveConcentratorTest, InitTriCrypto2Pool {

    using SafeERC20 for IERC20;

    CurveArbiCompounder bpCompounder;
    TriCryptoTo2Pool tricryptoConcentrator;
    
    function setUp() public {

        _setUp();

        vm.startPrank(owner);
        
        bpCompounder = CurveArbiCompounder(payable(fc2Pool));
        
        address tempAddr = _initializeTriCrypto2Pool(address(owner), address(fortressRegistry), address(fortressSwap), platform, fc2Pool, address(ammOperations));
        tricryptoConcentrator = TriCryptoTo2Pool(payable(tempAddr));

        vm.stopPrank();

        (,,,,,, compounder,,,) = AMMConcentratorBase(address(tricryptoConcentrator)).settings();
    }

    function testCorrectFlowETH(uint256 _amount) public {
        _testCorrectFlow(ETH, _amount, address(tricryptoConcentrator));
    }

    function testCorrectFlowUSDT(uint256 _amount) public {
        _testCorrectFlow(USDT, _amount, address(tricryptoConcentrator));
    }

    function testCorrectFlowWBTC(uint256 _amount) public {
        _testCorrectFlow(WBTC, _amount, address(tricryptoConcentrator));
    }

    function testCorrectFlowWETH(uint256 _amount) public {
        _testCorrectFlow(WETH, _amount, address(tricryptoConcentrator));
    }

    function testCorrectFlowHarvestSingleUSDT(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(USDT, _amount, address(payable(tricryptoConcentrator)), USDT);
    }
    
    function testCorrectFlowHarvestSingleWBTC(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(WBTC, _amount, address(payable(tricryptoConcentrator)), USDC);
    }

    function testCorrectFlowHarvestSingleWETH(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(WETH, _amount, address(payable(tricryptoConcentrator)), USDT);
    }

    function testCorrectFlowHarvestSingleWETHUSDC(uint256 _amount) public {
        _testCorrectFlowHarvestWithUnderlying(WETH, _amount, address(payable(tricryptoConcentrator)), USDC);
    }

    function testRedeemUnderlyingAndClaimUSDT(uint256 _amount) public {
        _testRedeemUnderlyingAndClaim(USDT, _amount, address(payable(tricryptoConcentrator)), USDT);
    }

    function testDepositCap(uint256 _amount) public {
        _testDepositCap(USDT, _amount, address(payable(tricryptoConcentrator)));
    }

    function testMint(uint256 _amount) public {
        _testMint(USDT, _amount, address(tricryptoConcentrator), USDT);
    }

    function testWithdraw(uint256 _amount) public {
        _testWithdraw(USDT, _amount, address(payable(tricryptoConcentrator)));
    }

    function testRedeemAndClaim(uint256 _amount) public {
        _testRedeemAndClaim(USDT, _amount, address(payable(tricryptoConcentrator)));
    }

    function testTransfer(uint256 _amount) public {
        _testCorrectFlowTransfer(USDT, _amount, address(payable(tricryptoConcentrator)));
    }

    function testDepositNoAsset(uint256 _amount) public {
        _testDepositNoAsset(_amount, USDT, address(payable(tricryptoConcentrator)));
    }

    function testDepositWrongAsset(uint256 _amount) public {
        _testDepositWrongAsset(_amount, CRV, address(payable(tricryptoConcentrator)));
    }

    function testWithdrawNoShare(uint256 _amount) public {
        _testWithdrawNoShare(_amount, USDT, address(payable(tricryptoConcentrator)));
    }
}
