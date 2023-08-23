// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TaskToken} from "../src/TaskToken.sol";

contract TaskTokenTest is Test {
    TaskToken public token;

    function setUp() public {
        token = new TaskToken();
    }
}
