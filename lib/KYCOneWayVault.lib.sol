// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";

library KYCOneWayVaultHelpers {
    function getConfig(KYCOneWayVault vault) internal view returns (KYCOneWayVault.KYCOneWayVaultConfig memory) {
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
         KYCOneWayVault.FeeDistributionConfig memory feeDistribution
        ) = vault.config();
        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVault.KYCOneWayVaultConfig({
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
