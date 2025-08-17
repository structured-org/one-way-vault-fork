// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {OneWayVault} from "../src/OneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";

contract UpdateOneWayVaultWrapperScript is Script {
    function run() external {
        OneWayVault vault = OneWayVault(vm.envAddress("VAULT"));
        address newWrapper = vm.envAddress("WRAPPER");

        (BaseAccount depositAccount,
         address strategist,
         , // old wrapper: unused
         uint32 depositFeeBps,
         uint32 withdrawFeeBps,
         uint32 maxRateIncrementBps,
         uint32 maxRateDecrementBps,
         uint64 minRateUpdateDelay,
         uint64 maxRateUpdateDelay,
         uint256 depositCap,
         OneWayVault.FeeDistributionConfig memory feeDistribution
        ) = vault.config();
        OneWayVault.OneWayVaultConfig memory config = OneWayVault.OneWayVaultConfig({
            depositAccount: depositAccount,
            strategist: strategist,
            wrapper: newWrapper,
            depositFeeBps: depositFeeBps,
            withdrawFeeBps: withdrawFeeBps,
            maxRateIncrementBps: maxRateIncrementBps,
            maxRateDecrementBps: maxRateDecrementBps,
            minRateUpdateDelay: minRateUpdateDelay,
            maxRateUpdateDelay: maxRateUpdateDelay,
            depositCap: depositCap,
            feeDistribution: feeDistribution
        });

        vm.startBroadcast();
        vault.updateConfig(abi.encode(config));
        vm.stopBroadcast();
    }
}
