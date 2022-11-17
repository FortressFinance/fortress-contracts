// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "test/compounder/balancer/BalancerCompounderBaseTest.sol";

contract testWETHrETH is Test, AddRoutes, BalancerCompounderBaseTest {

    // wstETH/WETH - (https://info.balancer.xeonus.io/#/pools/0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080)

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 21;
        address _asset = BALANCER_RETHWETH;
        string memory _symbol = "fortress-bWETHrETH";
        string memory _name = "Fortress Balancer rETH/WETH";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = BAL;
        _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = rETH;
        _underlyingAssets[1] = WETH;

        vm.startPrank(owner);
        balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);
        fortressRegistry.registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedrETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(rETH, _amount);
    }

    function testSingleUnwrappedWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);

        _testSingleUnwrapped(WETH, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1.5 ether);

        _testRedeem(rETH, _amount);
    }

    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testWithdraw(rETH, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(rETH, _amount);
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

        _testNoSharesWithdraw(_amount, rETH);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, rETH);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(rETH);
    }
}