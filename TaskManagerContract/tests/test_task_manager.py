from brownie import TaskToken, TaskManager, accounts, config, network
from rich.console import Console
import logging, sys
import pytest
console = Console()

@pytest.fixture
def init_token(TaskToken, accounts):
    return TaskToken.deploy({'from' : accounts[0]})


@pytest.fixture(scope='module')
def Alice():
    return accounts[0]

@pytest.fixture(scope='module')
def Bob():
    return accounts[1]
