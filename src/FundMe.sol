// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // constant doesn't use storage so takes less gas
    uint256 public constant MINIMUM_USD = 50e18;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent
        // 1. How do we send Eth to this contract? (use payable tag)
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough ETH"); // 1e18 = 1ETH = 1000000000000000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;

        // https://api cant be made on all nodes for consensus

        // What is a revert?
        // Undo any actions that have been done, and send the remaining gas back
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // payable type needed to send money to or from address
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        //require(msg.sender == i_owner, "Sender is not owner!");
        _; // order of _; determines whether code the modifier is called in or the code in modifier is compiled/read first
    }

    // Automatically routed to fund if someone sends transaction without using fund
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
