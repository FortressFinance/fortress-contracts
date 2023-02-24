// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "test/mainnet/compounder/balancer/BalancerCompounderBaseTest.sol";
contract test3ETH {}
// contract test3ETH is Test, AddRoutes, BalancerCompounderBaseTest {

//     // sfrxETH-stETH-rETH StablePool

//     using SafeERC20 for IERC20;
 
//     function setUp() public {
        
//         _setUp();

//         uint256 _convexPid = 13;
//         address _asset = BALANCER_3ETH;
//         string memory _symbol = "fortress-b3ETH";
//         string memory _name = "Fortress Balancer sfrxETH-stETH-rETH";

//         address[] memory _rewardAssets = new address[](2);
//         _rewardAssets[0] = BAL;
//         _rewardAssets[1] = AURA;

//         address[] memory _underlyingAssets = new address[](3);
//         _underlyingAssets[0] = sfrxETH;
//         _underlyingAssets[1] = rETH;
//         _underlyingAssets[2] = wstETH;

//         vm.startPrank(owner);
//         balancerCompounder = new BalancerCompounder(ERC20(_asset), _name, _symbol, owner, platform, address(fortressSwap), _convexPid, _rewardAssets, _underlyingAssets);
//         fortressRegistry.registerBalancerCompounder(address(balancerCompounder), _asset, _symbol, _name, _underlyingAssets);
//         vm.stopPrank();
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- test correct flow --------------------------------------
//     // ------------------------------------------------------------------------------------------
    
//     // TODO - check why fails with BAL#100 error on exit pool
//     // function testSingleUnwrappedrETH(uint256 _amount) public {
//     //     vm.assume(_amount > 0.01 ether && _amount < 1 ether);

//     //     _testSingleUnwrapped(rETH, _amount);
//     // }

//     function testSingleUnwrappedwstETH(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 2 ether);

//         _testSingleUnwrapped(wstETH, _amount);
//     }

//     function testSingleUnwrappedsfrxETH(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 2 ether);

//         _testSingleUnwrapped(sfrxETH, _amount);
//     }

//     function testDeposit(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 1 ether);

//         _testDeposit(_amount);
//     }

//     function testRedeem(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 1.5 ether);

//         _testRedeem(sfrxETH, _amount);
//     }

//     function testWithdraw(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         _testWithdraw(sfrxETH, _amount);
//     }

//     function testMint(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);
 
//         _testMint(sfrxETH, _amount);
//     }

//     function testDepositCap(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 1 ether);

//         _testDepositCap(sfrxETH, _amount);
//     }
    
//     function testFortressRegistry() public {
//         _testFortressRegistry();
//     }

//     // ------------------------------------------------------------------------------------------
//     // --------------------------------- test wrong flows ---------------------------------------
//     // ------------------------------------------------------------------------------------------

//     function testNoAssetsDeposit(uint256 _amount) public {
//         _testNoAssetsDeposit(_amount);
//     }

//     function testNoAssetsMint(uint256 _amount) public {
//         _testNoAssetsMint(_amount);
//     }

//     function testNoSharesWithdraw(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         _testNoSharesWithdraw(_amount, sfrxETH);
//     }

//     function testNoSharesRedeem(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 5 ether);

//         _testNoSharesRedeem(_amount, sfrxETH);
//     }

//     function testSingleUnwrappedDepositWrongAsset(uint256 _amount) public {
//         vm.assume(_amount > 0.01 ether && _amount < 99 ether);
//         _testSingleUnwrappedDepositWrongAsset(BAL, _amount);
//     }

//     function testHarvestNoBounty() public {
//         _testHarvestNoBounty(sfrxETH);
//     }
// }