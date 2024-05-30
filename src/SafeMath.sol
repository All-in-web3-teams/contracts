// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

/**
 * @title 乘除防溢出合约
 * @author
 * @notice
 *    功能：防止乘除法溢出报错
 */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;
        return c;
    }
}
