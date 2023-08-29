// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
import { Signature } from "./Signature.sol";
import "./TaskToken.sol";

contract TaskManager is Ownable, ReentrancyGuard, TaskToken {
    // using SignatureChecker for bytes32;
    using Signature for bytes32;
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

    function _getHashValue(address _owner, uint _tsk_id) internal pure returns (bytes32 hashed) {
        return keccak256(abi.encodePacked(_tsk_id, _owner));
    }

    function _split(bytes memory _metamask_signature) 
    internal 
    pure 
    returns(bytes32 r, bytes32 s, uint8 v) {
        // require(!(_metamask_signature == bytes(0)), "invalid data inserted");

        assembly {
            r := mload(add(_metamask_signature, 0x20))
            s := mload(add(_metamask_signature, 0x40))
            v := byte(0, mload(add(_metamask_signature, 0x60)))
        }
    }


    modifier onlyTaskOwner(uint256 _task_id, bytes memory _metamask_sign) {
        require(IdOfTasks[_task_id].task_owner == msg.sender, "You are NOT the task owner");

        // Check signer verification
        TaskDetails memory task_to_verify = IdOfTasks[_task_id]; // The task belongs to msg.sender

        bytes32 hashed_message_for_verify = _getHashValue(msg.sender, task_to_verify.task_id);
        bytes32 stored_signed_message_for_verify = task_to_verify.sign_msg;
        require(SignedMessageToOwner[stored_signed_message_for_verify] == msg.sender, "We have not your task sign");

        address _recovered = stored_signed_message_for_verify.recover(_metamask_sign);

        if (_recovered == msg.sender) {
            emit SignedMessageVerified(msg.sender, stored_signed_message_for_verify);
        } else {
            blackList.push(msg.sender);
            revert("You are Not owner");
        }
        _;
    }


    function CreateTask(string memory _task_msg, uint256 _task_completed_date) external returns (bool created) {
        require(!(_task_msg.equal("") && _task_completed_date == block.timestamp), "invalid values inserted");
        require(!(TaskMessageUsed[_task_msg]), "This message of task has already used");

        uint256 task_id_gen = uint256(keccak256(abi.encodePacked(msg.sender)));

        bytes32 hashed = _getHashValue(msg.sender, task_id_gen);
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
     * NOTE: MetaMask message signature will fetch via ethers js
     */
    function removeTask(uint256 _task_id_for_remove, bytes memory _metamask_sign_for_verifiy)
        external
        onlyTaskOwner(_task_id_for_remove, _metamask_sign_for_verifiy)
        returns (bool removed)
    {
        require(TaskIdActivate[_task_id_for_remove], "Task has already canceled");
        TaskDetails storage removing_task = IdOfTasks[_task_id_for_remove];
        require(removing_task.task_status != TASK_STATUS.CANCELED, "task has already canceled");

        /** MODIFICATIONS (Just for vitals data) */
        removing_task.task_status = TASK_STATUS.CANCELED;

        TaskIdActivate[removing_task.task_id] = false;

        uint256 task_index = _FindTaskFromTaskOwnershipList(_task_id_for_remove);
        // modify(delete) the task belong to list of msg.sender's tasks 
        TasksOwnershipList[msg.sender][task_index] = TasksOwnershipList[msg.sender][TasksOwnershipList[msg.sender].length - 1];
        TasksOwnershipList[msg.sender].pop();

        emit TaskRemoved(removing_task.task_owner, removing_task.task_id);
        removed = true;
    }


    /**
     * NOTE: Update function will also be used at remove and complete functions.
     */
    /**
     * NOTE: for passing value input if you don't want to update, pass zero value if that type
     */
     /* 0 -> update task details  |  1 -> complete task  |  2 -> remove task */
    function updateTask(
        string memory _new_msg,
        uint _new_time,
        uint _task_id_for_update,
        bytes memory _metamask_sign_for_verifiy
    ) external onlyTaskOwner(_task_id_for_update, _metamask_sign_for_verifiy) 
    returns (bool updated) {

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


    function CompleteTask(uint _task_id_for_complete, bytes memory _metamask_task_signature) 
    external 
    onlyTaskOwner(_task_id_for_complete,_metamask_task_signature) 
    nonReentrant
    returns(bool completed) {
        require(TaskIdActivate[_task_id_for_complete] == true, "Task has already canceled");


        bool removed = this.removeTask(_task_id_for_complete, _metamask_task_signature);
        // rewarding to the owner
        bool rewarded = _GetTaskCompletedReward(msg.sender, 10);
        require(removed && rewarded, "Something went wrong in reward function");
        emit OwnerRewarded(msg.sender, _task_id_for_complete, 10);
        completed = rewarded;
    }


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
