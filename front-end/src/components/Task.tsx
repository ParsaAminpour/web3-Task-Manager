import { useState, useReducer } from 'react'
import "../css/Task.css"
import {html} from "./html_base";

export type Task = {
    task_primary_id: string;
    task_message: string;
    task_completed_date: number; // in timestamp
    task_status: boolean;
    // other attrs will define on-chain
}
export enum ACTION {
    CREATE, COMPLETE, REMOVE
}
export type ActionType = {
    type: ACTION;
    data: Task
}
export type TaskList = {
    tasks: Task[]
}

export const TaskReducer = (state: TaskList , action: ActionType): any => {
    switch(action.type) {
        case ACTION.CREATE:
            return [...state.tasks, action.data];

        case ACTION.COMPLETE:
            state.tasks.map(task => {
                if (task == action.data) task.task_status = true;
            });
            return state.tasks;    

        case ACTION.REMOVE:
            state.tasks.filter(task => {
                task != action.data;
            })
            return state.tasks;

        default:
            throw new Error("An error occured");
    }
}

export const Task = ():React.ReactNode => {
    const init_task_val:Task[] = [{
        task_primary_id: "",
        task_message: "",
        task_completed_date: new Date().getTime(),
        task_status: false,
    }]

    const [state, dispatch] = useReducer(TaskReducer, init_task_val);

    return (
      <>
        <div className="task-input">
            <input type="text" placeholder="Add a new task..." />
            <button className="add">Add</button>
        </div>

        <div className="clear-buttons">
            <button className="clear-all">Clear All</button>
            <button className="clear-completed">Clear Completed</button> 
        </div>

        <ul className="task-list">
            <li>
              <div className="task">
                <span>Task 1</span>
                <div className="buttons">
                  <button className="remove">Remove</button>
                  <button className="edit">Edit</button>
                </div>
              </div>
            </li>
        </ul>
      </>
    )
}


export default Task