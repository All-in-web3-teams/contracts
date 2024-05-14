// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Factory} from "../src/Factory.sol";

contract Deploy is Script {
    Factory factory;

    function run() external {
        vm.startBroadcast();
        factory = new Factory();
        factory.creataMemeCoin("Dogie", "DOG", 18, 1000 ether);
        vm.stopBroadcast();
    }
}
