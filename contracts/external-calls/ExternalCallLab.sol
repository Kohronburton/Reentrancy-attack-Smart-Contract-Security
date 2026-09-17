// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract RevertingRecipient {
    receive() external payable {
        revert("reject payment");
    }
}

contract VulnerableUncheckedPayout {
    mapping(address => bool) public paid;

    receive() external payable {}

    // Vulnerability: failed low-level calls are ignored, corrupting business state.
    function pay(address payable recipient, uint256 amount) external {
        recipient.call{value: amount}("");
        paid[recipient] = true;
    }
}

contract SecureCheckedPayout {
    mapping(address => bool) public paid;

    receive() external payable {}

    function pay(address payable recipient, uint256 amount) external {
        require(recipient != address(0), "zero recipient");
        require(address(this).balance >= amount, "insufficient funds");

        // Effects before interaction. A failed transfer reverts this state change atomically.
        paid[recipient] = true;

        (bool ok, ) = recipient.call{value: amount}("");
        require(ok, "payment failed");
    }
}
