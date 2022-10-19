const { ethers } = require("hardhat");
const { Smartcontract } = require("sds-cli");

(async function main() {
  const name          = "Lord";
  const group         = "ERC20";
  const address = "0x05B21D0094b118d2e651C888a3C8541191bCD1e0";
  const txid = "0x0664262704bb556c34fe87b42a86c7c47348f83489ce65be60145fed4459f10c";

  // We get the contract to deploy
  let deployer        = await ethers.getSigner();
  let smartcontract   = new Smartcontract(group, name);

  await smartcontract
    .registerInHardhat(deployer, address, txid)
    .catch(console.error);

  console.log(`\n\nLORD Deployment Finished!\n\n`);
})()
