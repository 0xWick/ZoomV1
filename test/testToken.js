   
const { ethers } = require("hardhat")
const {expect} = require("chai");

describe("Token", () => {

    // Test InitialSupply Mint
    it("Should mint intial supply to the deployer", async () => {

        const [deployer] = await ethers.getSigners();

        const ContractFactory = await ethers.getContractFactory("Token")

        const Contract = await ContractFactory.deploy("Kutti", "KT", ethers.utils.parseEther("100"))

        const deployerBalance = await Contract.balanceOf(deployer.address)

        expect(await Contract.totalSupply()).to.equal(deployerBalance)
    
    })
})