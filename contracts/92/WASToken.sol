// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WASToken is ERC20{
    constructor() ERC20("Win the championship chain", "WAS") {
        _mint(msg.sender, 23119 * 10 ** decimals());
    }
}