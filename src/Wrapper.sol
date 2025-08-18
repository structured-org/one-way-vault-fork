// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OneWayVault} from './OneWayVault.sol';
import {IZkMe} from './IZkMe.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Wrapper is Ownable {
    OneWayVault public vault;
    IZkMe public zkMe;
    address public cooperator;
    IERC20 public asset;
    bool public withdrawsEnabled;

    mapping(address => bool) allowedUsers;

    error KycFailed();

    error WithdrawsDisabled();

    constructor(
        address _owner,
        address _vault,
        address _zkMe,
        address _cooperator,
        bool _withdrawsEnabled
    ) Ownable(_owner) {
        vault = OneWayVault(_vault);
        zkMe = IZkMe(_zkMe);
        cooperator = _cooperator;
        asset = IERC20(vault.asset());
        withdrawsEnabled = _withdrawsEnabled;
    }

    modifier onlyKyc() {
        // first, check if user is explicitly approved
        // only then ask ZkMe if user is approved
        // saves gas, avoiding a call to ZkMe when possible
        if (!allowedUsers[msg.sender] && !zkMe.hasApproved(cooperator, msg.sender)) {
            revert KycFailed();
        }
        _;
    }

    function allowUser(address _user) external onlyOwner {
        allowedUsers[_user] = true;
    }

    function removeUser(address _user) external onlyOwner {
        delete allowedUsers[_user];
    }

    function setWithdraws(bool _withdrawsEnabled) external onlyOwner {
        withdrawsEnabled = _withdrawsEnabled;
    }

    function deposit(uint256 assets, address receiver) public onlyKyc returns (uint256) {
        SafeERC20.safeTransferFrom(asset, msg.sender, address(this), assets);
        asset.approve(address(vault), assets);
        return vault.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, string calldata receiver) external {
        if (!withdrawsEnabled) {
            revert WithdrawsDisabled();
        }

        vault.withdraw(assets, receiver, msg.sender);
    }
}
