// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Meme} from "./Meme.sol";
import {Raffle} from "./Raffle.sol";

contract Factory {
    constructor() {}

    function creataMemeCoin(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply)
        external
        returns (address)
    {
        Meme contractAddress = new Meme(name, symbol, decimals, totalSupply);
        return address(contractAddress);
    }

    function createRaffle(
        address meme,
        uint256 memeBounty,
        uint256 winnerBounty,
        uint256 entrancefee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) external returns (address) {
        Raffle raffle = new Raffle(
            meme,
            memeBounty,
            winnerBounty,
            entrancefee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        return address(raffle);
    }
}
