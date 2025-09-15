// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {ZkMeMock} from "../src/mock/ZkMeMock.sol";
import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {KYCOneWayVaultHelpers} from "../lib/KYCOneWayVault.lib.sol";
import {ERC4626Upgradeable} from "@openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

contract KYCOneWayVaultTest is Test {
    address constant OWNER = address(1);
    address constant STRATEGIST = address(2);
    address constant PLATFORM = address(3);
    address constant COOPERATOR = address(4);
    address constant USER = address(5);
    address constant NEW_WRAPPER = address(6);

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

    function testDepositCapOverflow() public {
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVaultHelpers.getConfig(vault);
        config.depositCap = 200;
        vault.updateConfig(abi.encode(config));

        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(vault), 1000);

        wrapper.deposit(150, USER);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxDeposit.selector, USER, 100, 50));
        wrapper.deposit(100, USER);

        wrapper.deposit(50, USER);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxDeposit.selector, USER, 20, 0));
        wrapper.deposit(20, USER);
    }

    function testUpdateWrapper() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER, USER);
        underlyingToken.approve(address(wrapper), 100);

        vm.startPrank(OWNER, OWNER);
        vault.updateWrapper(NEW_WRAPPER);

        vm.startPrank(USER, USER);
        vm.expectRevert("Only wrapper allowed");
        wrapper.deposit(100, USER);
    }

    function testDirectDepositForbidden() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER, USER);
        vm.expectRevert("Only wrapper allowed");
        vault.deposit(100, USER);
    }

    function testDirectMintForbidden() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER, USER);
        vm.expectRevert("Only wrapper allowed");
        vault.mint(100, USER);
    }
}
