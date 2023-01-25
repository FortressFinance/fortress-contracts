// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseStrategy} from "./BaseStrategy.sol";

import {IFortGlp} from "./interfaces/IFortGlp.sol";

contract FortressGlpStrategy is BaseStrategy {

    /// @notice The address of fortGLP
    address public fortGlp;
    
    /********************************** Constructor **********************************/
    
    // constructor(
    //         address[] _assets,
    //         address _assetVault,
    //         address _platform,
    //         address _manager,
    //         address _swap,
    //         address _fortGlp
    //     )
    //     BaseStrategy(
    //         address[] _assets,
    //         address _assetVault,
    //         address _platform,
    //         address _manager,
    //         address _swap
    //     ) {
    //         fortGlp = _fortGlp;
    //     }

    constructor(
            address[] _assets,
            address _assetVault,
            address _platform,
            address _manager,
            address _swap,
            address _fortGlp
        ) public {
            super(_assets, _assetVault, _platform, _manager, _swap);
            fortGlp = _fortGlp;
        }


    /********************************** View Functions **********************************/

    function isActive() public view virtual returns (bool) {
        if (isStrategiesActiveOverride) return false;

        if (IERC20(fortGlp).balanceOf(address(this)) > 0) {
            return true;
        } else {
            return false;
        }
    }

    /********************************** Manager Functions **********************************/

    function DepositToFortGlp(uint256 _amount, uint256 _minAmount) external onlyManager returns (uint256 _shares) {
        _shares = IFortGlp(_fortGlp).depositUnderlying(_assetVaultAsset, _amount, address(this), _minAmount);
    }

    function RedeemFromFortGlp(uint256 _shares, uint256 _minAmount) external onlyManager returns (uint256 _amount) {
        _amount = IFortGlp(fortGlp).redeemUnderlying(assetVaultAsset, _shares, address(this), address(this), _minAmount);
    }

    function RedeemAllFromFortGlp(uint256 _minAmount) external onlyManager returns (uint256 _amount) {
        _amount = IFortGlp(fortGlp).redeemUnderlying(assetVaultAsset, IFortGlp(fortGlp).balanceOf(address(this)), address(this), address(this), _minAmount);
    }
}
