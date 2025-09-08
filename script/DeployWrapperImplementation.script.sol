// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {Wrapper} from "../src/Wrapper.sol";

contract DeployWrapperImplementationScript is Script {
    function run() external {
        vm.startBroadcast();
        Wrapper wrapper = new Wrapper();
        vm.stopBroadcast();

        console.log("Wrapper address:", address(wrapper));
    }
}
