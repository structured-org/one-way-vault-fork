// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("tNAME", "tSYMBOL") {
        _mint(msg.sender, 100 * (10 ** decimals()));
    }
}
