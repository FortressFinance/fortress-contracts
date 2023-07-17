// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveV2Pool {

    function get_virtual_price() external view returns (uint256 price);

    function A() external view returns (uint256);
    
    function gamma() external view returns (uint256);

    function claim_admin_fees() external;

    function remove_liquidity_one_coin(uint256, int128, uint256) external;
}