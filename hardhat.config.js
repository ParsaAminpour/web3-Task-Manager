const { task } = require("hardhat/config");

require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

const ALCHEMY_API_KEY = "AxTP4jd8-4x-SGX209UgA8H-7izaSklo";

const GOERLI_PRIVATE_KEY = "e7585b49e5e13361829100ce05dd432cc8e998ed359bf5263a6710d0bdb7620d"
module.exports = {
  solidity: "0.8.9",  
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/AxTP4jd8-4x-SGX209UgA8H-7izaSklo`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  }
};

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(`%c${account.address}`, `color:green`);
  }
});