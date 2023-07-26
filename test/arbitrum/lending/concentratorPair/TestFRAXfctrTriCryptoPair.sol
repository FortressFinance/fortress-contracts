// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FortressTriCryptoOracle} from "src/shared/lending/oracles/FortressTriCryptoOracle.sol";

import {ICompounder} from "src/shared/fortress-interfaces/ICompounder.sol";

import {ConcentratorLendingPair} from "src/shared/lending/ConcentratorLendingPair.sol";
import {TriCryptoTo2Pool} from "src/arbitrum/concentrators/curve/TriCryptoTo2Pool.sol";
import {InitTriCrypto2Pool} from "script/arbitrum/utils/concentrators/curve/InitTriCrypto2Pool.sol";

import "test/arbitrum/lending/BaseTest.sol";
import "script/arbitrum/lending/InitFraxfcTriCryptoPair.s.sol";

contract TestFRAXfctrTriCryptoPair is BaseTest, InitTriCrypto2Pool {

    FortressTriCryptoOracle oracle;
    ConcentratorLendingPair lendingPair;
    TriCryptoTo2Pool fctrTriCrypto;

    function setUp() public {

        _setUp();
 
        _addFraxWethRouteToSwap();

        oracle = new FortressTriCryptoOracle(address(owner),address(fcTriCrypto)); //0x32ED4f40ce345Eca65F24735Ad9D35c7fF3460E5

        // --------------------------------- deploy collateral (fctrTricrypto) ---------------------------------

        vm.startPrank(owner);
        address fortressRegistry = address(0);
        address tempAddr = _initializeTriCrypto2Pool(address(owner), fortressRegistry, address(fortressSwap), platform, fc2Pool, address(ammOperations));
        fctrTriCrypto = TriCryptoTo2Pool(payable(tempAddr));
        vm.stopPrank();

        // --------------------------------- deploy pair ---------------------------------

        // Frax asset (1e18 precision), fcTriCrypto collateral (1e18 precision)
        ERC20 _asset = ERC20(address(FRAX)); // asset
        address _collateral = address(fctrTriCrypto); // collateral
        string memory _name = "Fortress FRAX/fctrTriCrypto Lending Pair";
        string memory _symbol = "fFRAX/fctrTriCrypto";
        address _oracleMultiply = address(USD_FRAX_FEED); // denominator oracle (1e8 precision)
        address _oracleDivide = address(oracle); // numerator oracle (1e6 precision)
        // oracle normalization 1^(36 - precision of numerator oracle + precision of denominator oracle - precision of collateral token)
        uint256 _oracleNormalization = 1e20; // 1^(36 + 8 - 6 - 18)
        address _rateContract = address(rateCalculator);

        bytes memory _configData = abi.encode(_collateral, _oracleMultiply, _oracleDivide, _oracleNormalization, _rateContract, "");

        address _owner = address(owner);
        uint256 _maxLTV = 80000; // 80%
        uint256 _liquidationFee = 10000; // 10%

        bytes memory _concentratorConfig = abi.encode(fc2Pool, multiClaimer, false);
        
        lendingPair = new ConcentratorLendingPair(_asset, _name, _symbol, _configData, _concentratorConfig, _owner, address(fortressSwap), _maxLTV, _liquidationFee);

        // --------------------------------- init pair ---------------------------------

        _testInitialize(address(lendingPair));

        // --------------------------------- deposit funds into TriCryptoTo2Pool ---------------------------------

        _dealERC20(WETH, owner, 100 ether);
        vm.startPrank(owner);
        IERC20(WETH).approve(address(fctrTriCrypto), type(uint256).max);
        fctrTriCrypto.depositUnderlying(WETH, owner, 50 ether, 0);
        vm.stopPrank();

        // --------------------------------- deposit funds into fc2Pool ---------------------------------

        // _dealERC20(USDC, owner, 100 ether);
        // vm.startPrank(owner);
        // IERC20(USDC).approve(fc2Pool, type(uint256).max);
        // ICompounder(fc2Pool).depositUnderlying(USDC, owner, 50 ether, 0);
        // vm.stopPrank();
    }

    // --------------------------------- tests ---------------------------------

    function testSanity() public {
        assertTrue(true);
        _dealERC20(USDC, owner, 2 ether);
        vm.startPrank(owner);
        IERC20(USDC).approve(fc2Pool, type(uint256).max);
        uint256 _balance = IERC20(USDC).balanceOf(owner);
        ICompounder(fc2Pool).depositUnderlying(USDC, owner, _balance, 0);

        skip(216000);
        skip(216000);
        skip(216000);

        ICompounder(fc2Pool).harvest(owner, 0);

        vm.stopPrank();
    }
    
    function testCorrectFlowWeth(uint256 _amount) public {
        vm.assume(_amount > 0.1 ether && _amount < 10 ether);

        (uint256 _totalAssetsAfter, uint256 _totalSupplyAfter) = _testDepositLiquidity(address(lendingPair), _amount);

        uint256 _totalCollateral = _testLeveragePosition(address(lendingPair), WETH);

        _testClaim();

        _testClosePosition(address(lendingPair), WETH, _totalAssetsAfter, _totalSupplyAfter, _totalCollateral);

        _testRemoveLiquidity(address(lendingPair));

        _testPlatformFee(address(lendingPair));

        _testUpdateSwap(address(lendingPair));

        _testUpdatePauseSettings(address(lendingPair));

        _testUpdateFee(address(lendingPair));

        _testUpdateOwner(address(lendingPair));
    }

    // --------------------------------- internal functions ---------------------------------

    function _testClaim() internal {
        assertTrue(lendingPair.userCollateralBalance(address(alice)) > 0, "_testClaim: E0");
        assertTrue(lendingPair.userCollateralBalance(address(bob)) > 0, "_testClaim: E1");
        assertTrue(lendingPair.userBorrowShares(address(alice)) > 0, "_testClaim: E2");
        assertTrue(lendingPair.userBorrowShares(address(bob)) > 0, "_testClaim: E3");

        assertEq(lendingPair.pendingReward(address(lendingPair)), 0, "_testClaim: E4");

        skip(216000);
        skip(216000);
        skip(216000);
        skip(216000);

        assertEq(lendingPair.pendingReward(address(lendingPair)), 0, "_testClaim: E5");

        vm.startPrank(owner);
        lendingPair.harvest(owner, 0);
        vm.stopPrank();

        assertTrue(lendingPair.pendingReward(address(lendingPair)) > 0, "_testClaim: E6");
    }

    function _addFraxWethRouteToSwap() internal {
        vm.startPrank(owner);

        if (!(fortressSwap.routeExists(FRAX, WETH))) {
            // uint256[] memory _poolType = new uint256[](1);
            // address[] memory _poolAddress = new address[](1);
            // address[] memory _fromList = new address[](1);
            // address[] memory _toList = new address[](1);

            // _poolType[0] = 14;
            
            // _poolAddress[0] = address(0);
            
            // _fromList[0] = FRAX;
            
            // _toList[0] = WETH;
            
            // fortressSwap.updateRoute(FRAX, WETH, _poolType, _poolAddress, _fromList, _toList);

            uint256[] memory _poolType = new uint256[](3);
            address[] memory _poolAddress = new address[](3);
            address[] memory _fromList = new address[](3);
            address[] memory _toList = new address[](3);

            _poolType[0] = 2;
            _poolType[1] = 2;
            _poolType[2] = 4;

            _poolAddress[0] = CURVE_FRAXBP;
            _poolAddress[1] = CURVE_BP;
            _poolAddress[2] = CURVE_TRICRYPTO;

            _fromList[0] = FRAX;
            _fromList[1] = USDC;
            _fromList[2] = USDT;

            _toList[0] = USDC;
            _toList[1] = USDT;
            _toList[2] = WETH;

            fortressSwap.updateRoute(FRAX, WETH, _poolType, _poolAddress, _fromList, _toList);
        }

        
        if (!(fortressSwap.routeExists(WETH, FRAX))) {
            uint256[] memory _poolType = new uint256[](1);
            address[] memory _poolAddress = new address[](1);
            address[] memory _fromList = new address[](1);
            address[] memory _toList = new address[](1);

            _poolType[0] = 14;
            
            _poolAddress[0] = address(0);
            
            _fromList[0] = WETH;
            
            _toList[0] = FRAX;
            
            fortressSwap.updateRoute(WETH, FRAX, _poolType, _poolAddress, _fromList, _toList);
        }
        
        vm.stopPrank();
    }
}