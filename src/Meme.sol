// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Meme is ERC20, ERC20Burnable, Ownable {
    uint8 private s_decimal;

    constructor(string memory name, string memory symbol, uint8 decimal, uint256 totalSupply)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        s_decimal = decimal;
        _mint(msg.sender, totalSupply);
    }

    function decimals() public view override returns (uint8) {
        return s_decimal;
    }
}
