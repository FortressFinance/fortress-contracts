// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "test/compounder/curve/CurveCompounderBaseTest.sol";

contract testFXScvxFXS is Test, AddRoutes, CurveCompounderBaseTest {

    // cvxFXS/FXS - https://curve.fi/factory-crypto/18

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 72;
        uint256 _poolType = 2;
        address _asset = cvxFXSFXS_f;
        string memory _symbol = "fortress-ccvxFXS";
        string memory _name = "Fortress Curve cvxFXS";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        
        address[] memory _underlyingAssets = new address[](2);
        _underlyingAssets[0] = FXS;
        _underlyingAssets[1] = cvxFXS;

        vm.startPrank(owner);
        curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        fortressRegistry.registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedFXS(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1.5 ether);

        _testSingleUnwrapped(FXS, _amount);
    }

    function testSingleUnwrappedCvxFXS(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(cvxFXS, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(FXS, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 2 ether);

        _testWithdraw(FXS, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(FXS, _amount);
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

        _testNoSharesWithdraw(_amount, FXS);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, FXS);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(FXS);
    }
}