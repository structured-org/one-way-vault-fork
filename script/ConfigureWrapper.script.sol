// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {Wrapper} from "../src/Wrapper.sol";

contract DeployWrapperScript is Script {
    function run() external {
        Wrapper wrapper = Wrapper(vm.envAddress("WRAPPER"));
        address vault = vm.envAddress("VAULT");
        address zkMe = vm.envAddress("ZK_ME");
        address cooperator = vm.envAddress("COOPERATOR");
        bool withdrawsEnabled = vm.envBool("WITHDRAWS_ENABLED");

        vm.startBroadcast();
        wrapper.setConfig(vault, zkMe, cooperator, withdrawsEnabled);
        vm.stopBroadcast();
    }
}
