// // SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝

// 
// 
// 
// 

// Github - https://github.com/FortressFinance

import {IBalancerV2StablePool} from "../interfaces/IBalancerV2StablePool.sol";
import {IBalancerVault} from "../interfaces/IBalancerVault.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import "./BaseOracle.sol";

contract FortressWstETHwETHOracle is BaseOracle {

    using FixedPointMathLib for uint256;

    uint256 public wethOracle_decimals = 1e8;
    uint256 public wstethOracle_decimals = 1e18;

    IChainlinkAggregator public wEthOracle = IChainlinkAggregator(address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612));
    IChainlinkAggregator public wstEthOracle = IChainlinkAggregator(address(0xb523AE262D20A936BC152e6023996e46FDC2A95D));
    IBalancerV2StablePool public BPT = IBalancerV2StablePool(address(0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f));

    /********************************** Constructor **********************************/

    constructor(address _owner, address _vault) BaseOracle(_owner, _vault) {}

    /********************************** Modifiers **********************************/

    modifier reentrancyCheck() {
        IBalancerVault(BPT.getVault()).manageUserBalance(new IBalancerVault.UserBalanceOp[](0));
        _;
    }

    /********************************** External Functions **********************************/

    function description() external pure override returns (string memory) {
        return "fcwstETHwETH USD Oracle";
    }

    /********************************** Internal Functions **********************************/

    function _getPrice() internal view override  returns (int256) {
        uint256 _bptPrice = _minAssetPrice().mulWadDown(BPT.getRate()) * _BASE / wethOracle_decimals;
        uint256 _sharePrice = ERC4626(vault).convertToAssets(_bptPrice);

        // check that vault share price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);
        _checkVaultSpread();

        return int256(_sharePrice);
    }

    function _minAssetPrice() internal view returns (uint256) {
        (, int256 wethPrice, ,uint256 wethUpdatedAt, ) = wEthOracle.latestRoundData();
        (, int256 wstEthPrice, ,uint256 wstEthUpdatedAt, ) = wstEthOracle.latestRoundData();

        if (wethPrice == 0 || wstEthPrice == 0)  revert zeroPrice();
        if (wethUpdatedAt < block.timestamp - (24 * 3600) || wstEthUpdatedAt < block.timestamp - (24 * 3600)) revert stalePrice();
        
        return (uint256(wstEthPrice) >= wstethOracle_decimals) ? uint256(wethPrice) : uint256(wstEthPrice).mulWadDown(uint256(wethPrice)) / wstethOracle_decimals;
    }

    /********************************** Owner Functions **********************************/

    /// @notice this function needs to be called periodically to update the last share price
    function updateLastSharePrice() external override onlyOwner  {
        uint256 _bptPrice = _minAssetPrice().mulWadDown(BPT.getRate()) * _BASE / wethOracle_decimals;
        lastSharePrice = ERC4626(vault).convertToAssets(_bptPrice);

        emit LastSharePriceUpdated(lastSharePrice);
    }

    function updatePriceFeed(address _wETHoracle, address _wstETHoracle) external onlyOwner {
        wEthOracle = IChainlinkAggregator(_wETHoracle);
        wstEthOracle = IChainlinkAggregator(_wstETHoracle);
        wethOracle_decimals = 10 ** wEthOracle.decimals();
        wstethOracle_decimals = 10 ** wstEthOracle.decimals();
    }
}