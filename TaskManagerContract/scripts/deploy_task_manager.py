from brownie import accounts, config, network, TaskManager
from rich.console import Console
from datetime import datetime as dt
from rich import print
import asyncio
import logging, sys
console = Console()

def get_acc():
    if network.show_active() == 'development':
        acc = accounts[0]
        console.log(f'[bold yellow]\
                     accounts manager is on {acc.address} in ganache[/bold yellow]')
    
    if network.show_active() == 'sepolia2':
        acc = accounts.add(config['wallets']['from_key'])
        console.log(f'[bold yellow]\
                    account manager is on {acc.address} in Sepolia [/bold yellow]')
        
async def deploy_contract():
    acc = get_acc()

    task_contract = await TaskManager.deploy(
        'Task Test Title', {'from':acc}
    )
    console.log(f'Task is deployed at {task_contract.address}')

    asyncio.sleep(3)

    # created task
    task = await task_contract.CreateTask(
        'Test Task Message', 10800, {'from':acc})
    sys.stdout.write(f'A task created with these informations:\n')

    for sub in list(task):
        print(f'[bold green]{sub}[/bold green]')

    try:
        result = await approve_for_spending(task_contract=task_contract)
        if result: raise ValueError
        console.log('And the address caller approved for spend 10 Task Token')
    except ValueError:
        console.log(f'[bold red]Approved is not happened[/bold red]')


async def approve_for_spending(task_contract) -> bool:
    approved = await task_contract.approve(
        accounts[0], 10, {'from':accounts[0]}
    )
    return approved

    
def main():
    deploy_contract()
    