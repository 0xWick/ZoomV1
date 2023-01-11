   
const { ethers } = require("hardhat")
// require("@nomiclabs/hardhat-waffle");
const { expect } = require("chai");

// * Utility Functions


const toWei = (value) => ethers.utils.parseEther(value.toString());

const fromWei = (value) =>
  ethers.utils.formatEther(
    typeof value === "string" ? value : value.toString()
  );

const getBalance = ethers.provider.getBalance;

// * Exchange Contract Test
describe("Exchange", () => {

    let owner;
    let user;
    let token;
    let exchange;

    beforeEach(async () => {
        // Get Signers
        [owner, user] = await ethers.getSigners();

        // Deploy Token Contract
        const Token = await ethers.getContractFactory("Token")
        token = await Token.deploy("Galaxy", "GX", toWei(1000000))
        await token.deployed();

        // Deploy Exchange Contract
        const Exchange = await ethers.getContractFactory("Exchange");
        exchange = await Exchange.deploy(token.address);
        await exchange.deployed();
    })

    it("is Deployed", async () => {
        expect(await exchange.deployed()).to.equal(exchange);
    })
    
    describe("Add Liquidity", () => {
        it("Should add liquidity to Contract Reserve", async () => {
            
            // Approve Tokens for the contract's (transferFrom Function)
            await token.approve(exchange.address, toWei(200))

            // Add Liquidity to the Contract
            await exchange.addLiquidity(toWei(200), {value: toWei(100)});

            // Check Ether balance
            expect(await getBalance(exchange.address)).to.equal(toWei(100))            
            // Check Token Balance
            expect(await exchange.getReserve()).to.equal(toWei(200))
        })
    })

    describe("getPrice", () => {
        it("returns correct Price", async() => {

            await token.approve(exchange.address, toWei(2000));

            await exchange.addLiquidity(toWei(2000), {value: toWei(1000)});
 
            // Get Reserves
            const tokenReserve = await exchange.getReserve();
            const etherReserve = await getBalance(exchange.address);
            // Eth Per Token
            expect(await exchange.getPrice(etherReserve, tokenReserve)).to.equal(500)

            // ? Not using toWei because Division of a uint256/uint256 reduces the zeros
            // ? and its same as an integer
            
            // Token per Eth
            expect(await exchange.getPrice(tokenReserve, etherReserve)).to.equal(2000)


        })
    })

    describe("getTokenAmount", () => {
        it("returns correct Token Amount", async () => {

            // * Add Liquidity
            // Approve Tokens for the contract's (transferFrom Function)
            await token.approve(exchange.address, toWei(2000))

            // Add Liquidity to the Contract
            await exchange.addLiquidity(toWei(2000), {value: toWei(1000)});
            
            // Check Token Amount
            let tokensOut = await exchange.getTokenAmount(toWei(1));
            expect(fromWei(tokensOut)).to.equal("1.998001998001998001")            

            tokensOut = await exchange.getTokenAmount(toWei(100));
            expect(fromWei(tokensOut)).to.equal("181.818181818181818181");
      
            tokensOut = await exchange.getTokenAmount(toWei(1000));
            expect(fromWei(tokensOut)).to.equal("1000.0");

        })
    })

    describe("getEthAmount", async () => {
        it("returns correct ether amount", async () => {
          await token.approve(exchange.address, toWei(2000));
          await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
    
          let ethOut = await exchange.getEthAmount(toWei(2));
          expect(fromWei(ethOut)).to.equal("0.999000999000999");
    
          ethOut = await exchange.getEthAmount(toWei(100));
          expect(fromWei(ethOut)).to.equal("47.619047619047619047");
    
          ethOut = await exchange.getEthAmount(toWei(2000));
          expect(fromWei(ethOut)).to.equal("500.0");
        });
      });

}) 

