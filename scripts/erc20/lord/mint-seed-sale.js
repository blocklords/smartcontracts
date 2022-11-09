const { ethers } = require("hardhat");

(async function main() {
    let deployer        = await ethers.getSigner();
    let name = "Lord";

    const Lord       = await hre.ethers.getContractAt(name, "0xBD29CE50f23e9dcFCfc7c85e3BC0231ab68cbC37");

    // const mintToken = await myContract.mint(1, { value: ethers.utils.parseEther("0.3") });
    let mintTx = await Lord.mintSeedSale(deployer.address)
    console.log('Minted successfully. Waiting for transaction confirmation....')
    console.log(mintTx)
    await mintTx.wait();

    console.log(`\n\nLORD Mint confirmed!\n\n`);
})()
