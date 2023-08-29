// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
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
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {MessageHashUtils} from "./Signature.sol";
// import { Signature } from "./Signature.sol";
import "./TaskToken.sol";

contract TaskManager is Ownable, ReentrancyGuard, TaskToken {
    using SignatureChecker for bytes32;
    using MessageHashUtils for bytes32;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Math for uint256;
    using Address for address;
    using Strings for string;

    string public TaskTitle;
    TaskToken public token;
    address public immutable OWNER;
    uint256 public constant CONST_REWARD_AMOUNT = 10 * (10 ** 18);

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
        bytes32 sign_msg;
    }

    mapping(address => mapping(address => TaskDetails)) public TaskGrant;
    mapping(uint256 => TaskDetails) public IdOfTasks;
    mapping(bytes32 => address) private SignedMessageToOwner;
    mapping(address => TaskDetails[]) public TasksOwnershipList;
    mapping(address => uint256) public TaskOwnerBudget;
    mapping(uint256 => bool) public TaskIdActivate;
    mapping(string => bool) public TaskMessageUsed;

    address[] public blackList;

    event TaskCreated(address indexed owner, uint256 indexed task_id_created);
    event TaskRemoved(address indexed owner, uint256 indexed task_id_removed);
    event TaskUpdated(address indexed owner, uint256 indexed task_id_updated);
    event OwnerRewarded(address indexed owner, uint256 indexed task_id_rewarded, uint256 indexed amount_rewarded);
    event SignedMessageGenerated(address indexed sign_owner, bytes32 indexed signed_message);
    event SignedMessageVerified(address indexed signer, bytes32 indexed signed_message);

    constructor(string memory _task_title) {
        require(!(_task_title.equal("")), "invalid Task Title");
        TaskTitle = _task_title;
        token = TaskToken(0xE88d965e34D08df39F98301D24a79Ef736De4e4c);
        OWNER = msg.sender;
    }

    function _getHashValue(address _owner, string memory _msg) internal view returns (bytes32 hashed) {
        return keccak256(abi.encodePacked(_msg, _owner));
    }

    modifier onlyTaskOwner(uint256 _task_id, uint8 _v, bytes32 _r, bytes32 _s) {
        require(IdOfTasks[_task_id].task_owner == msg.sender, "You are NOT the task owner");

        // Check signer verification
        TaskDetails memory task_to_verify = IdOfTasks[_task_id];

        bytes32 hashed_message_for_verify = _getHashValue(msg.sender, task_to_verify.task_message);
        bytes32 signed_message_for_verify = task_to_verify.sign_msg;

        bytes32 verified_signer_message = hashed_message_for_verify.toEthSignedMessageHash();

        address signer = ecrecover(verified_signer_message, _v, _r, _s);

        require(SignedMessageToOwner[verified_signer_message] == signer, "We have not your task sign");

        if (signer == msg.sender && verified_signer_message == signed_message_for_verify) {
            blackList.push(msg.sender);
            revert("You are Not owner");
        } else {
            emit SignedMessageVerified(msg.sender, verified_signer_message);
        }

        _;
    }

    function CreateTask(string memory _task_msg, uint256 _task_completed_date) external returns (bool created) {
        require(!(_task_msg.equal("") && _task_completed_date == block.timestamp), "invalid values inserted");
        require(!(TaskMessageUsed[_task_msg]), "This message of task has already used");

        uint256 task_id_gen = uint256(keccak256(abi.encodePacked(msg.sender)));

        bytes32 hashed = _getHashValue(msg.sender, _task_msg);
        bytes32 SignedMessageGen = hashed.toEthSignedMessageHash();
        emit SignedMessageGenerated(msg.sender, SignedMessageGen);

        TaskDetails memory new_task = TaskDetails(
            msg.sender,
            task_id_gen,
            _task_msg,
            block.timestamp,
            _task_completed_date,
            TASK_STATUS.PENDING,
            SignedMessageGen
        );

        TasksOwnershipList[new_task.task_owner].push(new_task);
        TaskIdActivate[task_id_gen] = true;

        emit TaskCreated(new_task.task_owner, new_task.task_id);

        created = true;
    }

    function _FindTaskFromTaskOwnershipList(uint256 _task_id_for_looking) internal view returns (uint256) {
        require(_task_id_for_looking < TasksOwnershipList[msg.sender].length, "invalid task id");

        for (uint256 j = 0; j < TasksOwnershipList[msg.sender].length; j++) {
            if (TasksOwnershipList[msg.sender][j].task_id == _task_id_for_looking) return j;
        }
        revert("Not found");
    }

    /**
     * NOTE: v, r, s will fetch via ethers js
     */
    function removeTask(uint256 _task_id_for_remove, uint8 _v, bytes32 _r, bytes32 _s)
        external
        onlyTaskOwner(_task_id_for_remove, _v, _r, _s)
        returns (bool removed)
    {
        require(TaskIdActivate[_task_id_for_remove], "Task has already canceled");
        TaskDetails memory removing_task = IdOfTasks[_task_id_for_remove];
        require(removing_task.task_status != TASK_STATUS.CANCELED, "task has already canceled");

        removing_task.task_status = TASK_STATUS.CANCELED;

        uint256 task_index = _FindTaskFromTaskOwnershipList(_task_id_for_remove);
        TasksOwnershipList[msg.sender][task_index] = TasksOwnershipList[msg.sender][TasksOwnershipList[msg.sender].length - 1];
        TasksOwnershipList[msg.sender].pop();

        emit TaskRemoved(removing_task.task_owner, removing_task.task_id);
        removed = true;
    }


    /**
     * NOTE: v, r, s will fetch via ethers js
     */
    /**
     * NOTE: for passing value input if you don't want to update, pass zero value if that type
     */
    function updateTask(
        string memory _new_msg,
        uint256 _new_time,
        uint256 _task_id_for_update,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyTaskOwner(_task_id_for_update, _v, _r, _s) returns (bool updated) {

        TaskDetails memory updating_task = IdOfTasks[_task_id_for_update];
        uint256 task_idx = _FindTaskFromTaskOwnershipList(_task_id_for_update);

        require(!(updating_task.task_message.equal(_new_msg)), "message not new");
        require(_new_time == updating_task.task_complete_period, "complete timestamp is not new");
        require(_new_time != block.timestamp || _new_time > block.timestamp, "new time is not for future");

        if (!(_new_msg.equal(""))) {
            updating_task.task_message = _new_msg;
            TasksOwnershipList[msg.sender][task_idx].task_message = _new_msg;
            updated = true;
        } else if (!(_new_time != 0 && _new_time == block.timestamp)) {
            updating_task.task_complete_period = _new_time;
            TasksOwnershipList[msg.sender][task_idx].task_complete_period = _new_time;
            updated = true;
        } else if (!(_new_msg.equal("")) && !(_new_time != 0 && _new_time == block.timestamp)) {
            updating_task.task_message = _new_msg;
            TasksOwnershipList[msg.sender][task_idx].task_message = _new_msg;
            updating_task.task_complete_period = _new_time;
            TasksOwnershipList[msg.sender][task_idx].task_complete_period = _new_time;
            updated = true;
        }

        updated = false;
        revert("There is no new value for update");
    }



    // function CompleteTask(uint _task_id_for_complete, uint8 _v, bytes32 _r, bytes32 _s) external onlyTaskOwner(_task_id_for_complete, _v, _r,) returns(bool completed) {
    //     require(TaskIdActivate[_task_id_for_complete] == true, "Task has already canceled");

    // }



    function _GetTaskCompletedReward(address _to, uint256 _amount)
        internal
        onlyOwner
        nonReentrant
        returns (bool rewarded)
    {
        require(_to != address(0) && _amount > 0, "invalid inputs");
        TaskOwnerBudget[msg.sender] = TaskOwnerBudget[msg.sender].add(CONST_REWARD_AMOUNT);

        bool success = token.transferFrom(OWNER, _to, _amount);
        require(success, "Transaction failed or occured to some tx problems");
        rewarded = success;
    }
}

contract GenerateRandomness {}
