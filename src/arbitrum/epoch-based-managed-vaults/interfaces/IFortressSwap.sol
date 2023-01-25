// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortressSwap {

    /// @notice swap _amount of _fromToken to _toToken.
    /// @param _fromToken The address of the token to swap from.
    /// @param _toToken The address of the token to swap to.
    /// @param _amount The amount of _fromToken to swap.
    /// @return _amount The amount of _toToken after swap.  
    function swap(address _fromToken, address _toToken, uint256 _amount) external payable returns (uint256);
}