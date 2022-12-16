// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "script/mainnet/utils/AddRoutes.sol";

import "src/shared/interfaces/IWETH.sol";

// TODO - add tests for 12: BalancerSingleSwap
contract testFortressSwap is Test, AddRoutes {
    
    address owner;
    address alice;
    address bob;

    uint256 mainnetFork;
    uint256 arbitrumFork;

    FortressSwap fortressSwap;

    function setUp() public {
        
        // --------------------------------- set env ---------------------------------
        
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        // string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        // arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        
        vm.selectFork(mainnetFork);
        
        // --------------------------------- set accounts ---------------------------------
        owner = address(0x16cAD91E1928F994816EbC5e759d8562aAc65ab2);
        alice = address(0xFa0C696bC56AE0d256D34a307c447E80bf92Dd41);
        bob = address(0x864e4b0c28dF7E2f317FF339CebDB5224F47220e);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);

        // --------------------------------- deploy contracts ---------------------------------

        fortressSwap = new FortressSwap(address(owner));

        // --------------------------------- add routes ---------------------------------

        vm.startPrank(owner);
        addRoutes(address(fortressSwap));
        vm.stopPrank();
    }

    function testCantSwapNoRoute() public {
        vm.startPrank(alice);

        vm.expectRevert();
        fortressSwap.swap{ value: 1 ether }(ETH, JPEG, 1 ether);
        
        vm.stopPrank();
    }

    // --------------------------------- swap from CRV ---------------------------------

    // CRV --> ETH
    function testSwapCRVToETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> ETH:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        uint256 _before = address(alice).balance;
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, ETH, _tokenAmount);
        _ethAmount = address(alice).balance - _before;
        console.log("Swap %s CRV for %s ETH", _tokenAmount, _ethAmount);
        console.log("ETH from swap = %s", _amountOut);
        assertApproxEqAbs(_ethAmount, _amountOut, 10);
    }

    // CRV --> CVX
    function testSwapCRVToCVX(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> CVX:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, CVX, _tokenAmount);
        console.log("Swap %s CRV for %s CVX", _tokenAmount, _amountOut);
        console.log("CVX from swap = %s", IERC20(CVX).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(CVX).balanceOf(alice), 10);
    }

    // CRV --> stETH
    function testSwapCRVToStETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> stETH:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, stETH, _tokenAmount);
        console.log("Swap %s CRV for %s stETH", _tokenAmount, _amountOut);
        console.log("stETH from swap = %s", IERC20(stETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(stETH).balanceOf(alice), 10);
    }

    // CRV --> USDC
    function testSwapCRVToUSDC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> USDC:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, USDC, _tokenAmount);
        console.log("Swap %s CRV for %s USDC", _tokenAmount, _amountOut);
        console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
    }


    // CRV --> USDT
    function testSwapCRVToUSDT(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> USDT:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, USDT, _tokenAmount);
        console.log("Swap %s CRV for %s USDT", _tokenAmount, _amountOut);
        console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
    }

    // CRV --> DAI
    function testSwapCRVToDAI(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> DAI:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, DAI, _tokenAmount);
        console.log("Swap %s CRV for %s DAI", _tokenAmount, _amountOut);
        console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
    }

    // CRV --> FRAX
    function testSwapCRVToFRAX(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> FRAX:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, FRAX, _tokenAmount);
        console.log("Swap %s CRV for %s FRAX", _tokenAmount, _amountOut);
        console.log("FRAX from swap = %s", IERC20(FRAX).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(FRAX).balanceOf(alice), 10);
    }

    // CRV --> MIM
    function testSwapCRVToMIM(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> MIM:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, MIM, _tokenAmount);
        console.log("Swap %s CRV for %s MIM", _tokenAmount, _amountOut);
        console.log("MIM from swap = %s", IERC20(MIM).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(MIM).balanceOf(alice), 10);
    }

    // CRV --> alUSD
    function testSwapCRVToalUSD(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> alUSD:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, alUSD, _tokenAmount);
        console.log("Swap %s CRV for %s alUSD", _tokenAmount, _amountOut);
        console.log("alUSD from swap = %s", IERC20(alUSD).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(alUSD).balanceOf(alice), 10);
    }

    // CRV --> pUSD
    function testSwapCRVTopUSD(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> pUSD:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, pUSD, _tokenAmount);
        console.log("Swap %s CRV for %s pUSD", _tokenAmount, _amountOut);
        console.log("pUSD from swap = %s", IERC20(pUSD).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(pUSD).balanceOf(alice), 10);
    }

    // CRV --> BUSD
    function testSwapCRVToBUSD(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> bUSD:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, BUSD, _tokenAmount);
        console.log("Swap %s CRV for %s BUSD", _tokenAmount, _amountOut);
        console.log("BUSD from swap = %s", IERC20(BUSD).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(BUSD).balanceOf(alice), 10);
    }

    // CRV --> FXS
    function testSwapCRVToFXS(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> FXS:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, FXS, _tokenAmount);
        console.log("Swap %s CRV for %s FXS", _tokenAmount, _amountOut);
        console.log("FXS from swap = %s", IERC20(FXS).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(FXS).balanceOf(alice), 10);
    }

    // CRV --> wBTC
    function testSwapCRVToWBTC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> wBTC:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, wBTC, _tokenAmount);
        console.log("Swap %s CRV for %s wBTC", _tokenAmount, _amountOut);
        console.log("wBTC from swap = %s", IERC20(wBTC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(wBTC).balanceOf(alice), 10);
    }

    // CRV --> sBTC
    function testSwapCRVToSBTC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> sBTC:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, sBTC, _tokenAmount);
        console.log("Swap %s CRV for %s sBTC", _tokenAmount, _amountOut);
        console.log("sBTC from swap = %s", IERC20(sBTC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(sBTC).balanceOf(alice), 10);
    }

    // CRV --> sETH
    function testSwapCRVToSETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> sETH:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, sETH, _tokenAmount);
        console.log("Swap %s CRV for %s sETH", _tokenAmount, _amountOut);
        console.log("sETH from swap = %s", IERC20(sETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(sETH).balanceOf(alice), 10);
    }

    // CRV --> FPI
    function testSwapCRVToFPI(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> FPI:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, FPI, _tokenAmount);
        console.log("Swap %s CRV for %s FPI", _tokenAmount, _amountOut);
        console.log("FPI from swap = %s", IERC20(FPI).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(FPI).balanceOf(alice), 10);
    }

    // CRV --> OHM
    function testSwapCRVToOHM(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> OHM:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, OHM, _tokenAmount);
        console.log("Swap %s CRV for %s OHM", _tokenAmount, _amountOut);
        console.log("OHM from swap = %s", IERC20(OHM).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(OHM).balanceOf(alice), 10);
    }

    // CRV --> JPEG
    function testSwapCRVToJPEG(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> JPEG:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, JPEG, _tokenAmount);
        console.log("Swap %s CRV for %s JPEG", _tokenAmount, _amountOut);
        console.log("JPEG from swap = %s", IERC20(JPEG).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(JPEG).balanceOf(alice), 10);
    }

    // CRV --> cvxFXS
    function testSwapCRVToCvxFXS(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> cvxFXS:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, cvxFXS, _tokenAmount);
        console.log("Swap %s CRV for %s cvxFXS", _tokenAmount, _amountOut);
        console.log("cvxFXS from swap = %s", IERC20(cvxFXS).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(cvxFXS).balanceOf(alice), 10);
    }
    
    // CRV --> LINK
    function testSwapCRVToLINK(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> LINK:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, LINK, _tokenAmount);
        console.log("Swap %s CRV for %s LINK", _tokenAmount, _amountOut);
        console.log("LINK from swap = %s", IERC20(LINK).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(LINK).balanceOf(alice), 10);
    }

    // CRV --> sLINK
    function testSwapCRVToSLINK(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> sLINK:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, sLINK, _tokenAmount);
        console.log("Swap %s CRV for %s sLINK", _tokenAmount, _amountOut);
        console.log("sLINK from swap = %s", IERC20(sLINK).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(sLINK).balanceOf(alice), 10);
    }

    // CRV --> alETH
    function testSwapCRVToAlETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CRV --> alETH:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CRV, _ethAmount);
        console.log("Swap %s ETH for %s CRV", _ethAmount, IERC20(CRV).balanceOf(alice));
        console.log("CRV from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CRV).balanceOf(alice), 10);
        
        IERC20(CRV).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CRV, alETH, _tokenAmount);
        console.log("Swap %s CRV for %s alETH", _tokenAmount, _amountOut);
        console.log("alETH from swap = %s", IERC20(alETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(alETH).balanceOf(alice), 10);
    }
    

    // --------------------------------- swap from CVX ---------------------------------

    // CVX --> ETH
    function testSwapCVXToETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> ETH:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        uint256 _before = address(alice).balance;
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, ETH, _tokenAmount);
        _ethAmount = address(alice).balance - _before;
        console.log("Swap %s CVX for %s ETH", _tokenAmount, _ethAmount);
        console.log("ETH from swap = %s", _amountOut);
        assertApproxEqAbs(_ethAmount, _amountOut, 10);
    }

    // CVX --> CRV
    function testSwapCVXToCRV(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> CRV:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, CRV, _tokenAmount);
        console.log("Swap %s CVX for %s CRV", _tokenAmount, _amountOut);
        console.log("CRV from swap = %s", IERC20(CRV).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(CRV).balanceOf(alice), 10);
    }

    // CVX --> stETH
    function testSwapCVXToStETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> stETH:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, stETH, _tokenAmount);
        console.log("Swap %s CVX for %s stETH", _tokenAmount, _amountOut);
        console.log("stETH from swap = %s", IERC20(stETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(stETH).balanceOf(alice), 10);
    }

    // CVX --> USDC
    function testSwapCVXToUSDC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> USDC:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, USDC, _tokenAmount);
        console.log("Swap %s CVX for %s USDC", _tokenAmount, _amountOut);
        console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
    }

    // CVX --> USDT
    function testSwapCVXToUSDT(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> USDT:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, USDT, _tokenAmount);
        console.log("Swap %s CVX for %s USDT", _tokenAmount, _amountOut);
        console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
    }

    // CVX --> DAI
    function testSwapCVXToDAI(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> DAI:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, DAI, _tokenAmount);
        console.log("Swap %s CVX for %s DAI", _tokenAmount, _amountOut);
        console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
    }

    // CVX --> FRAX
    function testSwapCVXToFRAX(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> FRAX:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, FRAX, _tokenAmount);
        console.log("Swap %s CVX for %s FRAX", _tokenAmount, _amountOut);
        console.log("FRAX from swap = %s", IERC20(FRAX).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(FRAX).balanceOf(alice), 10);
    }

    // CVX --> MIM
    function testSwapCVXToMIM(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> MIM:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, MIM, _tokenAmount);
        console.log("Swap %s CVX for %s MIM", _tokenAmount, _amountOut);
        console.log("MIM from swap = %s", IERC20(MIM).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(MIM).balanceOf(alice), 10);
    }

    // CVX --> alUSD
    function testSwapCVXToalUSD(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> alUSD:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, alUSD, _tokenAmount);
        console.log("Swap %s CVX for %s alUSD", _tokenAmount, _amountOut);
        console.log("alUSD from swap = %s", IERC20(alUSD).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(alUSD).balanceOf(alice), 10);
    }

    // CVX --> pUSD
    function testSwapCVXTopUSD(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> pUSD:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, pUSD, _tokenAmount);
        console.log("Swap %s CVX for %s pUSD", _tokenAmount, _amountOut);
        console.log("pUSD from swap = %s", IERC20(pUSD).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(pUSD).balanceOf(alice), 10);
    }

    // CVX --> BUSD
    function testSwapCVXToBUSD(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> BUSD:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, BUSD, _tokenAmount);
        console.log("Swap %s CVX for %s BUSD", _tokenAmount, _amountOut);
        console.log("BUSD from swap = %s", IERC20(BUSD).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(BUSD).balanceOf(alice), 10);
    }

    // CVX --> wBTC
    function testSwapCVXToWBTC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> wBTC:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, wBTC, _tokenAmount);
        console.log("Swap %s CVX for %s wBTC", _tokenAmount, _amountOut);
        console.log("wBTC from swap = %s", IERC20(wBTC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(wBTC).balanceOf(alice), 10);
    }

    // CVX --> sBTC
    function testSwapCVXToSBTC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> sBTC:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, sBTC, _tokenAmount);
        console.log("Swap %s CVX for %s sBTC", _tokenAmount, _amountOut);
        console.log("sBTC from swap = %s", IERC20(sBTC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(sBTC).balanceOf(alice), 10);
    }

    // CVX --> sETH
    function testSwapCVXToSETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> sETH:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, sETH, _tokenAmount);
        console.log("Swap %s CVX for %s sETH", _tokenAmount, _amountOut);
        console.log("sETH from swap = %s", IERC20(sETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(sETH).balanceOf(alice), 10);
    }

    // CVX --> FPI
    function testSwapCVXToFPI(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> FPI:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, FPI, _tokenAmount);
        console.log("Swap %s CVX for %s FPI", _tokenAmount, _amountOut);
        console.log("FPI from swap = %s", IERC20(FPI).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(FPI).balanceOf(alice), 10);
    }

    // CVX --> OHM
    function testSwapCVXToOHM(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> OHM:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, OHM, _tokenAmount);
        console.log("Swap %s CVX for %s OHM", _tokenAmount, _amountOut);
        console.log("OHM from swap = %s", IERC20(OHM).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(OHM).balanceOf(alice), 10);
    }

    // CVX --> JPEG
    function testSwapCVXToJPEG(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> JPEG:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, JPEG, _tokenAmount);
        console.log("Swap %s CVX for %s JPEG", _tokenAmount, _amountOut);
        console.log("JPEG from swap = %s", IERC20(JPEG).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(JPEG).balanceOf(alice), 10);
    }

    // CVX --> cvxFXS
    function testSwapCVXToCvxFXS(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> cvxFXS:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, cvxFXS, _tokenAmount);
        console.log("Swap %s CVX for %s cvxFXS", _tokenAmount, _amountOut);
        console.log("cvxFXS from swap = %s", IERC20(cvxFXS).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(cvxFXS).balanceOf(alice), 10);
    }

    // CVX --> LINK
    function testSwapCVXToLINK(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> LINK:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, LINK, _tokenAmount);
        console.log("Swap %s CVX for %s LINK", _tokenAmount, _amountOut);
        console.log("LINK from swap = %s", IERC20(LINK).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(LINK).balanceOf(alice), 10);
    }

    // CVX --> alETH
    function testSwapCVXToAlETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("CVX --> alETH:\n");
        
        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, CVX, _ethAmount);
        console.log("Swap %s ETH for %s CVX", _ethAmount, IERC20(CVX).balanceOf(alice));
        console.log("CVX from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(CVX).balanceOf(alice), 10);
        
        IERC20(CVX).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(CVX, alETH, _tokenAmount);
        console.log("Swap %s CVX for %s alETH", _tokenAmount, _amountOut);
        console.log("alETH from swap = %s", IERC20(alETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(alETH).balanceOf(alice), 10);
    }

    // --------------------------------- from FXS ---------------------------------

    // FXS --> ETH
    function testSwapFXSToETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("FXS --> ETH:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, FXS, _ethAmount);
        console.log("Swap %s ETH for %s FXS", _ethAmount, IERC20(FXS).balanceOf(alice));
        console.log("FXS from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(FXS).balanceOf(alice), 10);
        
        uint256 _before = address(alice).balance;
        IERC20(FXS).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(FXS, ETH, _tokenAmount);
        _ethAmount = address(alice).balance - _before;
        console.log("Swap %s FXS for %s ETH", _tokenAmount, _ethAmount);
        console.log("ETH from swap = %s", _amountOut);
        assertApproxEqAbs(_ethAmount, _amountOut, 10);
    }

    // FXS --> USDC
    function testSwapFXSToUSDC(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("FXS --> USDC:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, FXS, _ethAmount);
        console.log("Swap %s ETH for %s FXS", _ethAmount, IERC20(FXS).balanceOf(alice));
        console.log("FXS from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(FXS).balanceOf(alice), 10);
        
        IERC20(FXS).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(FXS, USDC, _tokenAmount);
        console.log("Swap %s FXS for %s USDC", _tokenAmount, _amountOut);
        console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
    }

    // FXS --> USDT
    function testSwapFXSToUSDT(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("FXS --> USDT:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, FXS, _ethAmount);
        console.log("Swap %s ETH for %s FXS", _ethAmount, IERC20(FXS).balanceOf(alice));
        console.log("FXS from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(FXS).balanceOf(alice), 10);
        
        IERC20(FXS).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(FXS, USDT, _tokenAmount);
        console.log("Swap %s FXS for %s USDT", _tokenAmount, _amountOut);
        console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
    }
    
    // FXS --> DAI
    function testSwapFXSToDAI(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("FXS --> DAI:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, FXS, _ethAmount);
        console.log("Swap %s ETH for %s FXS", _ethAmount, IERC20(FXS).balanceOf(alice));
        console.log("FXS from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(FXS).balanceOf(alice), 10);
        
        IERC20(FXS).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(FXS, DAI, _tokenAmount);
        console.log("Swap %s FXS for %s DAI", _tokenAmount, _amountOut);
        console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
    }

    // FXS --> FRAX
    function testSwapFXSToFRAX(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("FXS --> FRAX:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, FXS, _ethAmount);
        console.log("Swap %s ETH for %s FXS", _ethAmount, IERC20(FXS).balanceOf(alice));
        console.log("FXS from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(FXS).balanceOf(alice), 10);
        
        IERC20(FXS).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(FXS, FRAX, _tokenAmount);
        console.log("Swap %s FXS for %s FRAX", _tokenAmount, _amountOut);
        console.log("FRAX from swap = %s", IERC20(FRAX).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(FRAX).balanceOf(alice), 10);
    }

    // --------------------------------- swap from LDO ---------------------------------

    // LDO --> stETH
    function testSwapLDOTostETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("LDO --> stETH:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, LDO, _ethAmount);
        console.log("Swap %s ETH for %s LDO", _ethAmount, _tokenAmount);
        console.log("LDO from swap = %s", IERC20(LDO).balanceOf(alice));
        assertApproxEqAbs(_tokenAmount, IERC20(LDO).balanceOf(alice), 10);

        IERC20(LDO).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(LDO, stETH, _tokenAmount);
        console.log("Swap %s LDO for %s stETH", _tokenAmount, _amountOut);
        console.log("stETH from swap = %s", IERC20(stETH).balanceOf(alice));
        assertApproxEqAbs(_amountOut, IERC20(stETH).balanceOf(alice), 10);
    }

    // LDO --> ETH
    function testSwapLDOToETH(uint256 _ethAmount) public {
        vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
        vm.startPrank(alice);
        console.log("LDO --> ETH:\n");

        uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, LDO, _ethAmount);
        console.log("Swap %s ETH for %s LDO", _ethAmount, IERC20(LDO).balanceOf(alice));
        console.log("LDO from swap = %s", _tokenAmount);
        assertApproxEqAbs(_tokenAmount, IERC20(LDO).balanceOf(alice), 10);
        
        uint256 _before = address(alice).balance;
        IERC20(LDO).approve(address(fortressSwap), _tokenAmount);
        uint256 _amountOut = fortressSwap.swap(LDO, ETH, _tokenAmount);
        _ethAmount = address(alice).balance - _before;
        console.log("Swap %s LDO for %s ETH", _tokenAmount, _ethAmount);
        console.log("ETH from swap = %s", _amountOut);
        assertApproxEqAbs(_ethAmount, _amountOut, 10);
    }

    // --------------------------------- from SNX ---------------------------------

        // SNX --> DAI
        function testSwapSNXToDAI(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SNX --> DAI:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SNX, _ethAmount);
            console.log("Swap %s ETH for %s SNX", _ethAmount, IERC20(SNX).balanceOf(alice));
            console.log("SNX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SNX).balanceOf(alice), 10);
            
            IERC20(SNX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SNX, DAI, _tokenAmount);
            console.log("Swap %s SNX for %s DAI", _tokenAmount, _amountOut);
            console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
        }

        // SNX --> USDC
        function testSwapSNXToUSDC(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SNX --> USDC:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SNX, _ethAmount);
            console.log("Swap %s ETH for %s SNX", _ethAmount, IERC20(SNX).balanceOf(alice));
            console.log("SNX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SNX).balanceOf(alice), 10);
            
            IERC20(SNX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SNX, USDC, _tokenAmount);
            console.log("Swap %s SNX for %s USDC", _tokenAmount, _amountOut);
            console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
        }

        // SNX --> USDT
        function testSwapSNXToUSDT(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SNX --> USDT:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SNX, _ethAmount);
            console.log("Swap %s ETH for %s SNX", _ethAmount, IERC20(SNX).balanceOf(alice));
            console.log("SNX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SNX).balanceOf(alice), 10);
            
            IERC20(SNX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SNX, USDT, _tokenAmount);
            console.log("Swap %s SNX for %s USDT", _tokenAmount, _amountOut);
            console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
        }

        // SNX --> sUSD
        function testSwapSNXToSUSD(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SNX --> sUSD:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SNX, _ethAmount);
            console.log("Swap %s ETH for %s SNX", _ethAmount, IERC20(SNX).balanceOf(alice));
            console.log("SNX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SNX).balanceOf(alice), 10);
            
            IERC20(SNX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SNX, sUSD, _tokenAmount);
            console.log("Swap %s SNX for %s sUSD", _tokenAmount, _amountOut);
            console.log("sUSD from swap = %s", IERC20(sUSD).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(sUSD).balanceOf(alice), 10);
        }

        // --------------------------------- from USDD ---------------------------------

        // USDD --> DAI
        function testSwapUSDDToDAI(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("USDD --> DAI:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, USDD, _ethAmount);
            console.log("Swap %s ETH for %s USDD", _ethAmount, IERC20(USDD).balanceOf(alice));
            console.log("USDD from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(USDD).balanceOf(alice), 10);
            
            IERC20(USDD).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(USDD, DAI, _tokenAmount);
            console.log("Swap %s USDD for %s DAI", _tokenAmount, _amountOut);
            console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
        }

        // USDD --> USDC
        function testSwapUSDDToUSDC(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("USDD --> USDC:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, USDD, _ethAmount);
            console.log("Swap %s ETH for %s USDD", _ethAmount, IERC20(USDD).balanceOf(alice));
            console.log("USDD from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(USDD).balanceOf(alice), 10);
            
            IERC20(USDD).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(USDD, USDC, _tokenAmount);
            console.log("Swap %s USDD for %s USDC", _tokenAmount, _amountOut);
            console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
        }

        // USDD --> USDT
        function testSwapUSDDToUSDT(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("USDD --> USDT:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, USDD, _ethAmount);
            console.log("Swap %s ETH for %s USDD", _ethAmount, IERC20(USDD).balanceOf(alice));
            console.log("USDD from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(USDD).balanceOf(alice), 10);
            
            IERC20(USDD).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(USDD, USDT, _tokenAmount);
            console.log("Swap %s USDD for %s USDT", _tokenAmount, _amountOut);
            console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
        }

        // --------------------------------- from SPELL ---------------------------------

        // SPELL --> ETH
        function testSwapSPELLToETH(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SPELL --> ETH:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SPELL, _ethAmount);
            console.log("Swap %s ETH for %s SPELL", _ethAmount, IERC20(SPELL).balanceOf(alice));
            console.log("SPELL from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SPELL).balanceOf(alice), 10);
            
            uint256 _before = address(alice).balance;
            IERC20(SPELL).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SPELL, ETH, _tokenAmount);
            _ethAmount = address(alice).balance - _before;
            console.log("Swap %s SPELL for %s ETH", _tokenAmount, _ethAmount);
            console.log("ETH from swap = %s", _amountOut);
            assertApproxEqAbs(_ethAmount, _amountOut, 10);
        }

        // SPELL --> MIM
        function testSwapSPELLToMIM(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SPELL --> MIM:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SPELL, _ethAmount);
            console.log("Swap %s ETH for %s SPELL", _ethAmount, IERC20(SPELL).balanceOf(alice));
            console.log("SPELL from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SPELL).balanceOf(alice), 10);
            
            IERC20(SPELL).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SPELL, MIM, _tokenAmount);
            console.log("Swap %s SPELL for %s MIM", _tokenAmount, _amountOut);
            console.log("MIM from swap = %s", IERC20(MIM).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(MIM).balanceOf(alice), 10);
        }

        // SPELL --> DAI
        function testSwapSPELLToDAI(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SPELL --> DAI:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SPELL, _ethAmount);
            console.log("Swap %s ETH for %s SPELL", _ethAmount, IERC20(SPELL).balanceOf(alice));
            console.log("SPELL from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SPELL).balanceOf(alice), 10);
            
            IERC20(SPELL).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SPELL, DAI, _tokenAmount);
            console.log("Swap %s SPELL for %s DAI", _tokenAmount, _amountOut);
            console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
        }

        // SPELL --> USDC
        function testSwapSPELLToUSDC(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SPELL --> USDC:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SPELL, _ethAmount);
            console.log("Swap %s ETH for %s SPELL", _ethAmount, IERC20(SPELL).balanceOf(alice));
            console.log("SPELL from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SPELL).balanceOf(alice), 10);
            
            IERC20(SPELL).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SPELL, USDC, _tokenAmount);
            console.log("Swap %s SPELL for %s USDC", _tokenAmount, _amountOut);
            console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
        }

        // SPELL --> USDT
        function testSwapSPELLToUSDT(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("SPELL --> USDT:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, SPELL, _ethAmount);
            console.log("Swap %s ETH for %s SPELL", _ethAmount, IERC20(SPELL).balanceOf(alice));
            console.log("SPELL from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(SPELL).balanceOf(alice), 10);
            
            IERC20(SPELL).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(SPELL, USDT, _tokenAmount);
            console.log("Swap %s SPELL for %s USDT", _tokenAmount, _amountOut);
            console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
        }

        // --------------------------------- from ALCX ---------------------------------

        // ALCX --> ETH
        function testSwapALCXToETH(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("ALCX --> ETH:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, ALCX, _ethAmount);
            console.log("Swap %s ETH for %s ALCX", _ethAmount, IERC20(ALCX).balanceOf(alice));
            console.log("ALCX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(ALCX).balanceOf(alice), 10);
            
            uint256 _before = address(alice).balance;
            IERC20(ALCX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(ALCX, ETH, _tokenAmount);
            _ethAmount = address(alice).balance - _before;
            console.log("Swap %s ALCX for %s ETH", _tokenAmount, _ethAmount);
            console.log("ETH from swap = %s", _amountOut);
            assertApproxEqAbs(_ethAmount, _amountOut, 10);
        }

        // ALCX --> alUSD
        function testSwapALCXToalUSD(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("ALCX --> alUSD:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, ALCX, _ethAmount);
            console.log("Swap %s ETH for %s ALCX", _ethAmount, IERC20(ALCX).balanceOf(alice));
            console.log("ALCX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(ALCX).balanceOf(alice), 10);
            
            IERC20(ALCX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(ALCX, alUSD, _tokenAmount);
            console.log("Swap %s ALCX for %s alUSD", _tokenAmount, _amountOut);
            console.log("alUSD from swap = %s", IERC20(alUSD).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(alUSD).balanceOf(alice), 10);
        }

        // ALCX --> DAI
        function testSwapALCXToDAI(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("ALCX --> DAI:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, ALCX, _ethAmount);
            console.log("Swap %s ETH for %s ALCX", _ethAmount, IERC20(ALCX).balanceOf(alice));
            console.log("ALCX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(ALCX).balanceOf(alice), 10);
            
            IERC20(ALCX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(ALCX, DAI, _tokenAmount);
            console.log("Swap %s ALCX for %s DAI", _tokenAmount, _amountOut);
            console.log("DAI from swap = %s", IERC20(DAI).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(DAI).balanceOf(alice), 10);
        }

        // ALCX --> USDC
        function testSwapALCXToUSDC(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("ALCX --> USDC:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, ALCX, _ethAmount);
            console.log("Swap %s ETH for %s ALCX", _ethAmount, IERC20(ALCX).balanceOf(alice));
            console.log("ALCX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(ALCX).balanceOf(alice), 10);
            
            IERC20(ALCX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(ALCX, USDC, _tokenAmount);
            console.log("Swap %s ALCX for %s USDC", _tokenAmount, _amountOut);
            console.log("USDC from swap = %s", IERC20(USDC).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDC).balanceOf(alice), 10);
        }

        // ALCX --> USDT
        function testSwapALCXToUSDT(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("ALCX --> USDT:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, ALCX, _ethAmount);
            console.log("Swap %s ETH for %s ALCX", _ethAmount, IERC20(ALCX).balanceOf(alice));
            console.log("ALCX from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(ALCX).balanceOf(alice), 10);
            
            IERC20(ALCX).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(ALCX, USDT, _tokenAmount);
            console.log("Swap %s ALCX for %s USDT", _tokenAmount, _amountOut);
            console.log("USDT from swap = %s", IERC20(USDT).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(USDT).balanceOf(alice), 10);
        }

        // USDC --> ALCX
        function testSwapUSDCtoALCX(uint256 _ethAmount) public {
            vm.assume(_ethAmount < 100 ether && _ethAmount > 0.0001 ether);
            vm.startPrank(alice);
            console.log("USDC --> ALCX:\n");
            
            uint256 _tokenAmount = fortressSwap.swap{ value: _ethAmount }(ETH, USDC, _ethAmount);
            console.log("Swap %s ETH for %s USDC", _ethAmount, IERC20(USDC).balanceOf(alice));
            console.log("USDC from swap = %s", _tokenAmount);
            assertApproxEqAbs(_tokenAmount, IERC20(USDC).balanceOf(alice), 10);
            
            IERC20(USDC).approve(address(fortressSwap), _tokenAmount);
            uint256 _amountOut = fortressSwap.swap(USDC, ALCX, _tokenAmount);
            console.log("Swap %s USDC for %s ALCX", _tokenAmount, _amountOut);
            console.log("ALCX from swap = %s", IERC20(ALCX).balanceOf(alice));
            assertApproxEqAbs(_amountOut, IERC20(ALCX).balanceOf(alice), 10);
        }
}
