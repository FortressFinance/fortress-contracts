// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortressVault {

    function depositSingleUnderlying(uint256 _underlyingAmount, address _underlyingAsset, address _receiver, uint256 _minAmount) external payable returns (uint256 _shares);
    
    function redeemSingleUnderlying(uint256 _shares, address _underlyingAsset, address _receiver, address _owner, uint256 _minAmount) external returns (uint256 _underlyingAmount);
}