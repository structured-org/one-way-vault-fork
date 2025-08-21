// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {ZkMeMock} from "../src/mock/ZkMeMock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {IERC20Errors} from "@openzeppelin-contracts-5.2.0/interfaces/draft-IERC6093.sol";
import {ERC4626Upgradeable} from "@openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {KYCOneWayVaultHelpers} from "../lib/KYCOneWayVault.lib.sol";

contract KYCOneWayVaultTest is Test {
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
        underlyingToken = new ERC20Mock();
        zkMe = new ZkMeMock();

        // README step 2
        KYCOneWayVault implementation = new KYCOneWayVault();

        // README step 3
        depositAccount = new BaseAccount(OWNER, new address[](0));

        // README step 4
        wrapper = new Wrapper(OWNER);

        // README step 5
        KYCOneWayVault.FeeDistributionConfig memory feeConfig = KYCOneWayVault.FeeDistributionConfig({
            strategistAccount: STRATEGIST,
            platformAccount: PLATFORM,
            strategistRatioBps: uint32(0)
        });
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVault.KYCOneWayVaultConfig({
            depositAccount: BaseAccount(payable(address(depositAccount))),
            strategist: STRATEGIST,
            wrapper: address(wrapper),
            depositFeeBps: uint32(0),
            withdrawFeeBps: uint32(0),
            maxRateIncrementBps: uint32(0),
            maxRateDecrementBps: uint32(0),
            minRateUpdateDelay: uint64(0),
            maxRateUpdateDelay: uint64(1),
            depositCap: uint256(0),
            feeDistribution: feeConfig
        });
        bytes memory initializeCall = abi.encodeCall(KYCOneWayVault.initialize, (
            OWNER,
            abi.encode(config),
            address(underlyingToken),
            "vTEST",
            "vSYMBOL",
            10 ** underlyingToken.decimals()
        ));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initializeCall);
        vault = KYCOneWayVault(address(proxy));

        // README step 6
        wrapper.setConfig(address(vault), address(zkMe), COOPERATOR, true);
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

    function testWithdrawSuccess() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        wrapper.deposit(100, USER);
        vault.approve(address(wrapper), 100);
        wrapper.withdraw(100, "test_receiver");

        (uint64 id,
         address owner,
         uint256 redemptionRate,
         uint256 sharesAmount,
         string memory receiver
        ) = vault.withdrawRequests(0);
        assertEq(id, 0);
        assertEq(owner, USER);
        assertEq(redemptionRate, 10 ** 18);
        assertEq(sharesAmount, 100);
        assertEq(receiver, "test_receiver");
    }

    function testWithdrawFailureNoFunds() public {
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        vault.approve(address(wrapper), 100);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector, USER, 100, 0));
        wrapper.withdraw(100, "test_receiver");
    }

    function testWithdrawFailureNotEnoughFunds() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 20);
        wrapper.deposit(20, USER);
        vault.approve(address(wrapper), 100);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxWithdraw.selector, USER, 100, 20));
        wrapper.withdraw(100, "test_receiver");
    }

    function testWithdrawFailureNoALlowance() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        wrapper.deposit(100, USER);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(wrapper), 0, 100));
        wrapper.withdraw(100, "test_receiver");
    }

    function testWithdrawFailureNotEnoughAllowance() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        wrapper.deposit(100, USER);
        vault.approve(address(wrapper), 20);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(wrapper), 20, 100));
        wrapper.withdraw(100, "test_receiver");
    }

    function testVaultDirectDepositForbidden() public {
        underlyingToken.transfer(USER, 1000);

        vm.startPrank(USER);
        vm.expectRevert("Only wrapper allowed");
        vault.deposit(100, USER);
    }

    function testVaultDirectWithdrawForbidden() public {
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        wrapper.deposit(100, USER);

        vm.expectRevert("Only wrapper allowed");
        vault.withdraw(100, "test_receiver", USER);
    }

    function testWithdrawDisabled() public {
        wrapper.setConfig(address(vault), address(zkMe), COOPERATOR, false);
        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 100);
        wrapper.deposit(100, USER);
        vault.approve(address(wrapper), 100);

        vm.expectRevert(abi.encodeWithSelector(Wrapper.WithdrawsDisabled.selector));
        wrapper.withdraw(100, "test_receiver");
    }

    function testDepositCapOverflow() public {
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVaultHelpers.getConfig(vault);
        config.depositCap = 200;
        vault.updateConfig(abi.encode(config));

        underlyingToken.transfer(USER, 1000);
        wrapper.allowUser(USER);

        vm.startPrank(USER);
        underlyingToken.approve(address(wrapper), 1000);

        wrapper.deposit(150, USER);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxDeposit.selector, USER, 100, 50));
        wrapper.deposit(100, USER);

        wrapper.deposit(50, USER);

        vm.expectRevert(abi.encodeWithSelector(ERC4626Upgradeable.ERC4626ExceededMaxDeposit.selector, USER, 20, 0));
        wrapper.deposit(20, USER);
    }
}
