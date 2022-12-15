// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IFortressBaseVault {

    function deposit(uint256 _assets, address _receiver) external returns (uint256 _shares);

    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _assets);

    function depositUnderlying(uint256 _underlyingAmount, address _receiver, uint256 _minAmount) external returns (uint256 _shares);

    function redeemUnderlying(uint256 _shares, address _receiver, address _owner, uint256 _minAmount) external returns (uint256 _assets);
}