// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FortressTriCryptoOracle} from "src/shared/lending/oracles/FortressTriCryptoOracle.sol";

import {AMMConcentratorBase, IConvexBasicRewards} from "src/shared/concentrators/AMMConcentratorBase.sol";

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
    }

    // --------------------------------- tests ---------------------------------
    
    function testCorrectFlowWeth(uint256 _amount) public {
        vm.assume(_amount > 0.1 ether && _amount < 10 ether);

        (uint256 _totalAssetsAfter, uint256 _totalSupplyAfter) = _testDepositLiquidity(address(lendingPair), _amount);

        uint256 _totalCollateral = _testLeveragePosition(address(lendingPair), WETH);

        _testClaimAliceAndBob();

        _testClosePosition(address(lendingPair), WETH, _totalAssetsAfter, _totalSupplyAfter, _totalCollateral);

        _testRemoveLiquidity(address(lendingPair));

        _testPlatformFee(address(lendingPair));

        _testUpdateSwap(address(lendingPair));

        _testUpdatePauseSettings(address(lendingPair));

        _testUpdateFee(address(lendingPair));

        _testUpdateOwner(address(lendingPair));

        _testClaimCharlie();
    }

    // --------------------------------- internal functions ---------------------------------

    function _testClaimAliceAndBob() internal {
        assertTrue(lendingPair.userCollateralBalance(address(alice)) > 0, "_testClaim: E0");
        assertTrue(lendingPair.userCollateralBalance(address(bob)) > 0, "_testClaim: E1");
        assertTrue(lendingPair.userBorrowShares(address(alice)) > 0, "_testClaim: E2");
        assertTrue(lendingPair.userBorrowShares(address(bob)) > 0, "_testClaim: E3");
        assertEq(fctrTriCrypto.pendingReward(address(lendingPair)), 0, "_testClaim: E4");

        skip(216000);

        vm.startPrank(owner);
        fctrTriCrypto.harvest(owner, 0);

        assertTrue(fctrTriCrypto.pendingReward(address(lendingPair)) > 0, "_testClaim: E5");

        lendingPair.harvest(owner, 0);
        vm.stopPrank();

        uint256 _aliceReward = lendingPair.pendingReward(alice);
        uint256 _bobReward = lendingPair.pendingReward(bob);
        uint256 _charlieReward = lendingPair.pendingReward(charlie);

        assertEq(fctrTriCrypto.pendingReward(address(lendingPair)), 0, "_testClaim: E6");
        assertApproxEqAbs(_aliceReward, _bobReward, 1e10, "_testClaim: E7");
        assertApproxEqAbs(_bobReward, _charlieReward, 1e10, "_testClaim: E8");
        assertTrue(_aliceReward > 0, "_testClaim: E9");

        vm.startPrank(alice);
        uint256 _rewardsBalanceBefore = IERC20(lendingPair.rewardAsset()).balanceOf(address(alice));
        lendingPair.claim(alice, alice);
        uint256 _rewardsPaid = IERC20(lendingPair.rewardAsset()).balanceOf(address(alice)) - _rewardsBalanceBefore;
        assertEq(_rewardsPaid, _aliceReward, "_testClaim: E10");
        assertEq(lendingPair.pendingReward(alice), 0, "_testClaim: E11");
        vm.stopPrank();

        vm.startPrank(bob);
        _rewardsBalanceBefore = IERC20(lendingPair.rewardAsset()).balanceOf(address(bob));
        lendingPair.claim(bob, bob);
        _rewardsPaid = IERC20(lendingPair.rewardAsset()).balanceOf(address(bob)) - _rewardsBalanceBefore;
        assertEq(_rewardsPaid, _bobReward, "_testClaim: E12");
        assertEq(lendingPair.pendingReward(bob), 0, "_testClaim: E13");
        vm.stopPrank();

        assertApproxEqAbs(IERC20(lendingPair.rewardAsset()).balanceOf(address(lendingPair)), _charlieReward, 1e2, "_testClaim: E16");
    }

    function _testClaimCharlie() internal {
        assertEq(lendingPair.userCollateralBalance(address(charlie)), 0, "_testClaimCharlie: E1");
        assertEq(lendingPair.userBorrowShares(address(charlie)), 0, "_testClaimCharlie: E2");

        uint256 _charlieReward = lendingPair.pendingReward(charlie);

        vm.startPrank(charlie);
        uint256 _rewardsBalanceBefore = IERC20(lendingPair.rewardAsset()).balanceOf(address(charlie));
        lendingPair.claim(charlie, charlie);
        uint256 _rewardsPaid = IERC20(lendingPair.rewardAsset()).balanceOf(address(charlie)) - _rewardsBalanceBefore;
        assertEq(_rewardsPaid, _charlieReward, "_testClaimCharlie: E14");
        assertEq(lendingPair.pendingReward(charlie), 0, "_testClaimCharlie: E15");
        vm.stopPrank();

        assertApproxEqAbs(IERC20(lendingPair.rewardAsset()).balanceOf(address(lendingPair)), 0, 1e2, "_testClaimCharlie: E16");
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