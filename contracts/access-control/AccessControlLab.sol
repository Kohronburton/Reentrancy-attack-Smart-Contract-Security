// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VulnerableTreasury {
    receive() external payable {}

    // Vulnerability: anyone can sweep the full treasury.
    function sweep(address payable recipient) external {
        (bool ok, ) = recipient.call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}

contract SecureTreasury is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    receive() external payable {}

    function sweep(address payable recipient) external onlyOwner {
        require(recipient != address(0), "zero recipient");
        (bool ok, ) = recipient.call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}
