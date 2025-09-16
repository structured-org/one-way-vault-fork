// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployKYCOneWayVaultScript is Script {
    function run() external {
        address owner = vm.envAddress("OWNER");
        address implementation = vm.envAddress("IMPLEMENTATION");
        address underlyingToken = vm.envAddress("UNDERLYING_TOKEN");
        address depositAccount = vm.envAddress("DEPOSIT_ACCOUNT");
        address strategist = vm.envAddress("STRATEGIST");
        address platform = vm.envAddress("PLATFORM");
        uint256 strategistRatioBps = vm.envOr("STRATEGIST_RATIO_BPS", uint256(0));
        uint256 depositFeeBps = vm.envOr("DEPOSIT_FEE_BPS", uint256(0));
        uint256 withdrawFeeBps = vm.envOr("WITHDRAW_FEE_BPS", uint256(0));
        uint256 maxRateIncrementBps = vm.envOr("MAX_RATE_INCREMENT_BPS", uint256(10000));
        uint256 maxRateDecrementBps = vm.envOr("MAX_RATE_DECREMENT_BPS", uint256(5000));
        uint256 minRateUpdateDelay = vm.envOr("MIN_RATE_UPDATE_DELAY", uint256(0));
        uint256 maxRateUpdateDelay = vm.envOr("MAX_RATE_UPDATE_DELAY", uint256(86400));
        uint256 depositCap = vm.envOr("DEPOSIT_CAP", uint256(0));
        string memory vaultTokenName = vm.envString("VAULT_TOKEN_NAME");
        string memory vaultTokenSymbol = vm.envString("VAULT_TOKEN_SYMBOL");

        uint256 defaultStartingRate = 10 ** ERC20(underlyingToken).decimals();
        uint256 startingRate = vm.envOr("STARTING_RATE", defaultStartingRate);

        KYCOneWayVault.FeeDistributionConfig memory feeConfig = KYCOneWayVault.FeeDistributionConfig({
            strategistAccount: strategist,
            platformAccount: platform,
            strategistRatioBps: uint32(strategistRatioBps)
        });

        KYCOneWayVault.KYCOneWayVaultConfig memory config = KYCOneWayVault.KYCOneWayVaultConfig({
            depositAccount: BaseAccount(payable(address(depositAccount))),
            strategist: strategist,
            depositFeeBps: uint32(depositFeeBps),
            withdrawFeeBps: uint32(withdrawFeeBps),
            maxRateIncrementBps: uint32(maxRateIncrementBps),
            maxRateDecrementBps: uint32(maxRateDecrementBps),
            minRateUpdateDelay: uint64(minRateUpdateDelay),
            maxRateUpdateDelay: uint64(maxRateUpdateDelay),
            depositCap: depositCap,
            feeDistribution: feeConfig
        });

        bytes memory initializeCall = abi.encodeCall(KYCOneWayVault.initialize, (
            owner,
            abi.encode(config),
            underlyingToken,
            vaultTokenName,
            vaultTokenSymbol,
            startingRate
        ));

        vm.startBroadcast();
        ERC1967Proxy proxy = new ERC1967Proxy(implementation, initializeCall);
        vm.stopBroadcast();

        console.log("KYCOneWayVault address:", address(proxy));
        console.log("Configuration:");
        console.log("  Implementation:        ", implementation);
        console.log("  Owner:                 ", owner);
        console.log("  Deposit account:       ", depositAccount);
        console.log("  Strategist:            ", strategist);
        console.log("  Deposit fee BPS:       ", depositFeeBps);
        console.log("  Withdraw fee BPS:      ", withdrawFeeBps);
        console.log("  Max rate increment BPS:", maxRateIncrementBps);
        console.log("  Max rate decrement BPS:", maxRateDecrementBps);
        console.log("  Min rate update delay: ", minRateUpdateDelay);
        console.log("  Max rate update delay: ", maxRateUpdateDelay);
        console.log("  Deposit cap:           ", depositCap);
        console.log("  Fee distribution:");
        console.log("    Strategist account:    ", strategist);
        console.log("    Platform account:      ", platform);
        console.log("    Strategist ratio BPS:  ", strategistRatioBps);
        console.log("  Underlying token:      ", underlyingToken);
        console.log("  Vault token name:      ", vaultTokenName);
        console.log("  Vault token symbol:    ", vaultTokenSymbol);
        console.log("  Starting rate:         ", startingRate);
    }
}
