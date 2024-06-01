// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Factory} from "../src/Factory.sol";
import {Raffle} from "../src/Raffle.sol";
import {Meme} from "../src/Meme.sol";

contract Deploy is Script {
    Raffle raffle;

    function run() external {
        vm.startBroadcast();
        raffle = new Raffle(
            0x80A910Bf53197fCfb86edfab2D15AD1B45e416f3,
            1 ether,
            2 ether,
            0.001 ether,
            10,
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            12028636780673054411511968850501490050736241887773570890910866643877582681825,
            500_000
        );
        vm.stopBroadcast();
    }
}
