// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Meme} from "./Meme.sol";

contract Factory {
    constructor() {}

    function creataMemeCoin(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply)
        external
        returns (address)
    {
        Meme contractAddress = new Meme(name, symbol, decimals, totalSupply);
        return address(contractAddress);
    }
}
