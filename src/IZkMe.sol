// Copyright Structured
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

interface IZkMe {
    function hasApproved(address _cooperator, address _user) external view returns (bool);
}
