// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "script/mainnet/utils/Addresses.sol";

contract InitBase is Addresses {
    
    uint256[] _poolType1 = new uint256[](1);
    uint256[] _poolType2 = new uint256[](2);
    uint256[] _poolType3 = new uint256[](3);
    uint256[] _poolType4 = new uint256[](4);
    
    address[] _poolAddress1 = new address[](1);
    address[] _poolAddress2 = new address[](2);
    address[] _poolAddress3 = new address[](3);
    address[] _poolAddress4 = new address[](4);

    address[] _fromList1 = new address[](1);
    address[] _fromList2 = new address[](2);
    address[] _fromList3 = new address[](3);
    address[] _fromList4 = new address[](4);
    
    address[] _toList1 = new address[](1);
    address[] _toList2 = new address[](2);
    address[] _toList3 = new address[](3);
    address[] _toList4 = new address[](4);

    uint256 _boosterPoolId;
    uint256 _poolType;
    address _asset;
    string _symbol;
    string _name;

    address[] _rewardAssets2 = new address[](2);
    address[] _rewardAssets3 = new address[](2);

    address[] _underlyingAssets2 = new address[](2);
    address[] _underlyingAssets3 = new address[](3);
}