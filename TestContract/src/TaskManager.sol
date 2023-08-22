// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/utils/math/Math.sol";
import "openzeppelin/utils/Address.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";

contract TaskManager is Ownable {
    using Math for uint;
    using Address for address;
    using Strings for string;

    string public TaskTitle;

    enum TASK_STATUS { COMPLETED, PENDING, CANCELED }

    struct TaskDetails {
        address task_owner; uint task_id; // id will fenerate from VRF
        string task_message; uint task_created_date;
        uint task_complete_period; TASK_STATUS task_status;
    }

    mapping(address => mapping(address => TaskDetails)) public TaskGrant;
    mapping(address => TaskDetails) public TaskOwnership;
    mapping(address => TaskDetails[]) public TasksOwnershipList;
    mapping(address => uint) public TaskOwnerBudget;

    event TaskCreated(address indexed owner, uint indexed task_id_created);
    event TaskRemoved(address indexed owner, uint indexed task_id_removed);
    event TaskUpdated(address indexed owner, uint indexed task_id_updated);
    event OwnerRewarded(address indexed owner, uint indexed task_id_rewarded, uint indexed amount_rewarded);




    constructor(string memory _task_title) {
        require(!(_task_title.equal("")), "invalid Task Title");
        TaskTitle = _task_title;
    }

    function CreateTask(string memory _task_msg, uint _task_completed_date) external returns(bool created){
        require(!(_task_msg.equal("") && _task_completed_date == block.timestamp), "invalid values inserted");
        
        TaskDetails memory new_task = TaskDetails(
            msg.sender, uint(keccak256(abi.encodePacked(msg.sender))), _task_msg,
            block.timestamp, _task_completed_date, TASK_STATUS.PENDING
        );

        TaskOwnership[new_task.task_owner] = new_task;
        TasksOwnershipList[new_task.task_owner].push(new_task);

        emit TaskCreated(new_task.task_owner, new_task.task_id);
        
        created = true;
    }

    function removeTask() external returns(bool removed){}

    function updateTask() external returns(bool updated){}

    function GetTaskCompletedReward() external returns(bool rewarded){}
}