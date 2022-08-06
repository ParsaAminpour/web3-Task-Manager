// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Task is Ownable{
    using Counters for uint;

    enum Status{COMPLETED,PENDING,CANCELED}
    Status public status_enum;

    struct TaskStruct{
        string task; 
        bool status; uint time; 
    }
    TaskStruct public task_struct;

    constructor(string memory _task) {
        // require(get_string_len(_task) > 0, "task detail is invalid");
        task_struct.task = _task;
        task_struct.status = false;
        status_enum = Status.PENDING; //defualt is pending
        task_struct.time = block.timestamp;
    }

    function get_string_len(string memory s) public pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            unchecked{
                b < 0x80 ? ++i
                    : b < 0xE0 ? i += 2
                        : b < 0xF0 ? i+=3
                            : b < 0xF8 ? i += 4
                                : b < 0xFC ? i+= 5
                                    : i += 6;     }
            }
        return len;
    }

    // change the task function
    function change_task_info(string memory new_task) external onlyOwner returns(string memory new_task_) {
        require(get_string_len(new_task) != uint256(0));

        task_struct.task = new_task;
        new_task_ = task_struct.task;
    }
    // change status to COMPLETED -> make task_struct.status:true
    function compelete_task() external onlyOwner returns(bool new_status_) {
        require(task_struct.status == false, "The task has already cmopleted before");
        task_struct.status = true;
        status_enum = Status.COMPLETED;
        require(new_status_ && status_enum == Status.COMPLETED, "An error occured in complete_task function");
        new_status_ = true;
    }

    function cancel_task() external onlyOwner returns(bool new_status_) {
        require(status_enum == Status.PENDING && task_struct.status == false,
            "The task has already completed or canceled before");
        
        status_enum = Status.CANCELED;
        require(status_enum == Status.CANCELED);
        new_status_ = true;
    }
    
    function status_bare_metal() public view returns(string memory status_return_) {
        status_return_ = status_enum == Status.COMPLETED  ? "completed" 
            : status_enum == Status.PENDING ? "pending"
                : "canceled";
    }   

    function task_data() public view returns(string memory task_, bool status_, uint time_) {
        task_ = task_struct.task;
        status_ = task_struct.status;
        time_ = task_struct.time;
    }

}