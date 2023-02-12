// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortressSwap {

    /// @dev Checks if a certain swap route is available
    /// @param _fromToken - The address of the input token
    /// @param _toToken - The address of the output token
    /// @return - Whether the route exist
    function routeExists(address _fromToken, address _toToken) external view returns (bool);

    /// @notice Swaps _amount of _fromToken to _toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @param _amount The amount of _fromToken to swap
    /// @return _amount The amount of _toToken after swap
    function swap(address _fromToken, address _toToken, uint256 _amount) external payable returns (uint256);

    /// @notice Updates a swap route from _fromToken to _toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @param _poolType The types of the pools
    /// @param _poolAddress The addresses of the pools
    /// @param _fromList The tokens to swap from
    /// @param _toList The tokens to swap to
    function updateRoute(address _fromToken, address _toToken, uint256[] memory _poolType, address[] memory _poolAddress, address[] memory _fromList, address[] memory _toList) external;

    /// @dev Delete a swap route.
    /// @param _fromToken - The address of the input token.
    /// @param _toToken - The address of the output token.
    function deleteRoute(address _fromToken, address _toToken) external;    
}