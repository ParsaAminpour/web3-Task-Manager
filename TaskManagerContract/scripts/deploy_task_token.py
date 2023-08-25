from brownie import accounts, config, network, TaskToken
from rich.console import Console
from datetime import datetime as dt
console = Console()

def main():
    token = TaskToken.deploy({'from' : accounts[0]})
    console.log(token.address)