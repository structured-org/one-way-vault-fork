// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {Wrapper} from "../src/Wrapper.sol";

contract DeployWrapperScript is Script {
    function run() external {
        address owner = vm.envAddress("OWNER");
        address vault = vm.envAddress("VAULT");
        address zkMe = vm.envAddress("ZK_ME");
        address cooperator = vm.envAddress("COOPERATOR");
        bool withdrawsEnabled = vm.envBool("WITHDRAWS_ENABLED");

        vm.startBroadcast();
        Wrapper wrapper = new Wrapper(owner, vault, zkMe, cooperator, withdrawsEnabled);
        vm.stopBroadcast();

        console.log("Wrapper address:", address(wrapper));
        console.log("Configuration:");
        console.log("  Owner:            ", owner);
        console.log("  Vault:            ", vault);
        console.log("  ZkMe:             ", zkMe);
        console.log("  Cooperator:       ", cooperator);
        console.log("  Withdraws enabled:", withdrawsEnabled);
    }
}
