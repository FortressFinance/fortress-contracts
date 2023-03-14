// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortGlp {

    /// @dev Mints Vault shares to receiver by depositing exact amount of unwrapped underlying assets
    /// @param _underlyingAsset - The address of the underlying asset to deposit
    /// @param _receiver - The receiver of shares
    /// @param _underlyingAssets - The amount of underlying assets to deposit
    /// @param _minAmount - The minimum amount of primary asset to deposit (GLP)
    /// @return _shares - The amount of shares minted
    function depositUnderlying(address _underlyingAsset, address _receiver, uint256 _underlyingAssets, uint256 _minAmount) external returns (uint256 _shares);

    /// @notice that this function is vulnerable to a sandwich/frontrunning attacke if called without asserting the returned value
    /// @dev Burns exact shares from owner and sends assets of unwrapped underlying tokens to _receiver
    /// @param _underlyingAsset - The underlying asset to redeem
    /// @param _shares - The shares to burn
    /// @param _receiver - The address of the receiver of underlying assets
    /// @param _owner - The owner of shares to burn
    /// @return _underlyingAssets - The amount of underlying assets returned to the user
    function redeemUnderlying(address _underlyingAsset, uint256 _shares, address _receiver, address _owner, uint256 _minAmount) external returns (uint256 _underlyingAssets);

    /// @dev Adds the ability to choose the underlying asset to deposit to the base function.
    /// @dev Harvest the pending rewards and convert to underlying token, then stake.
    /// @param _receiver - The address of account to receive harvest bounty.
    /// @param _minBounty - The minimum amount of harvest bounty _receiver should get.
    function harvest(address _receiver, address _underlyingAsset, uint256 _minBounty) external returns (uint256 _rewards);
}