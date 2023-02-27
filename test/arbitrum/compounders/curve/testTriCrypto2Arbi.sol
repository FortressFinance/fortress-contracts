// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/compounders/curve/CurveCompounderBaseArbitrumTest.sol";
import "script/arbitrum/utils/compounders/curve/InitTriCryptoArbi.sol";

contract testTriCrypto2Arbi is CurveCompounderBaseArbitrumTest, InitTriCryptoArbi {

    // TriCrypto2 (https://curve.fi/tricrypto2)

    using SafeERC20 for IERC20;

    function setUp() public {
        
        _setUp();
        
        vm.startPrank(owner);
        address _curveCompounder = _initializeTriCrypto(owner, address(fortressArbiRegistry), address(fortressSwap), platform);
        vm.stopPrank();
        
        curveCompounder = CurveArbiCompounder(payable(_curveCompounder));
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedwBTC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(WBTC, _amount);
    }

    function testSingleUnwrappedUSDT(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(USDT, _amount);
    }

    function testSingleUnwrappedWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(WETH, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(WBTC, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testWithdraw(WBTC, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(WBTC, _amount);
    }

    function testDepositCap(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testDepositCap(WBTC, _amount);
    }

    // function testFortressRegistry() public {
    //     _testFortressRegistry();
    // }

    // // // ------------------------------------------------------------------------------------------
    // // // --------------------------------- test wrong flows ---------------------------------------
    // // // ------------------------------------------------------------------------------------------

    function testNoAssetsDeposit(uint256 _amount) public {
        _testNoAssetsDeposit(_amount);
    }

    function testNoAssetsMint(uint256 _amount) public {
        _testNoAssetsMint(_amount);
    }

    function testNoSharesWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesWithdraw(_amount, USDT);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, USDT);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        
        _testSingleUnwrappedDepositWrongAsset(USDC, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(WBTC);

    }
}