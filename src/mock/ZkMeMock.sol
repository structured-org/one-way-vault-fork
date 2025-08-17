// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {IZkMe} from '../IZkMe.sol';

contract ZkMeMock is IZkMe {
    mapping(address => mapping(address => bool)) public approves;

    constructor() {}

    function setApproved(address _cooperator, address _user, bool _approved) public {
        approves[_cooperator][_user] = _approved;
    }

    function hasApproved(address _cooperator, address _user) public view returns (bool) {
        return approves[_cooperator][_user];
    }
}
