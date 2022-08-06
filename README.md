# Interacting with Hardhat Project

This project demonstrates guide of Hardhat interaction. 
This project is **(NOT NOW)** a hardhat project with reactjs as front-end 
but it's NOT already added in here

###H3 for just running smart contract use:
```shell
npm cache remove --force
npm install
npm install @openzeppelin/contracts
npx hardhat compile
GAS_REPORT=true npx hardhat test
npx hardhat node -> 'for indicating accounts'
npx hardhat run scripts/<deploy_js_file>.js -> 'for deploying project'
```
