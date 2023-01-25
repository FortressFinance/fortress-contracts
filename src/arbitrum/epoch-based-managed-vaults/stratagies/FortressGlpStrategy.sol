// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseStrategy} from "./BaseStrategy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFortGlp} from "./interfaces/IFortGlp.sol";

contract FortressGlpStrategy is BaseStrategy {

    /// @notice The address of fortGLP
    address public fortGlp;
    
    /********************************** Constructor **********************************/

    constructor(address[] memory _assets, address _assetVault, address _platform, address _manager, address _fortGlp)
        BaseStrategy(_assets, _assetVault, _platform, _manager) {
            fortGlp = _fortGlp;
        }

    /********************************** View Functions **********************************/

    function isActive() public view override returns (bool) {
        if (isStrategiesActiveOverride) return false;

        if (IERC20(fortGlp).balanceOf(address(this)) > 0) {
            return true;
        } else {
            return false;
        }
    }

    /********************************** Manager Functions **********************************/

    function DepositToFortGlp(uint256 _amount, uint256 _minAmount) external onlyManager returns (uint256 _shares) {
        _shares = IFortGlp(fortGlp).depositUnderlying(assetVaultAsset, _amount, address(this), _minAmount);
    }

    function RedeemFromFortGlp(uint256 _shares, uint256 _minAmount) external onlyManager returns (uint256 _amount) {
        _amount = IFortGlp(fortGlp).redeemUnderlying(assetVaultAsset, _shares, address(this), address(this), _minAmount);
    }

    function RedeemAllFromFortGlp(uint256 _minAmount) external onlyManager returns (uint256 _amount) {
        _amount = IFortGlp(fortGlp).redeemUnderlying(assetVaultAsset, IERC20(fortGlp).balanceOf(address(this)), address(this), address(this), _minAmount);
    }
}
