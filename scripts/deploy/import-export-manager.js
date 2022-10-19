const { ethers } = require("hardhat");
const { Smartcontract } = require("sds-cli");

(async function main() {
  const name          = "ImportExportManager";
  const group         = "ImportExport";

  // We get the contract to deploy
  const Lord       = await ethers.getContractFactory(name);
  let deployer        = await ethers.getSigner();
  let smartcontract   = new Smartcontract(group, name);

  // constructor argument
  let constructor = [];

  await smartcontract
    .deployInHardhat(deployer, Lord, constructor)
    .catch(console.error);

  console.log(`\n\Import Export manager Deployment Finished!\n\n`);
})()
