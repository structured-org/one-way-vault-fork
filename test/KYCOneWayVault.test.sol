// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {ZkMeMock} from "../src/mock/ZkMeMock.sol";
import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {KYCOneWayVaultHelpers} from "../lib/KYCOneWayVault.lib.sol";
import {ERC4626Upgradeable} from "@openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract KYCOneWayVaultTest is Test {
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

    function setUp() public {
        vm.startPrank(OWNER);
        (underlyingToken, depositAccount, zkMe, vault) =
            KYCOneWayVaultHelpers.deployTestEnvironment(OWNER, STRATEGIST, PLATFORM, COOPERATOR);
    }

    function testDepositSuccessKycExplicit() public {
        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 100, 50);
        uint256 shares = vault.deposit(100, USER);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessKycZkMe() public {
        underlyingToken.transfer(USER, 1000);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 100, 50);
        uint256 shares = vault.deposit(100, USER);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessKycExplicitAndZkMe() public {
        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 100, 50);
        uint256 shares = vault.deposit(100, USER);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositSuccessCustomReceiver() public {
        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER2, 100, 50);
        uint256 shares = vault.deposit(100, USER2);

        assertEq(shares, 50);
        assertEq(vault.balanceOf(USER2), 50);
        assertEq(underlyingToken.balanceOf(USER), 900);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 100);
    }

    function testDepositFailureKyc() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 100);

        vm.expectRevert(KYCOneWayVault.KycFailed.selector);
        vault.deposit(100, USER);
    }

    function testMintSuccessKycExplicit() public {
        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 200, 100);
        uint256 assets = vault.mint(100, USER);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintSuccessZkMe() public {
        underlyingToken.transfer(USER, 1000);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 200, 100);
        uint256 assets = vault.mint(100, USER);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintSuccessExplicitAndZkMe() public {
        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);
        zkMe.setApproved(COOPERATOR, USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER, 200, 100);
        uint256 assets = vault.mint(100, USER);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintSuccessCustomReceiver() public {
        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectEmit(true, true, true, true);
        emit IERC4626.Deposit(USER, USER2, 200, 100);
        uint256 assets = vault.mint(100, USER2);

        assertEq(assets, 200);
        assertEq(vault.balanceOf(USER2), 100);
        assertEq(underlyingToken.balanceOf(USER), 800);
        assertEq(underlyingToken.balanceOf(address(depositAccount)), 200);
    }

    function testMintFailureKyc() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 200);

        vm.expectRevert(KYCOneWayVault.KycFailed.selector);
        vault.mint(100, USER);
    }

    function testManualUserApproval() public {
        assertEq(vault.userAllowed(USER), false);
        vault.setUserAllowed(USER, true);
        assertEq(vault.userAllowed(USER), true);
        vault.setUserAllowed(USER, false);
        assertEq(vault.userAllowed(USER), false);
    }

    function testDepositCapOverflow() public {
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVaultHelpers.getConfig(vault);
        config.depositCap = 200;
        vault.updateConfig(abi.encode(config));

        underlyingToken.transfer(USER, 1000);
        vault.setUserAllowed(USER, true);

        vm.startPrank(USER);
        underlyingToken.approve(address(vault), 1000);

        vault.deposit(150, USER);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxDeposit.selector, USER, 100, 50));
        vault.deposit(100, USER);

        vault.deposit(50, USER);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxDeposit.selector, USER, 20, 0));
        vault.deposit(20, USER);
    }
}
