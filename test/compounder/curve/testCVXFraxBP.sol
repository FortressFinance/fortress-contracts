// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "test/compounder/curve/CurveCompounderBaseTest.sol";

contract testCVXFraxBP is Test, AddRoutes, CurveCompounderBaseTest {

    // CVX/crvFRAX (https://curve.fi/factory-crypto/95)

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 117;
        uint256 _poolType = 8;
        address _asset = CVXFRAXBPLP;
        string memory _symbol = "fortress-cCVXFraxBP";
        string memory _name = "Fortress Curve CVX/FraxBP";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        
        address[] memory _underlyingAssets = new address[](3);
        _underlyingAssets[0] = CVX;
        _underlyingAssets[1] = USDC;
        _underlyingAssets[2] = FRAX;

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

    function testSingleUnwrappedFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(FRAX, _amount);
    }

    function testSingleUnwrappedCVX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(CVX, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeemFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(FRAX, _amount);
    }

    function testRedeemUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(USDC, _amount);
    }

    function testWithdrawUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testWithdraw(USDC, _amount);
    }

    function testWithdrawFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testWithdraw(FRAX, _amount);
    }

    function testMintFRAX(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(FRAX, _amount);
    }

    function testMintUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(USDC, _amount);
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

        _testNoSharesWithdraw(_amount, CVX);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, USDC);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(CVX);
    }
}