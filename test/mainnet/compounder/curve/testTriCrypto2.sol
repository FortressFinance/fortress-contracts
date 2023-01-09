// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "test/mainnet/compounder/curve/CurveCompounderBaseTest.sol";

contract testTriCrypto2 is Test, AddRoutes, CurveCompounderBaseTest {

    // TriCrypto2 (https://curve.fi/tricrypto2)

    using SafeERC20 for IERC20;
 
    function setUp() public {
        
        _setUp();

        uint256 _convexPid = 38;
        uint256 _poolType = 0;
        address _asset = TRICRYPTOLP;
        string memory _symbol = "fortress-cTriCrypto";
        string memory _name = "Fortress Curve TriCrypto2";

        address[] memory _rewardAssets = new address[](2);
        _rewardAssets[0] = CVX;
        _rewardAssets[1] = CRV;
        
        address[] memory _underlyingAssets = new address[](3);
        _underlyingAssets[0] = ETH;
        _underlyingAssets[1] = USDT;
        _underlyingAssets[2] = wBTC;

        vm.startPrank(owner);
        // curveCompounder = fortressFactory.launchCurveCompounder(ERC20(TRICRYPTOLP), "Fortress Curve TriCrypto2", "fortress-cTriCrypto", platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        curveCompounder = new CurveCompounder(ERC20(_asset), _name, _symbol, owner, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets, _poolType);
        fortressRegistry.registerCurveCompounder(address(curveCompounder), _asset, _symbol, _name, _underlyingAssets);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------------------------------
    // --------------------------------- test correct flow --------------------------------------
    // ------------------------------------------------------------------------------------------
    
    function testSingleUnwrappedwBTC(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(wBTC, _amount);
    }

    function testSingleUnwrappedUSDT(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testSingleUnwrapped(USDT, _amount);
    }

    function testSingleUnwrappedETH(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testSingleUnwrappedETH(_amount);
    }

    function testDeposit(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testDeposit(_amount);
    }

    function testRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testRedeem(wBTC, _amount);
    }
    
    function testWithdraw(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 1 ether);

        _testWithdraw(wBTC, _amount);
    }

    function testMint(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
        _testMint(wBTC, _amount);
    }

    function testDepositCap(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testDepositCap(wBTC, _amount);
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

        _testNoSharesWithdraw(_amount, USDT);
    }

    function testNoSharesRedeem(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 5 ether);

        _testNoSharesRedeem(_amount, USDT);
    }

    function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
        vm.assume(_amount > 0.01 ether && _amount < 99 ether);
        _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
    }

    function testHarvestNoBounty() public {
        _testHarvestNoBounty(wBTC);
    }
}