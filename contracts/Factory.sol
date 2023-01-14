// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Exchange.sol";


contract Factory {
    mapping (address => address) public tokenToExchange;

    

    // * Create an Exchange
    function createExchange(address _tokenAddress) public returns(address) {

        // * Input Validation
        require(_tokenAddress != address(0), "Invalid Token Address");

        // * Check if Exchange Already Exists
        require(tokenToExchange[_tokenAddress] == address(0), "Exchange Already Exists");

        // * Create new Exchange
        // ? This instantiation is similar to instantiation of
        // ? classes in OOP languages, however, in Solidity, 
        // ? the new operator will in fact deploy a contract.
        Exchange exchange = new Exchange(_tokenAddress);

        // * Add Exchange Address to the Mapping
        tokenToExchange[_tokenAddress] = address(exchange);

        // * Return Newly Created Exchange's Address
        return address(exchange);
    }


    // ? Interfaces don’t allow to access state variables and
    // ? this is why we’ve implemented the getExchange function
    function getExchange(address _tokenAddress) public view returns(address) {
        return tokenToExchange[_tokenAddress];
    }
}