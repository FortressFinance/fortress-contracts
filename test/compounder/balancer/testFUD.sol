// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "test/compounder/balancer/BalancerCompounderBaseTest.sol";

contract testFUD is Test, AddRoutes, BalancerCompounderBaseTest {

    // FIAT/USDC/DAI

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 17;
        address _asset = BALANCER_FIATUSDCDAI;
        string memory _symbol = "fortress-bFUD";
        string memory _name = "Fortress Balancer FIAT/USDC/DAI";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = BAL;
        _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](3);
        _underlyingAssets[0] = FIAT;
        _underlyingAssets[1] = USDC;
        _underlyingAssets[2] = DAI;

        vm.startPrank(owner);
        balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);
        fortressRegistry.registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedFIAT(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(FIAT, _amount);
    }

    function testSingleUnwrappedUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);

        _testSingleUnwrapped(USDC, _amount);
    }

    function testSingleUnwrappedDAI(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);

        _testSingleUnwrapped(DAI, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1.5 ether);

        _testRedeem(FIAT, _amount);
    }

    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testWithdraw(FIAT, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);
 
        _testMint(FIAT, _amount);
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

        _testNoSharesWithdraw(_amount, FIAT);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, FIAT);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(FIAT);
    }
}