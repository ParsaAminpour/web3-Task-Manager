// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Task.sol";

contract TaskFactory {    
    Task[] private tasks_list;
    string public task_detail;
   
    event failed_task_creating(string indexed fallback_msg);
    event task_created(string indexed result);
    event task_deleted(string indexed task_info_, uint indexed task_index_);
    function create_task(string memory task_info_) public returns(Task task_return_){
        try new Task(task_info_) {
            emit task_created("Task created successfully");
            Task task_contract = new Task(task_info_);
            task_return_ = task_contract;

        } catch Error(string memory fallback_){
            emit failed_task_creating(fallback_);
        }
    }
    function assign_created_contract(string memory your_task_info_) public returns(bool success_) {
        uint task_length_before_creating = tasks_list.length;
        Task task = create_task(your_task_info_);
        tasks_list.push(task);
        require(task_length_before_creating <= tasks_list.length, "Somethign went wrong in task_list length");
        success_ = true;
    }

    function deleting_created_task(uint index_) public {
        uint len = tasks_list.length;
        require(len >= index_, "index is invalid");
        
        delete tasks_list[index_];
        
        for(uint i=len; i<len-1; i++) {
            tasks_list[i] = tasks_list[i-1];
        }
        tasks_list.pop();
    }
}