// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployWrapperScript is Script {
    function run() external {
        address owner = vm.envAddress("OWNER");
        address implementation = vm.envAddress("IMPLEMENTATION");

        bytes memory initializeCall = abi.encodeCall(Wrapper.initialize, (owner));

        vm.startBroadcast();
        ERC1967Proxy proxy = new ERC1967Proxy(implementation, initializeCall);
        vm.stopBroadcast();

        console.log("Wrapper address:", address(proxy));
        console.log("Configuration:");
        console.log("  Implementation:", implementation);
        console.log("  Owner:         ", owner);
    }
}
