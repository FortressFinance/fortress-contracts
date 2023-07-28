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
// ==============================================================
// ================== FortressWstETHwETHOracle ==================
// ==============================================================

// Github - https://github.com/FortressFinance

import {IBalancerV2StablePool} from "../interfaces/IBalancerV2StablePool.sol";
import {IBalancerVault} from "../interfaces/IBalancerVault.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {ERC4626} from "@solmate/mixins/ERC4626.sol";

contract FortressWstETHwETHOracle {

    using FixedPointMathLib for uint256;

    uint256 public lastSharePrice;
    uint256 public lowerBoundPercentage;
    uint256 public upperBoundPercentage;
    uint256 public vaultMaxSpread;
    uint256 public virtualPriceUpperBound;

    address public owner;
    address public vault;

    uint256 public ethUSDFeed_decimals = 1e8;
    uint256 public wstEthETHFeed_decimals = 1e18;

    bool public isCheckPriceDeviation;

    uint256 constant internal _BASE = 1e18;

    IChainlinkAggregator public ethUSDFeed = IChainlinkAggregator(address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612));
    IChainlinkAggregator public wstEthETHFeed = IChainlinkAggregator(address(0xb523AE262D20A936BC152e6023996e46FDC2A95D));
    IBalancerV2StablePool public BPT = IBalancerV2StablePool(address(0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f));

    /********************************** Constructor **********************************/

    constructor(address _owner, address _vault) {
        lowerBoundPercentage = 20;
        upperBoundPercentage = 20;
        virtualPriceUpperBound = 1.1 * 1e18;

        owner = _owner;
        vault = _vault;

        uint256 _vaultSpread = ERC4626(_vault).convertToAssets(1e18);
        vaultMaxSpread = _vaultSpread * 110 / 100; // limit to 10% of the vault spread

        lastSharePrice = uint256(_getPrice());

        isCheckPriceDeviation = true;
    }

    /********************************** Modifiers **********************************/

    modifier reentrancyCheck() {
        IBalancerVault(BPT.getVault()).manageUserBalance(new IBalancerVault.UserBalanceOp[](0));
        _;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert notOwner();
        _;
    }

    /********************************** External Functions **********************************/

    function decimals() external pure virtual returns (uint8) {
        return 18;
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }

    function description() external pure returns (string memory) {
        return "fcwstETHwETH USD Oracle";
    }

    function getRoundData(uint80) external pure returns (uint80, int256, uint256, uint256, uint80) {
        revert("Not implemented");
    }

    function latestRoundData() external returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, _getPrice(), 0, 0, 0);
    }

    /********************************** Internal Functions **********************************/

    function _getPrice() internal reentrancyCheck returns (int256) {
        uint256 rate = BPT.getRate();
        if (rate < 1*1e18 || rate >= virtualPriceUpperBound)  revert virtualPriceOutOfBounds();
        uint256 _bptPrice = _minAssetPrice().mulWadDown(rate) * _BASE / ethUSDFeed_decimals;
        uint256 _sharePrice = ERC4626(vault).convertToAssets(_bptPrice);

        // check that vault share price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);
        _checkVaultSpread();

        return int256(_sharePrice);
    }

    function _minAssetPrice() internal view returns (uint256) {
        (, int256 ethPrice, ,uint256 ethUpdatedAt, ) = ethUSDFeed.latestRoundData();
        (, int256 wstEthPrice, ,uint256 wstEthUpdatedAt, ) = wstEthETHFeed.latestRoundData();

        if (ethPrice <= 0 || wstEthPrice <= 0)  revert zeroPrice();
        if (ethUpdatedAt < block.timestamp - (24 * 3600) || wstEthUpdatedAt < block.timestamp - (24 * 3600)) revert stalePrice();
        
        return (uint256(wstEthPrice) >= wstEthETHFeed_decimals) ? uint256(ethPrice) : uint256(wstEthPrice).mulWadDown(uint256(ethPrice)) / wstEthETHFeed_decimals;
    }

    function _checkVaultSpread() internal view {
        if (ERC4626(vault).convertToAssets(1e18) > vaultMaxSpread) revert vaultMaxSpreadExceeded();
    }

    function _checkPriceDeviation(uint256 _sharePrice) internal view {
        uint256 _lastSharePrice = lastSharePrice;
        uint256 _lowerBound = (_lastSharePrice * (100 - lowerBoundPercentage)) / 100;
        uint256 _upperBound = (_lastSharePrice * (100 + upperBoundPercentage)) / 100;

        if (_sharePrice < _lowerBound || _sharePrice > _upperBound) revert priceDeviationTooHigh();
    }
    /********************************** Owner Functions **********************************/

    /// @notice this function needs to be called periodically to update the last share price
    function updateLastSharePrice() external onlyOwner  {
        uint256 _bptPrice = _minAssetPrice().mulWadDown(BPT.getRate()) * _BASE / ethUSDFeed_decimals;
        lastSharePrice = ERC4626(vault).convertToAssets(_bptPrice);

        emit LastSharePriceUpdated(lastSharePrice);
    }

    function updatePriceFeed(address _ethUSDFeed, address _wstEthETHFeed) external onlyOwner {
        ethUSDFeed = IChainlinkAggregator(_ethUSDFeed);
        wstEthETHFeed = IChainlinkAggregator(_wstEthETHFeed);
        ethUSDFeed_decimals = 10 ** ethUSDFeed.decimals();
        wstEthETHFeed_decimals = 10 ** wstEthETHFeed.decimals();
    }
    
    function shouldCheckPriceDeviation(bool _check) external onlyOwner {
        isCheckPriceDeviation = _check;

        emit PriceDeviationCheckUpdated(_check);
    }

    function updatePriceDeviationBounds(uint256 _lowerBoundPercentage, uint256 _upperBoundPercentage) external onlyOwner {
        lowerBoundPercentage = _lowerBoundPercentage;
        upperBoundPercentage = _upperBoundPercentage;

        emit PriceDeviationBoundsUpdated(_lowerBoundPercentage, _upperBoundPercentage);
    }

    function updateVaultMaxSpread(uint256 _vaultMaxSpread) external onlyOwner {
        vaultMaxSpread = _vaultMaxSpread;

        emit VaultMaxSpreadUpdated(_vaultMaxSpread);
    }

    function updateVirtualPriceUpperBound(uint256 _virtualPriceUpperBound) external onlyOwner {
        virtualPriceUpperBound = _virtualPriceUpperBound;

        emit VirtualPriceUpperBound(_virtualPriceUpperBound);
    }

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;

        emit OwnershipTransferred(owner, _owner);
    }
    
    /********************************** Events **********************************/

    event LastSharePriceUpdated(uint256 lastSharePrice);
    event PriceDeviationCheckUpdated(bool isCheckPriceDeviation);
    event PriceDeviationBoundsUpdated(uint256 lowerBoundPercentage, uint256 upperBoundPercentage);
    event VaultMaxSpreadUpdated(uint256 vaultMaxSpread);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PriceFeedUpdated(address indexed usdtPriceFeed, address indexed usdcPriceFeed);
    event VirtualPriceUpperBound(uint256 virtualPriceUpperBound);

    /********************************** Errors **********************************/

    error priceDeviationTooHigh();
    error vaultMaxSpreadExceeded();
    error notOwner();
    error zeroPrice();
    error stalePrice();
    error reentrancy();
    error didNotConverge();
    error virtualPriceOutOfBounds();
}