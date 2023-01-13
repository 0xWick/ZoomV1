// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// * For interacting with ERC-20 Contract of the Token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    // * Connect with token Address
    address public tokenAddress;

    constructor(address _token) ERC20("ZoomV1", "ZOOM") {
        require(_token != address(0), "Invalid Token Address");
        tokenAddress = _token;
    }

    // * Providing Liquidity to the Pool
    function addLiquidity(
        uint256 _tokenAmount
    ) public payable returns (uint256) {
        // * For Pool Initialization Only
        if (getReserve() == 0) {
            // Get Token IERC-20 Instance
            IERC20 token = IERC20(tokenAddress);
            // Use "transferFrom" to move the tokens from sender to the pool(this contract)
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            // * LP TOKENS
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            uint256 EthReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();

            // Liquidity Ratio
            uint256 tokenAmount = (msg.value * tokenReserve) / EthReserve;

            require(_tokenAmount >= tokenAmount, " Insufficient token Amount");

            // Get Token IERC-20 Instance
            IERC20 token = IERC20(tokenAddress);
            // Use "transferFrom" to move the tokens from sender to the pool(this contract)
            token.transferFrom(msg.sender, address(this), tokenAmount);

            // * LP TOKENS

            uint256 liquidity = (totalSupply() * msg.value) / EthReserve;

            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    // * Removing Liquidity From the pool
    function removeLiquidity(
        uint256 _amount
    ) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");

        // Get User share from the Liquidity Pool (including the fees)
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    // * Get Token Reserve of the Exchange
    function getReserve() public view returns (uint256) {
        // Get Token IERC-20 Instance
        IERC20 token = IERC20(tokenAddress);

        // Get the ERC-20 token balance of current pool (aka Reserve)
        return token.balanceOf(address(this));
    }

    // ? Low Level Functions for Price and Amount
    // * GetPrice for Token or Ether in the Pool
    function getPrice(
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");

        return (inputReserve * 1000) / outputReserve;
    }

    // * Get Amount for Swap
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        // * Get OutPut Amount using Swap Formula

        // ? Old Formula without LP tokens
        // uint256 outputAmount = (inputAmount * outputReserve) / (inputAmount + inputReserve);
        // return outputAmount;

        // ? Formula With LP Tokens

        uint256 inputAmountWithFee = inputAmount * 99; // 1% Fee per Swap

        uint256 numerator = inputAmountWithFee * outputReserve;

        uint256 denominator = (inputAmountWithFee * 100) + inputReserve;

        return numerator / denominator;
    }

    // ? High Level Functions for getting Swap Amount
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ethSold is too small");

        uint256 tokenReserve = getReserve();

        uint256 tokenAmount = getAmount(
            _ethSold,
            address(this).balance,
            tokenReserve
        );

        return tokenAmount;
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();

        uint256 etherAmount = getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );

        return etherAmount;
    }

    // ? Swapping Functions
    function ethToTokenSwap(uint256 _minTokens) public payable {
        // Get Token Reserve
        uint256 tokenReserve = getReserve();

        // Get Amount of Tokens to send back to the user
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance,
            tokenReserve
        );

        // ? This value allows user to prevent extra slippage
        require(_minTokens > tokensBought, "Insufficeint Output Amount");
        // Send the Tokens to the caller
        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        // Get Token Reserve
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "insufficient output amount");

        // Get Tokens from Caller First
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );

        // Send Ether to the Caller
        payable(msg.sender).transfer(ethBought);
    }
}
