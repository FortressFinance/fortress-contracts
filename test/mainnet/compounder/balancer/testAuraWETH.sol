// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "test/mainnet/compounder/balancer/BalancerCompounderBaseTest.sol";

contract testAuraWETH is Test, AddRoutes, BalancerCompounderBaseTest {

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 0;
        address _asset = BALANCER_WETHAURA;
        string memory _symbol = "fortress-bAuraEth";
        string memory _name = "Fortress Balancer AuraEth";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = BAL;
        _rewardAssets[1] = AURA;

        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = AURA;
        _underlyingAssets[1] = WETH;

        vm.startPrank(owner);
        // balancerCompounder = fortressFactory.launchBalancerCompounder(ERC20(BALANCER_WETHAURA), "Fortress Balancer AuraEth", "fortress-bAuraEth", platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);
        balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, owner, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);
        fortressRegistry.registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedAURA(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(AURA, _amount);
    }

    function testSingleUnwrappedWETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);

        _testSingleUnwrapped(WETH, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        assertTrue(true);
        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1.5 ether);

        _testRedeem(AURA, _amount);
    }

    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testWithdraw(AURA, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(AURA, _amount);
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

        _testNoSharesWithdraw(_amount, AURA);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, AURA);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(AURA);
    }
}