// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/compounders/curve/CurveCompounderBaseArbitrumTest.sol";
import "script/arbitrum/utils/compounders/curve/InitCurveBPArbi.sol";

contract testCurveBPArbi is CurveCompounderBaseArbitrumTest, InitCurveBPArbi {

    using SafeERC20 for IERC20;
    
    function setUp() public {
        
        _setUp();
        
        // vm.startPrank(owner);
        // address _curveCompounder = _initializeCurveBP(owner, address(fortressArbiRegistry), address(fortressSwap), platform, address(ammOperations));
        // vm.stopPrank();
        
        // curveCompounder = CurveArbiCompounder(payable(_curveCompounder));
    }

    function testSanity() public {
        assertTrue(true);
        vm.startPrank(owner);
        address _curveCompounder = _initializeCurveBP(owner, address(fortressArbiRegistry), address(fortressSwap), platform, address(ammOperations));
        vm.stopPrank();
        
        curveCompounder = CurveArbiCompounder(payable(_curveCompounder));
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedUSDT(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(USDT, _amount);
    }

    function testSingleUnwrappedUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(USDC, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
        
        _testRedeem(USDC, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testWithdraw(USDC, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(USDC, _amount);
    }

    function testDepositCap(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testDepositCap(USDC, _amount);
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

        _testNoSharesWithdraw(_amount, USDC);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, USDC);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        
        _testSingleUnwrappedDepositWrongAsset(WETH, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(USDC);

    }
}