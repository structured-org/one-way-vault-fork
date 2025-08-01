// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {BaseAccount} from "../src/BaseAccount.sol";

contract DeployBaseAccountScript is Script {
    function run() external {
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast();
        BaseAccount baseAccount = new BaseAccount(owner, new address[](0));
        vm.stopBroadcast();

        console.log("BaseAccount address:", address(baseAccount));
        console.log("Configuration:");
        console.log("  Owner:", owner);
    }
}
