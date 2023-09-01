// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaskManager {

  struct Task {
    string title;
    string description;
    bool completed; 
    uint256 createdAt;
  }

  event TaskCreated(uint256 id, string title, string description, bool completed, uint256 createdAt);

  event TaskCompleted(uint256 id, bool completed);

  function createTask(string calldata _title, string calldata _description) external returns (uint256);
  
  function getTask(uint256 _taskId) external view returns (uint id, string memory title, string memory description, bool completed, uint256 createdAt);

  function completeTask(uint256 _taskId) external;

  function deleteTask(uint256 _taskId) external;
   
  function updateTask(uint256 _taskId, string calldata _title, string calldata _description) external;

  function getAllTasks() external view returns (Task[] memory);

  function getCompletedTasksCount() external view returns (uint256); 

}
