const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
    const task = "test_task";

    const TaskContract = await hre.ethers.getContractFactory("Task");
    const taskContract = await TaskContract.deploy(task);

    await taskContract.deployed();
    const [owner, other] = await hre.ethers.getSigners();
    console.log(`Task contract with address ${taskContract.address} was deployed`);
    console.log(`and the contract balance is:\t${await hre.ethers.provider.getBalance(taskContract.address)}`)
    console.log("the sender ballance is:", 
                await hre.ethers.   provider.getBalance(owner.address))
}

main().catch((error) => {
    console.error(error);
    process.exitCode=1;
})