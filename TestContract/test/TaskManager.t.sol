// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TaskManager} from "../src/TaskManager.sol";

contract TaskManagerTest is Test {
    TaskManager public manager;

    function setUp() public {
        manager = new TaskManager('programming');
    }

    function TestCreateTask() public {
        vm.startPrank(address(1));

        bool result = manager.CreateTask('Writing test units', block.timestamp);
        // TaskDetails  new_task = manager.TaskOwnership[address(1)];
        assertEq(result, true);
    }
}
