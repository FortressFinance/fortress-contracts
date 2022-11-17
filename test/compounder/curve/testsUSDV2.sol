// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// https://curve.fi/factory/174

import "test/compounder/curve/CurveCompounderBaseTest.sol";

contract testsUSDV2 is Test, AddRoutes, CurveCompounderBaseTest {

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 4;
        uint256 _poolType = 9;
        address _asset = SUSDV2LP;
        string memory _symbol = "fortress-csUSDV2";
        string memory _name = "Fortress Curve sUSD V2";

        address[] memory _rewardAssets = new address[](3);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        _rewardAssets[2] = SNX;
        
        address[] memory _underlyingAssets = new address[](4);
        _underlyingAssets[0] = sUSD;
        _underlyingAssets[1] = USDC;
        _underlyingAssets[2] = USDT;
        _underlyingAssets[3] = DAI;

        vm.startPrank(owner);
        curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        fortressRegistry.registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedsUSD(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrapped(sUSD, _amount);
    }

    function testSingleUnwrappedUSDT(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrapped(USDT, _amount);
    }

    function testSingleUnwrappedDAI(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrapped(DAI, _amount);
    }

    function testSingleUnwrappedUSDC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrapped(USDC, _amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(sUSD, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testWithdraw(sUSD, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(sUSD, _amount);
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

        _testNoSharesWithdraw(_amount, sUSD);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, sUSD);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(sUSD);
    }
}