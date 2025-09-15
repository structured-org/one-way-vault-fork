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
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract WrapperTest is Test {
    address constant OWNER = address(1);
    address constant STRATEGIST = address(2);
    address constant PLATFORM = address(3);
    address constant COOPERATOR = address(4);
    address constant USER = address(5);
    address constant USER2 = address(6);

    ERC20Mock underlyingToken;
    BaseAccount depositAccount;
    ZkMeMock zkMe;
    KYCOneWayVault vault;
    Wrapper wrapper;

    function setUp() public {
        vm.startPrank(OWNER, OWNER);
        (underlyingToken, depositAccount, zkMe, vault, wrapper) =
            KYCOneWayVaultHelpers.deployTestEnvironment(OWNER, STRATEGIST, PLATFORM, COOPERATOR);
    }

    function testDepositSuccessKycWrapper() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 100, 50);
        uint256 shares = wrapper.deposit(100, USER);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessKycZkMe() public {
        underlyingToken.transfer(USER, 1000);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 100, 50);
        uint256 shares = wrapper.deposit(100, USER);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessKycWrapperAndZkMe() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 100, 50);
        uint256 shares = wrapper.deposit(100, USER);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessCustomReceiver() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER2, 100, 50);
        uint256 shares = wrapper.deposit(100, USER2);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER2), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositFailureNoFunds() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, USER, 0, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureNotEnoughFunds() public {
        underlyingToken.transfer(USER, 50);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, USER, 50, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureNoAllowance() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(vault), 0, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureNotEnoughAllowance() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 50);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(vault), 50, 100));
        wrapper.deposit(100, USER);
    }

    function testDepositFailureKyc() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectRevert(Wrapper.KycFailed.selector);
        wrapper.deposit(100, USER);
    }

    function testDepositStaleRatePause() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        skip(10); // forwards time beyond maxRateUpdateDelay
        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);
        uint256 shares = wrapper.deposit(100, USER);

        assertEq(shares, 0);
        assertEq(vault.balanceOf(USER), 0);
        assertEq(underlyingToken.balanceOf(USER), 1000);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 0);

        KYCOneWayVault.VaultState memory state = KYCOneWayVaultHelpers.getState(vault);
        assertEq(state.paused, true);
        assertEq(state.pausedByOwner, false);
        assertEq(state.pausedByStaleRate, true);
    }

    function testMintSuccessKycWrapper() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 200, 100);
        uint256 assets = wrapper.mint(100, USER);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintSuccessZkMe() public {
        underlyingToken.transfer(USER, 1000);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 200, 100);
        uint256 assets = wrapper.mint(100, USER);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintSuccessWrapperAndZkMe() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 200, 100);
        uint256 assets = wrapper.mint(100, USER);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintSuccessCustomReceiver() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER2, 200, 100);
        uint256 assets = wrapper.mint(100, USER2);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER2), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintFailureNoFunds() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, USER, 0, 200));
        wrapper.mint(100, USER);
    }

    function testMintFailureNotEnoughFunds() public {
        underlyingToken.transfer(USER, 50);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, USER, 50, 200));
        wrapper.mint(100, USER);
    }

    function testMintFailureNoAllowance() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(vault), 0, 200));
        wrapper.mint(100, USER);
    }

    function testMintFailureNotEnoughAllowance() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 50);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(vault), 50, 200));
        wrapper.mint(100, USER);
    }

    function testMintFailureKyc() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectRevert(Wrapper.KycFailed.selector);
        wrapper.mint(100, USER);
    }

    function testMintStaleRatePause() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        skip(10); // forwards time beyond maxRateUpdateDelay
        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);
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
