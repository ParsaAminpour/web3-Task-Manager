// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TaskToken.sol";

    
contract TaskManager is Ownable, ReentrancyGuard, TaskToken  {
    using ECDSA for bytes32;
    using SignatureChecker for bytes32;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Math for uint256;
    using Address for address;
    using Strings for string;
        

    string public TaskTitle;
    TaskToken public token;
    address public immutable OWNER;
    uint public constant CONST_REWARD_AMOUNT = 10 * (10**18);

    enum TASK_STATUS {
        COMPLETED,
        PENDING,
        CANCELED
    }

    struct TaskDetails {
        address task_owner;
        uint256 task_id; // id will fenerate from VRF
        string task_message;
        uint256 task_created_date;
        uint256 task_complete_period;
        TASK_STATUS task_status;
    }

    mapping(address => mapping(address => TaskDetails)) public TaskGrant;
    mapping(uint => TaskDetails) public IdOfTasks;
    mapping(address => TaskDetails[]) public TasksOwnershipList;
    mapping(address => uint256) public TaskOwnerBudget;
    mapping(uint => bool) public TaskIdActivate;


    event TaskCreated(address indexed owner, uint256 indexed task_id_created);
    event TaskRemoved(address indexed owner, uint256 indexed task_id_removed);
    event TaskUpdated(address indexed owner, uint256 indexed task_id_updated);
    event OwnerRewarded(address indexed owner, uint256 indexed task_id_rewarded, uint256 indexed amount_rewarded);

    constructor(string memory _task_title) {
        require(!(_task_title.equal("")), "invalid Task Title");
        TaskTitle = _task_title;
        token = TaskToken(0xE88d965e34D08df39F98301D24a79Ef736De4e4c);
        OWNER = msg.sender;
    }

    modifier onlyTaskOwner(uint _task_id) {
        require(IdOfTasks[_task_id].task_owner == msg.sender, "You are NOT the task owner");
        _;
    }

    function CreateTask(string memory _task_msg, uint256 _task_completed_date) external returns (bool created) {
        require(!(_task_msg.equal("") && _task_completed_date == block.timestamp), "invalid values inserted");

        uint task_id_gen = uint256(keccak256(abi.encodePacked(msg.sender)));
        TaskDetails memory new_task = TaskDetails(
            msg.sender,
            task_id_gen,
            _task_msg,
            block.timestamp,
            _task_completed_date,
            TASK_STATUS.PENDING
        );

        TasksOwnershipList[new_task.task_owner].push(new_task);
        TaskIdActivate[task_id_gen] = true;

        emit TaskCreated(new_task.task_owner, new_task.task_id);

        created = true;
    }


    function _FindTaskFromTaskOwnershipList(uint _task_id_for_looking) internal view returns(uint) {
        require(_task_id_for_looking < TasksOwnershipList[msg.sender].length, "invalid task id");

        for(uint j=0; j < TasksOwnershipList[msg.sender].length; j++) {
            if(TasksOwnershipList[msg.sender][j].task_id == _task_id_for_looking) return j;
        }
        revert("Not found");
    }


    function removeTask(uint _task_id_for_remove) external onlyTaskOwner(_task_id_for_remove) returns(bool removed) {
        require(TaskIdActivate[_task_id_for_remove], "Task has already canceled");
        TaskDetails memory removing_task = IdOfTasks[_task_id_for_remove];
        require(removing_task.task_status != TASK_STATUS.CANCELED, "task has already canceled");

        removing_task.task_status = TASK_STATUS.CANCELED;

        uint task_index = _FindTaskFromTaskOwnershipList(_task_id_for_remove);
        TasksOwnershipList[msg.sender][task_index] = TasksOwnershipList[msg.sender][TasksOwnershipList[msg.sender].length-1];
        TasksOwnershipList[msg.sender].pop();

        emit TaskRemoved(removing_task.task_owner, removing_task.task_id);
        removed = true;
    }


    /**NOTE: for passing value input if you don't want to update, pass zero value if that type */
    function updateTask(string memory _new_msg, uint _new_time, uint _task_id_for_update) external onlyTaskOwner(_task_id_for_update) returns(bool updated) {
        TaskDetails storage updating_task = IdOfTasks[_task_id_for_update];
        uint task_idx = _FindTaskFromTaskOwnershipList(_task_id_for_update);

        require(!(updating_task.task_message.equal(_new_msg)), "message not new");
        require(_new_time == updating_task.task_complete_period, "complete timestamp is not new");
        require(_new_time != block.timestamp || _new_time > block.timestamp, "new time is not for future");

        if(!(_new_msg.equal(""))) {
            updating_task.task_message = _new_msg;
            TasksOwnershipList[msg.sender][task_idx].task_message = _new_msg;
            updated=true;

        } else if(!(_new_time != 0 && _new_time == block.timestamp)) {
            updating_task.task_complete_period = _new_time;
            TasksOwnershipList[msg.sender][task_idx].task_complete_period = _new_time;
            updated=true;

        } else if(!(_new_msg.equal("")) && !(_new_time != 0 && _new_time == block.timestamp)) {
            updating_task.task_message = _new_msg;
            TasksOwnershipList[msg.sender][task_idx].task_message = _new_msg;
            updating_task.task_complete_period = _new_time;
            TasksOwnershipList[msg.sender][task_idx].task_complete_period = _new_time;
            updated=true;
        }

        updated = false;
        revert("There is no new value for update");
    }

    // function CompleteTask(uint _task_id_for_complete) external onlyTaskOwner(_task_id_for_complete) returns(bool completed) {
    //     require(TaskIdActivate[_task_id_for_complete] == true, "Task has already canceled");

    // }

    function _GetTaskCompletedReward(address _to, uint _amount) internal onlyOwner nonReentrant returns (bool rewarded) {
        require(_to != address(0) && _amount > 0, "invalid inputs");
        TaskOwnerBudget[msg.sender] = TaskOwnerBudget[msg.sender].add(CONST_REWARD_AMOUNT);

        bool success = token.transferFrom(OWNER, _to, _amount);
        require(success, "Transaction failed or occured to some tx problems");
        rewarded = success;
    }
}

contract GenerateRandomness {}