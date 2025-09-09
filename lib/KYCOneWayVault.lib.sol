// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {ERC20Mock} from "../src/mock/ERC20Mock.sol";
import {ZkMeMock} from "../src/mock/ZkMeMock.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

library KYCOneWayVaultHelpers {
    function getConfig(KYCOneWayVault vault) internal view returns (KYCOneWayVault.KYCOneWayVaultConfig memory) {
        (BaseAccount depositAccount,
         address strategist,
         uint32 depositFeeBps,
         uint32 withdrawFeeBps,
         uint32 maxRateIncrementBps,
         uint32 maxRateDecrementBps,
         uint64 minRateUpdateDelay,
         uint64 maxRateUpdateDelay,
         uint256 depositCap,
         KYCOneWayVault.FeeDistributionConfig memory feeDistribution
        ) = vault.config();
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVault.KYCOneWayVaultConfig({
            depositAccount: depositAccount,
            strategist: strategist,
            depositFeeBps: depositFeeBps,
            withdrawFeeBps: withdrawFeeBps,
            maxRateIncrementBps: maxRateIncrementBps,
            maxRateDecrementBps: maxRateDecrementBps,
            minRateUpdateDelay: minRateUpdateDelay,
            maxRateUpdateDelay: maxRateUpdateDelay,
            depositCap: depositCap,
            feeDistribution: feeDistribution
        });
        return config;
    }

    function getState(KYCOneWayVault vault) internal view returns (KYCOneWayVault.VaultState memory) {
        (bool paused,
         bool pausedByOwner,
         bool pausedByStaleRate
        ) = vault.vaultState();
        KYCOneWayVault.VaultState memory state = KYCOneWayVault.VaultState({
            paused: paused,
            pausedByOwner: pausedByOwner,
            pausedByStaleRate: pausedByStaleRate
        });
        return state;
    }

    function deployTestEnvironment(
        address owner,
        address strategist,
        address platform,
        address cooperator
    ) internal returns (
        ERC20Mock underlyingToken,
        BaseAccount depositAccount,
        ZkMeMock zkMe,
        KYCOneWayVault vault,
        Wrapper wrapper
    ) {
        underlyingToken = new ERC20Mock();
        zkMe = new ZkMeMock();

        // README step 2
        KYCOneWayVault vaultImplementation = new KYCOneWayVault();

        // README step 3
        Wrapper wrapperImplementation = new Wrapper();

        // README step 4
        depositAccount = new BaseAccount(owner, new address[](0));

        // README step 5
        bytes memory wrapperInitializeCall = abi.encodeCall(Wrapper.initialize, (owner));
        ERC1967Proxy wrapperProxy = new ERC1967Proxy(address(wrapperImplementation), wrapperInitializeCall);
        wrapper = Wrapper(address(wrapperProxy));

        // README step 6
        KYCOneWayVault.FeeDistributionConfig memory feeConfig = KYCOneWayVault.FeeDistributionConfig({
            strategistAccount: strategist,
            platformAccount: platform,
            strategistRatioBps: uint32(0)
        });
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVault.KYCOneWayVaultConfig({
            depositAccount: BaseAccount(payable(address(depositAccount))),
            strategist: strategist,
            depositFeeBps: uint32(0),
            withdrawFeeBps: uint32(0),
            maxRateIncrementBps: uint32(0),
            maxRateDecrementBps: uint32(0),
            minRateUpdateDelay: uint64(0),
            maxRateUpdateDelay: uint64(1),
            depositCap: uint256(0),
            feeDistribution: feeConfig
        });
        bytes memory vaultInitializeCall = abi.encodeCall(KYCOneWayVault.initialize, (
            owner,
            abi.encode(config),
            address(underlyingToken),
            "vTEST",
            "vSYMBOL",
            10 ** underlyingToken.decimals() * 2,
            address(wrapper)
        ));
        ERC1967Proxy vaultProxy = new ERC1967Proxy(address(vaultImplementation), vaultInitializeCall);
        vault = KYCOneWayVault(address(vaultProxy));

        // README step 7
        wrapper.setConfig(address(vault), address(zkMe), cooperator);
    }
}
