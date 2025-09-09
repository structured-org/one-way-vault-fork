// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {KYCOneWayVault} from './KYCOneWayVault.sol';
import {IZkMe} from './IZkMe.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Wrapper is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    struct Config {
        KYCOneWayVault vault;
        IZkMe zkMe;
        address cooperator;
        IERC20 asset;
    }

    /**
     * @dev bytes32(uint256(keccak256('wrapper.config')) - 1)
     */
    bytes32 internal constant _CONFIG_SLOT = 0xc152e5a71b568a04d7b32079a68009d9daed5dc6d0ff6505f851b68b63526089;

    function _getConfig() private pure returns (Config storage $) {
        assembly {
            $.slot := _CONFIG_SLOT
        }
    }

    struct AllowedUsers {
        mapping(address => bool) allowedUsers;
    }

    /**
     * @dev bytes32(uint256(keccak256('wrapper.allowed_users')) - 1)
     */
    bytes32 internal constant _ALLOWED_USERS_SLOT = 0x9f9702eae2e04bd68c59413adb0e3b63f639d94e80b3b11a7f6678c38c2aeff2;

    function _getAllowedUsers() private pure returns (AllowedUsers storage $) {
        assembly {
            $.slot := _ALLOWED_USERS_SLOT
        }
    }

    modifier onlyKyc() {
        // First, check if user is explicitly approved inside of the Wrapper.
        // Only then ask ZkMe if user is approved on its side.
        // This order of execution saves gas, avoiding a call to ZkMe when possible.
        if (
            !_getAllowedUsers().allowedUsers[msg.sender] &&
            !_getConfig().zkMe.hasApproved(_getConfig().cooperator, msg.sender)
        ) {
            revert KycFailed();
        }

        _;
    }

    error KycFailed();

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {
        // Overloaded to protect this function to be ever called only by the owner.
    }

    function setConfig(
        address _vault,
        address _zkMe,
        address _cooperator
    ) external onlyOwner {
        Config storage config = _getConfig();

        config.vault = KYCOneWayVault(_vault);
        config.zkMe = IZkMe(_zkMe);
        config.cooperator = _cooperator;
        config.asset = IERC20(config.vault.asset());
    }

    function allowUser(address _user) external onlyOwner {
        _getAllowedUsers().allowedUsers[_user] = true;
    }

    function removeUser(address _user) external onlyOwner {
        delete _getAllowedUsers().allowedUsers[_user];
    }

    function userAllowed(address _user) external view returns (bool) {
        return _getAllowedUsers().allowedUsers[_user];
    }

    function deposit(uint256 assets, address receiver) external nonReentrant onlyKyc returns (uint256) {
        Config storage config = _getConfig();

        SafeERC20.safeTransferFrom(config.asset, msg.sender, address(this), assets);
        config.asset.approve(address(config.vault), assets);

        uint256 shares = config.vault.deposit(assets, receiver);
        if (shares == 0) {
            _refund(config.asset, assets);
        }
        return shares;
    }

    function mint(uint256 shares, address receiver) external nonReentrant onlyKyc returns (uint256) {
        Config storage config = _getConfig();

        (uint256 assets,) = _getConfig().vault.calculateMintFee(shares);
        SafeERC20.safeTransferFrom(config.asset, msg.sender, address(this), assets);
        config.asset.approve(address(config.vault), assets);

        uint256 assetsDeposited = config.vault.mint(shares, receiver);
        if (assetsDeposited == 0) {
            _refund(config.asset, assets);
        }
        return assetsDeposited;
    }

    function _refund(IERC20 asset, uint256 assets) internal {
        // The vault has paused itself, now we have to refund the user.
        // We do not revert here since we want the vault to be able to
        // update it's pause state successfully.
        SafeERC20.safeTransfer(asset, msg.sender, assets);
    }
}
