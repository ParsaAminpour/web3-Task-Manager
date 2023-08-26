from brownie import GetRand, accounts, config, network, Contract
from rich.console import Console
from datetime import datetime as dt
from rich import print
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

    random_cont = await GetRand.deploy(
        config['networks'][network.show_active()]['vrf_coordinator'],
        config['networks'][network.show_active()]['link'],
        config['networks'][network.show_active()]['key_hash'],
        0.2 * 10 ** 18, {{'from':acc}})
    
    console.log(f'[bold green] \
                The contract account address is {random_cont.address}[/bold green]')

    random_cont.getRandomness({'from':acc})
    print(f'[bold green] -- {random_cont.get_random_number()} -- is the random number fetched')


