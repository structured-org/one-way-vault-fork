// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {ZkMeMock} from "../src/mock/ZkMeMock.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {IERC20Errors} from "@openzeppelin-contracts-5.2.0/interfaces/draft-IERC6093.sol";
import {KYCOneWayVaultHelpers} from "../lib/KYCOneWayVault.lib.sol";

contract WrapperTest is Test {
    address constant OWNER = address(1);
    address constant STRATEGIST = address(2);
    address constant PLATFORM = address(3);
    address constant COOPERATOR = address(4);
    address constant USER = address(5);

    ERC20Mock underlyingToken;
    BaseAccount depositAccount;
    ZkMeMock zkMe;
    KYCOneWayVault vault;
    Wrapper wrapper;

    function setUp() public {
        vm.startPrank(OWNER);
        (underlyingToken, depositAccount, zkMe, vault, wrapper) =
            KYCOneWayVaultHelpers.deployTestEnvironment(OWNER, STRATEGIST, PLATFORM, COOPERATOR);
    }

    function testDepositSuccessKycWrapper() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        uint256 assets = wrapper.deposit(100, USER);

        assertEq(assets, 100);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessKycZkMe() public {
        underlyingToken.transfer(USER, 1000);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        uint256 assets = wrapper.deposit(100, USER);

        assertEq(assets, 100);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessKycWrapperAndZkMe() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        uint256 assets = wrapper.deposit(100, USER);

        assertEq(assets, 100);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositFailureNoFunds() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, USER, 0, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureNotEnoughFunds() public {
        underlyingToken.transfer(USER, 50);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, USER, 50, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureNoAllowance() public {
        underlyingToken.transfer(USER, 50);
        wrapper.allowUser(USER);

        vm.startPrank(USER);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(wrapper), 0, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureNotEnoughAllowance() public {
        underlyingToken.transfer(USER, 50);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 50);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(wrapper), 50, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureKyc() public {
        underlyingToken.transfer(USER, 100);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);

        vm.expectRevert(Wrapper.KycFailed.selector);
        wrapper.deposit(100, USER);
    }

    function testDepositRefund() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        skip(10); // forwards time beyond maxRateUpdateDelay
        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        uint256 assets = wrapper.deposit(100, USER);

        assertEq(assets, 0);
        assertEq(vault.balanceOf(USER), 0);
        assertEq(underlyingToken.balanceOf(USER), 1000);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 0);

        KYCOneWayVault.VaultState memory state = KYCOneWayVaultHelpers.getState(vault);
        assertEq(state.paused, true);
        assertEq(state.pausedByOwner, false);
        assertEq(state.pausedByStaleRate, true);
    }

    function testManualUserApproval() public {
        assertEq(wrapper.userAllowed(USER), false);
        wrapper.allowUser(USER);
        assertEq(wrapper.userAllowed(USER), true);
        wrapper.removeUser(USER);
        assertEq(wrapper.userAllowed(USER), false);
    }
}
