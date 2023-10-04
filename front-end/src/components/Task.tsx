import { useState, useReducer } from 'react'
import "../css/Task.css"

export interface Task {
    task_primary_id: string;
    task_message: string;
    task_completed_date: number; // in timestamp
    task_status: boolean;
    // other attrs will define on-chain
}
export enum ACTION {
    CREATE, COMPLETE, REMOVE, EDIT, CLEAR
}
export type ActionType = {
    type: ACTION;
    data: Task | string
}

export const TaskReducer = (state: Task[] , action: ActionType): any => {
    switch(action.type) {
        case ACTION.CREATE:
            return [...state, action?.data];

        case ACTION.COMPLETE:
            state.map(task => {
                if (task == action.data) task.task_status = true;
            });
            return state;    

        case ACTION.REMOVE:
            state.filter(task => {
                task != action.data;
            })
            return [action?.data]
        
        case ACTION.CLEAR:
            return [action.data];

        default:
            throw new Error("An error occured");
    }
}

export const Task = ():React.ReactNode => {

    const init_task_val:Task[] = [{
        task_primary_id: "",
        task_message: "primary task",
        task_completed_date: new Date().getTime(),
        task_status: false,
    }]

    const [state, dispatch] = useReducer(TaskReducer, init_task_val);
    const [new_task, setNewTask] = useState("");

    const AddNewTask = () => {
        dispatch({
            type: ACTION.CREATE,
            data: {
                task_message: new_task,
                task_completed_date: new Date().getTime() + 1000,
                task_primary_id: crypto.randomUUID(),
                task_status: false,
                }   
        })
        setNewTask("");
    }

    return (
      <>
        <div className="task-input">
            <input type="text" placeholder="Add a new task..." 
                value={new_task} onChange={(e) => setNewTask(e.target.value)}/>

            <button className="add" onClick={AddNewTask}>
                Add
            </button>
        </div>

        <div className="clear-buttons">
            <button className="clear-all" onClick={() => dispatch({
                type: ACTION.CLEAR,
                data: init_task_val[0]  
            })}>
                Clear All
            </button>

            <button className="clear-completed">Clear Completed</button> 
        </div>


        <ul className="task-list">
            {state.map((task:Task) => (
            <li>
              <div className="task">
                <span key={task.task_primary_id}>{task.task_message}</span>

                <div className="buttons">

                    <button className="remove" 
                        onClick={() => dispatch({type: ACTION.REMOVE, data: task})}> 
                    Remove
                  </button>
                  
                  <button className="edit"
                        onClick={() => dispatch({type:ACTION.COMPLETE, data: task})}>
                    Complete
                </button>

                </div>
              </div>
            </li>
            ))}
        </ul>
      </>
    )
}


export default Task