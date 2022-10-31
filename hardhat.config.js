/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  networks: {
    hardhat: {
      mining: {
        auto: false,
        interval: 1000
      }
    },
    sepolia: {
      url: process.env.SEPOLIA_REMOTE_HTTP,
      accounts: [
        process.env.SEPOLIA_DEPLOYER_KEY
      ]
    },
    goerli: {
      url: process.env.GOERLI_REMOTE_HTTP,
      accounts: [
        process.env.GOERLI_DEPLOYER_KEY
      ]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN_KEY
  },
  solidity: {
    compilers: [
      {
        version: "0.8.9",
      }
    ],
  }
};
