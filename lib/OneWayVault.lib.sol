// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {OneWayVault} from "../src/OneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";

library OneWayVaultHelpers {
    function getConfig(OneWayVault vault) internal view returns (OneWayVault.OneWayVaultConfig memory) {
        (BaseAccount depositAccount,
         address strategist,
         address wrapper,
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
            wrapper: wrapper,
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
}
