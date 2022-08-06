const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat"); 
const { task } = require("hardhat/config");

describe("Task", function() {
    async function deployTaskContract() {
        const [owner, other_addr] = await ethers.getSigners();
        const owner_balance = await ethers.provider.getBalance(owner.address);
        
        const TaskContract = await ethers.getContractFactory("Task");
        const task_contract = await TaskContract.deploy("mytask");
        await task_contract.deployed();
        
        const task_struct = await task_contract.task_struct(0);
        return { task, owner, other_addr, task_contract, task_struct }; 
    }

    describe("deployment", () => {
        it("task_struct_task_should_be_same", async() => {
            const { task, task_contract, task_struct } = 
                await loadFixture(deployTaskContract);
            
            let[task_, status_, time_] = task_struct(0);
            expect(task_).to.equal(task);
        })

        it("task_struct_status_should_be_false", async() => {
            const { task, owner, task_contract, task_struct } = 
                await loadFixture(deployTaskContract);
            let[task_, status_, time_] = task_struct(0);
            expect(status_).to.equal(false);
        })
        
        it("time_stamp_check", async() => {
                const { task, owner, task_contract, task_struct } = 
                    await loadFixture(deployTaskContract);
                let[task_, status_, time_] = task_struct(0);
                expect(time).to.equal(time.latest());
        })
    })
})