// SPDX-License-Identifier: AGPL
pragma solidity 0.8.17;

import {Auth, Authority} from "@solmate/auth/Auth.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import {IRouteFactory} from "./interfaces/IRouteFactory.sol";

import "./Base.sol";

/// @title Orchestrator
/// @author johnnyonline (Puppet Finance) https://github.com/johnnyonline
/// @notice This contract contains the logic and storage for managing routes and puppets
contract Orchestrator is Auth, Base, IOrchestrator {

    using SafeERC20 for IERC20;
    using Address for address payable;

    // settings
    address public vaultFactory;

    bool private _paused;

    // vaults info

    // investors info

    // ============================================================================================
    // Constructor
    // ============================================================================================

    constructor(address _owner, address _vaultFactory) {
        owner = _owner;
        vaultFactory = _vaultFactory;
    }

    // ============================================================================================
    // Modifiers
    // ============================================================================================


    // ============================================================================================
    // View Functions
    // ============================================================================================

    // vault

    function getVaultKey(address _manager, string calldata _description) public view returns (bytes32 _vaultKey) {
        return keccak256(abi.encodePacked(_manager, _description));
    }

    function getvault(bytes32 _vaultKey) external view returns (address) {
        return _vaultInfo[_vaultKey].vault;
    }

    function investors(bytes32 _vaultKey) external view returns (address[] memory _investors) {
        // todo
    }

    // ============================================================================================
    // Manager Function
    // ============================================================================================

    function registerVault(address _collateralToken, address _indexToken, bool _isLong) public nonReentrant returns (bytes32 _routeKey) {
        if (_collateralToken == address(0) || _indexToken == address(0)) revert ZeroAddress();

        bytes32 _routeTypeKey = getRouteTypeKey(_collateralToken, _indexToken, _isLong);
        if (!routeType[_routeTypeKey].isRegistered) revert RouteTypeNotRegistered();

        _routeKey = getRouteKey(msg.sender, _routeTypeKey);
        if (_routeInfo[_routeKey].isRegistered) revert RouteAlreadyRegistered();

        address _routeAddr = IRouteFactory(routeFactory).createRoute(address(this), msg.sender, _collateralToken, _indexToken, _isLong);

        RouteType memory _routeType = RouteType({
            collateralToken: _collateralToken,
            indexToken: _indexToken,
            isLong: _isLong,
            isRegistered: true
        });

        RouteInfo storage _route = _routeInfo[_routeKey];

        _route.route = _routeAddr;
        _route.isRegistered = true;
        _route.routeType = _routeType;

        isRoute[_routeAddr] = true;
        _routes.push(_routeAddr);

        emit RegisterRoute(msg.sender, _routeAddr, _routeTypeKey);
    }

    /// @inheritdoc IOrchestrator
    function registerRouteAndRequestPosition(
        IRoute.AdjustPositionParams memory _adjustPositionParams,
        IRoute.SwapParams memory _swapParams,
        uint256 _executionFee,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external payable returns (bytes32 _routeKey, bytes32 _requestKey) {
        _routeKey = registerRoute(_collateralToken, _indexToken, _isLong);
        _requestKey = requestPosition(
            _adjustPositionParams,
            _swapParams,
            getRouteTypeKey(_collateralToken, _indexToken, _isLong),
            _executionFee,
            true
        );
    }

    /// @inheritdoc IOrchestrator
    function requestPosition(
        IRoute.AdjustPositionParams memory _adjustPositionParams,
        IRoute.SwapParams memory _swapParams,
        bytes32 _routeTypeKey,
        uint256 _executionFee,
        bool _isIncrease
    ) public payable nonReentrant returns (bytes32 _requestKey) {
        address _route = _routeInfo[getRouteKey(msg.sender, _routeTypeKey)].route;
        if (_route == address(0)) revert RouteNotRegistered();

        _requestKey = IRoute(_route).requestPosition{ value: msg.value }(
            _adjustPositionParams,
            _swapParams,
            _executionFee,
            _isIncrease
        );

        emit RequestPositionAdjustment(msg.sender, _route, _routeTypeKey, _requestKey);
    }

    /// @inheritdoc IOrchestrator
    function approvePlugin(bytes32 _routeTypeKey) external {
        address _route = _routeInfo[getRouteKey(msg.sender, _routeTypeKey)].route;
        if (_route == address(0)) revert RouteNotRegistered();

        IRoute(_route).approvePlugin();

        emit ApprovePlugin(msg.sender, _routeTypeKey);
    }

    // ============================================================================================
    // Puppet Functions
    // ============================================================================================

    /// @inheritdoc IOrchestrator
    function updateRouteSubscription(uint256 _allowance, address _trader, bytes32 _routeTypeKey, bool _subscribe) public nonReentrant {
        bytes32 _routeKey = getRouteKey(_trader, _routeTypeKey);
        RouteInfo storage _route = _routeInfo[_routeKey];
        PuppetInfo storage _puppet = _puppetInfo[msg.sender];

        if (!_route.isRegistered) revert RouteNotRegistered();
        if (IRoute(_route.route).isWaitingForCallback()) revert RouteWaitingForCallback();

        if (_subscribe) {
            if (_allowance > _BASIS_POINTS_DIVISOR || _allowance == 0) revert InvalidAllowancePercentage();

            EnumerableMap.set(_puppet.allowances, _route.route, _allowance);
            EnumerableSet.add(_route.puppets, msg.sender);
        } else {
            EnumerableMap.remove(_puppet.allowances, _route.route);
            EnumerableSet.remove(_route.puppets, msg.sender);
        }

        emit Subscribe(_allowance, _trader, msg.sender, _routeTypeKey, _subscribe);
    }

    /// @inheritdoc IOrchestrator
    function updateRoutesSubscriptions(
        uint256[] memory _allowances,
        address[] memory _traders,
        bytes32[] memory _routeTypeKeys,
        bool[] memory _subscribe
    ) external {
        if (_traders.length != _allowances.length) revert MismatchedInputArrays();
        if (_traders.length != _subscribe.length) revert MismatchedInputArrays();
        if (_traders.length != _routeTypeKeys.length) revert MismatchedInputArrays();

        for (uint256 i = 0; i < _traders.length; i++) {
            updateRouteSubscription(_allowances[i], _traders[i], _routeTypeKeys[i], _subscribe[i]);
        }
    }

    /// @inheritdoc IOrchestrator
    function deposit(uint256 _amount, address _asset, address _puppet) external payable nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (_puppet == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();
        if (msg.value > 0) {
            if (_amount != msg.value) revert InvalidAmount();
            if (_asset != _WETH) revert InvalidAsset();
        }

        _puppetInfo[_puppet].depositAccount[_asset] += _amount;

        if (msg.value > 0) {
            payable(_asset).functionCallWithValue(abi.encodeWithSignature("deposit()"), _amount);
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit Deposit(_amount, _asset, msg.sender, _puppet);
    }

    /// @inheritdoc IOrchestrator
    function withdraw(uint256 _amount, address _asset, address _receiver, bool _isETH) external nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (_receiver == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();
        if (_isETH && _asset != _WETH) revert InvalidAsset();
 
        _puppetInfo[msg.sender].depositAccount[_asset] -= _amount;

        if (_isETH) {
            IWETH(_asset).withdraw(_amount);
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_asset).safeTransfer(_receiver, _amount);
        }

        emit Withdraw(_amount, _asset, _receiver, msg.sender);
    }


    /// @inheritdoc IOrchestrator
    function setThrottleLimit(uint256 _throttleLimit, bytes32 _routeType) external {
        _puppetInfo[msg.sender].throttleLimits[_routeType] = _throttleLimit;

        emit SetThrottleLimit(msg.sender, _routeType, _throttleLimit);
    }

    // ============================================================================================
    // Route Functions
    // ============================================================================================

    /// @inheritdoc IOrchestrator
    function debitPuppetAccount(uint256 _amount, address _asset, address _puppet) external onlyRoute {
        _puppetInfo[_puppet].depositAccount[_asset] -= _amount;

        emit DebitPuppet(_amount, _asset, _puppet, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function creditPuppetAccount(uint256 _amount, address _asset, address _puppet) external onlyRoute {
        _puppetInfo[_puppet].depositAccount[_asset] += _amount;

        emit CreditPuppet(_amount, _asset, _puppet, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function updateLastPositionOpenedTimestamp(address _puppet, bytes32 _routeType) external onlyRoute {
        _puppetInfo[_puppet].lastPositionOpenedTimestamp[_routeType] = block.timestamp;

        emit UpdateOpenTimestamp(_puppet, _routeType, block.timestamp);
    }

    /// @inheritdoc IOrchestrator
    function sendFunds(uint256 _amount, address _asset, address _receiver) external onlyRoute {
        IERC20(_asset).safeTransfer(_receiver, _amount);

        emit Send(_amount, _asset, _receiver, msg.sender);
    }

    /// @inheritdoc IOrchestrator
    function emitCallback(bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external onlyRoute {
        emit Callback(msg.sender, _requestKey, _isExecuted, _isIncrease);
    }

    // ============================================================================================
    // Authority Functions
    // ============================================================================================

    // called by keeper

    /// @inheritdoc IOrchestrator
    function decreaseSize(
        IRoute.AdjustPositionParams memory _adjustPositionParams,
        uint256 _executionFee,
        bytes32 _routeKey
    ) external payable requiresAuth nonReentrant returns (bytes32 _requestKey) {
        address _route = _routeInfo[_routeKey].route;
        if (_route == address(0)) revert RouteNotRegistered();

        _requestKey = IRoute(_route).decreaseSize{ value: msg.value }(_adjustPositionParams, _executionFee);

        emit DecreaseSize(_requestKey, _routeKey);
    }

    /// @inheritdoc IOrchestrator
    function liquidate(bytes32 _routeKey) external requiresAuth nonReentrant {
        address _route = _routeInfo[_routeKey].route;
        if (_route == address(0)) revert RouteNotRegistered();

        IRoute(_route).liquidate();

        emit Liquidate(_routeKey);
    }

    // called by owner

    /// @inheritdoc IOrchestrator
    function rescueTokens(uint256 _amount, address _token, address _receiver) external requiresAuth nonReentrant {
        if (_token == address(0)) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }

        emit Rescue(_amount, _token, _receiver);
    }

    /// @inheritdoc IOrchestrator
    function rescueRouteTokens(uint256 _amount, address _token, address _receiver, address _route) external requiresAuth nonReentrant {
        IRoute(_route).rescueTokens(_amount, _token, _receiver);

        emit RouteRescue(_amount, _token, _receiver, _route);
    }

    /// @inheritdoc IOrchestrator
    function freezeRoute(address _route, bool _freeze) external requiresAuth nonReentrant {
        IRoute(_route).freeze(_freeze);

        emit FreezeRoute(_route, _freeze);
    }

    /// @inheritdoc IOrchestrator
    function setRouteType(address _collateral, address _index, bool _isLong) external requiresAuth nonReentrant {
        bytes32 _routeTypeKey = getRouteTypeKey(_collateral, _index, _isLong);
        routeType[_routeTypeKey] = RouteType(_collateral, _index, _isLong, true);

        emit SetRouteType(_routeTypeKey, _collateral, _index, _isLong);
    }

    /// @inheritdoc IOrchestrator
    function setGMXInfo(address _gmxRouter, address _gmxVault, address _gmxPositionRouter) external requiresAuth nonReentrant {
        GMXInfo storage _gmx = _gmxInfo;

        _gmx.gmxRouter = _gmxRouter;
        _gmx.gmxVault = _gmxVault;
        _gmx.gmxPositionRouter = _gmxPositionRouter;

        emit SetGMXUtils(_gmxRouter, _gmxVault, _gmxPositionRouter);
    }

    /// @inheritdoc IOrchestrator
    function setKeeper(address _keeperAddr) external requiresAuth nonReentrant {
        if (_keeperAddr == address(0)) revert ZeroAddress();

        _keeper = _keeperAddr;

        emit Keeper(_keeper);
    }

    /// @inheritdoc IOrchestrator
    function setReferralCode(bytes32 _refCode) external requiresAuth nonReentrant {
        if (_refCode == bytes32(0)) revert ZeroBytes32();

        _referralCode = _refCode;

        emit SetReferralCode(_refCode);
    }

    /// @inheritdoc IOrchestrator
    function setRouteFactory(address _factory) external requiresAuth nonReentrant {
        if (_factory == address(0)) revert ZeroAddress();

        routeFactory = _factory;

        emit SetRouteFactory(_factory);
    }

    /// @inheritdoc IOrchestrator
    function pause(bool _pause) external requiresAuth nonReentrant {
        _paused = _pause;

        emit Pause(_pause);
    }

    // ============================================================================================
    // Receive Function
    // ============================================================================================

    receive() external payable {}
}