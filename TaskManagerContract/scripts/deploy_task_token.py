from brownie import GetRandom, accounts, config, network, TaskToken
from rich.console import Console
from datetime import datetime as dt
console = Console()

def main():
    token = TaskToken.deploy({'from' : accounts[0]})
    console.log(token.address)


# def main():
#     global wallet_addr
#     if network.show_active() != 'sepolia2':
#         log.exception('Netowrk is not on Sepolia')

#     wallet_addr = config['wallets']['from_key']
#     if not wallet_addr == '':
#         account = accounts.add(wallet_addr)
#     else: account = accounts[0]
#     GetRandom.deploy({'from' : account})

# if __name__ == '__main__':
#     main()