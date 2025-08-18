// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {OneWayVault} from "../src/OneWayVault.sol";
import {BaseAccount} from "../src/BaseAccount.sol";
import {OneWayVaultHelpers} from "../lib/OneWayVault.lib.sol";

contract UpdateOneWayVaultWrapperScript is Script {
    function run() external {
        OneWayVault vault = OneWayVault(vm.envAddress("VAULT"));
        address newWrapper = vm.envAddress("WRAPPER");

        OneWayVault.OneWayVaultConfig memory config = OneWayVaultHelpers.getConfig(vault);
        config.wrapper = newWrapper;

        vm.startBroadcast();
        vault.updateConfig(abi.encode(config));
        vm.stopBroadcast();
    }
}
