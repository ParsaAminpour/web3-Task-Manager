from brownie import GetRandom, accounts, config, network, TaskToken
from rich.console import Console
from rich import print
from datetime import datetime as dt
console = Console()

def getAccount():
    global account
    try:
        if network.show_active() == 'developmnet':
            account = accounts[0]
            return account
    
        if network.show_active() == 'sepolia2':
            accounts.add(
                config.get('wallets','').get('from_key', ''))
            return account

    except: return False
    

def deploy_token():
    acc = getAccount()

    if acc is not False:
        token = TaskToken.deploy({
            'frpm' : acc})
    print(f"[bold green] \
            Contract deployed at {token.address}\n \
            and deployer is : acc")
    

def main():
    deploy_token()


