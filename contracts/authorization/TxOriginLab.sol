// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VulnerableTxOriginVault {
    address public immutable owner;

    constructor() payable {
        owner = msg.sender;
    }

    // Vulnerability: an intermediate phishing contract can satisfy tx.origin == owner.
    function withdrawAll() external {
        require(tx.origin == owner, "not owner");
        (bool ok, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}

contract TxOriginPhisher {
    function phish(VulnerableTxOriginVault vault) external {
        vault.withdrawAll();
    }

    receive() external payable {}
}

contract SecureAuthorizationVault is Ownable {
    constructor(address initialOwner) payable Ownable(initialOwner) {}

    function withdrawAll(address payable recipient) external onlyOwner {
        require(recipient != address(0), "zero recipient");
        (bool ok, ) = recipient.call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}
