// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortGlp {

    /// @dev Mints Vault shares to receiver by depositing exact amount of unwrapped underlying assets
    /// @param _underlyingAsset - The address of the underlying asset to deposit
    /// @param _underlyingAssets - The amount of underlying assets to deposit
    /// @param _receiver - The receiver of shares
    /// @param _minAmount - The minimum amount of primary asset to deposit (GLP)
    /// @return _shares - The amount of shares minted
    function depositUnderlying(address _underlyingAsset, uint256 _underlyingAssets, address _receiver, uint256 _minAmount) external returns (uint256 _shares);

    /// @notice that this function is vulnerable to a sandwich/frontrunning attacke if called without asserting the returned value
    /// @dev Burns exact shares from owner and sends assets of unwrapped underlying tokens to _receiver
    /// @param _underlyingAsset - The underlying asset to redeem
    /// @param _shares - The shares to burn
    /// @param _receiver - The address of the receiver of underlying assets
    /// @param _owner - The owner of shares to burn
    /// @return _underlyingAssets - The amount of underlying assets returned to the user
    function redeemUnderlying(address _underlyingAsset, uint256 _shares, address _receiver, address _owner, uint256 _minAmount) external returns (uint256 _underlyingAssets);
}