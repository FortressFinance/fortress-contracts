// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/arbitrum/compounders/balancer/BalancerCompounderBaseTest.sol";
import "script/arbitrum/utils/compounders/balancer/InitWstETHwETH.sol";

contract testArbiWstETHwETH is BalancerArbiCompounderBaseTest, InitWstETHwETHArbi {

    using SafeERC20 for IERC20;

    function setUp() public {
        
        _setUp();

        vm.startPrank(owner);
        address _balancerCompounder = _initializeWstETHwETH(owner, address(yieldOptimizersRegistry), address(fortressSwap), platform, address(ammOperations));
        vm.stopPrank();
        
        balancerCompounder = BalancerArbiCompounder(payable(_balancerCompounder));
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedWstETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testSingleUnwrapped(WSTETH, _amount);
    }

    function testSingleUnwrappedWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testSingleUnwrapped(WETH, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testDeposit(_amount);
    }

    function testRedeemWstETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testRedeem(WSTETH, _amount);
    }

    function testRedeemWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testRedeem(WETH, _amount);
    }
    
    function testWithdrawWstETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testWithdraw(WSTETH, _amount);
    }

    function testWithdrawWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testWithdraw(WETH, _amount);
    }

    function testMintWstETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);
 
        _testMint(WSTETH, _amount);
    }

    function testMintWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);
 
        _testMint(WETH, _amount);
    }

    function testDepositCapWstETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testDepositCap(WSTETH, _amount);
    }

    function testDepositCapWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 10 ether);

        _testDepositCap(WETH, _amount);
    }
    
    function testFortressRegistry() public {
        _testFortressRegistry();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test wrong flows ---------------------------------------
    // ------------------------------------------------------------------------------------------

    function testNoAssetsDeposit(uint256 _amount) public {
        _testNoAssetsDeposit(_amount);
    }

    function testNoAssetsMint(uint256 _amount) public {
        _testNoAssetsMint(_amount);
    }

    function testNoSharesWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesWithdraw(_amount, WSTETH);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, WSTETH);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(WSTETH);

    }
}