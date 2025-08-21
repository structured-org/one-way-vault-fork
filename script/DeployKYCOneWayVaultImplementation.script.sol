// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {KYCOneWayVault} from "../src/KYCOneWayVault.sol";

contract DeployKYCOneWayVaultImplementationScript is Script {
    function run() external {
        vm.startBroadcast();
        KYCOneWayVault vault = new KYCOneWayVault();
        vm.stopBroadcast();

        console.log("KYCOneWayVault address:", address(vault));
    }
}
