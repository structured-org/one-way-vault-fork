// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {OneWayVault} from "../src/OneWayVault.sol";

contract DeployOneWayVaultImplementationScript is Script {
    function run() external {
        vm.startBroadcast();
        OneWayVault vault = new OneWayVault();
        vm.stopBroadcast();

        console.log("OneWayVault address:", address(vault));
    }
}
