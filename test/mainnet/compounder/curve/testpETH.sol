// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/mainnet/compounder/curve/CurveCompounderBaseTest.sol";

contract testpETH is Test, AddRoutes, CurveCompounderBaseTest {

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 122;
        uint256 _poolType = 5;
        address _asset = pETH_ETH_f;
        string memory _symbol = "fortress-cpETH";
        string memory _name = "Fortress Curve pETH";

        address[] memory _rewardAssets = new address[](3);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        _rewardAssets[2] = JPEG;

        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = pETH;
        _underlyingAssets[1] = ETH;

        vm.startPrank(owner);
        // curveCompounder = fortressFactory.launchCurveCompounder(ERC20(pETH_ETH_f), "Fortress Curve pETH", "fortress-cpETH", platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, owner, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        fortressRegistry.registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedPETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrapped(pETH, _amount);
    }

    function testSingleUnwrappedETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrappedETH(_amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(pETH, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testWithdraw(pETH, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(pETH, _amount);
    }

    function testDepositCap(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testDepositCap(pETH, _amount);
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

        _testNoSharesWithdraw(_amount, pETH);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, pETH);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(pETH);
    }
}