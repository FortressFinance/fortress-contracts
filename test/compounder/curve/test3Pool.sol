// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "test/compounder/curve/CurveCompounderBaseTest.sol";

contract test3Pool is Test, AddRoutes, CurveCompounderBaseTest {

    // USDC/USDT/DAI (https://curve.fi/3pool)

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 9;
        uint256 _poolType = 7;
        address _asset = triCRV;
        string memory _symbol = "fortress-cCurveBP";
        string memory _name = "Fortress Curve Curve BP";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        
        address[] memory _underlyingAssets = new address[](3);
        _underlyingAssets[0] = USDC;
        _underlyingAssets[1] = USDT;
        _underlyingAssets[2] = DAI;

        vm.startPrank(owner);
        curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        fortressRegistry.registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1.5 ether);

        _testSingleUnwrapped(USDC, _amount);
    }

    function testSingleUnwrappedDAI(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(DAI, _amount);
    }

    function testSingleUnwrappedUSDT(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(USDT, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(DAI, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testWithdraw(DAI, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(DAI, _amount);
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

        _testNoSharesWithdraw(_amount, DAI);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, DAI);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(DAI);
    }
}