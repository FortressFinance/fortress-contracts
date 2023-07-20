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

//  _____         _                   _____     _ _____             _       _____             _     
// |   __|___ ___| |_ ___ ___ ___ ___|_   _|___|_|     |___ _ _ ___| |_ ___|     |___ ___ ___| |___ 
// |   __| . |  _|  _|  _| -_|_ -|_ -| | | |  _| |   --|  _| | | . |  _| . |  |  |  _| .'|  _| | -_|
// |__|  |___|_| |_| |_| |___|___|___| |_| |_| |_|_____|_| |_  |  _|_| |___|_____|_| |__,|___|_|___|
//                                                         |___|_|                                  

// Github - https://github.com/FortressFinance

import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {ICurveV2Pool} from "../interfaces/ICurveV2Pool.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {ERC4626} from "@solmate/mixins/ERC4626.sol";

contract FortressTriCryptoOracle {

    using FixedPointMathLib for uint256;

    uint256 public lastSharePrice;
    uint256 public lowerBoundPercentage;
    uint256 public upperBoundPercentage;
    uint256 public vaultMaxSpread;

    address public owner;
    address public vault;

    bool public isCheckPriceDeviation;

    uint256 constant internal _BASE = 1e18;
    
    IChainlinkAggregator public btcUSDFeed = IChainlinkAggregator(address(0x6ce185860a4963106506C203335A2910413708e9));
    IChainlinkAggregator public ethUSDFeed = IChainlinkAggregator(address(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612));
    IChainlinkAggregator public usdtUSDFeed = IChainlinkAggregator(address(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7));

    address public constant triCrypto = 0x960ea3e3C7FB317332d990873d354E18d7645590;

    /********************************** Constructor **********************************/

    constructor(address _owner, address _vault) {
        lowerBoundPercentage = 20;
        upperBoundPercentage = 20;
        
        owner = _owner;
        vault = _vault;

        uint256 _vaultSpread = ERC4626(_vault).convertToAssets(1e18);
        vaultMaxSpread = _vaultSpread * 110 / 100; // limit to 10% of the vault spread

        lastSharePrice = uint256(_getPrice());

        isCheckPriceDeviation = true;
    }

    /********************************** Modifiers **********************************/

    modifier reentrancyCheck() {
        ICurveV2Pool(triCrypto).claim_admin_fees();
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
        return "fcTriCrypto USD Oracle";
    }
    function getRoundData(uint80) external pure returns (uint80, int256, uint256, uint256, uint80) {
        revert("Not implemented");
    }

    function latestRoundData() external returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (0, _getPrice(), 0, 0, 0);
    }

    /********************************** Internal Functions **********************************/

    function _getPrice() internal reentrancyCheck returns (int256) {
        uint256 _lpPrice = _getLPprice(
            _getUSDPrice(btcUSDFeed) * 1e10,
            _getUSDPrice(ethUSDFeed) * 1e10,
            _getUSDPrice(usdtUSDFeed) * 1e10
        );
        uint256 _sharePrice = ERC4626(vault).convertToAssets(_lpPrice);

        // check that vault share price deviation did not exceed the configured bounds
        if (isCheckPriceDeviation) _checkPriceDeviation(_sharePrice);
        _checkVaultSpread();

        return int256(_sharePrice);
    }

    function _getUSDPrice(IChainlinkAggregator _feed) internal view returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = _feed.latestRoundData();
        
        if (answer <= 0) revert zeroPrice();
        if (updatedAt < block.timestamp - (24 * 3600)) revert stalePrice();
        
        return uint256(answer);
    }

    function _getLPprice(uint p1, uint p2, uint p3) internal view returns(uint256) {
        uint256 virtualPrice = ICurveV2Pool(triCrypto).get_virtual_price();
        if (virtualPrice < 1*1e18 || virtualPrice >= 1.1*1e18)  revert virtualPriceOutOfBounds();

        return 3 * ICurveV2Pool(triCrypto).get_virtual_price() * cubicRoot(p1 * p2 / 1e18 * p3) / 1e18;
    }

    function cubicRoot(uint x) internal pure returns (uint) {
        uint D = x / 1e18;
        for (uint i; i < 255;) {
            uint D_prev = D;
            D = D * (2e18 + x / D * 1e18 / D * 1e18 / D) / (3e18);
            uint diff = (D > D_prev) ? D - D_prev : D_prev - D;
            if (diff < 2 || diff * 1e18 < D) return D;
            unchecked { ++i; }
        }
        revert didNotConverge();
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
        uint256 _lpPrice = _getLPprice(
            _getUSDPrice(btcUSDFeed) * 1e10,
            _getUSDPrice(ethUSDFeed) * 1e10,
            _getUSDPrice(usdtUSDFeed) * 1e10
        );
        lastSharePrice = ERC4626(vault).convertToAssets(_lpPrice);
        emit LastSharePriceUpdated(lastSharePrice);
    }

    function updatePriceFeed(address _btcUSDFeed, address _ethUSDFeed, address _usdtUSDFeed) external onlyOwner {
        btcUSDFeed = IChainlinkAggregator(_btcUSDFeed);
        ethUSDFeed = IChainlinkAggregator(_ethUSDFeed);
        usdtUSDFeed = IChainlinkAggregator(_usdtUSDFeed);
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