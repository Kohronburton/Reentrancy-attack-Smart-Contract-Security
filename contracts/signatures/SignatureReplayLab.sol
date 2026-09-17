// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract VulnerableSignedPayout {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable signer;

    constructor(address authorizedSigner) payable {
        signer = authorizedSigner;
    }

    // Vulnerability: the same valid signature can be replayed indefinitely while funds remain.
    function claim(uint256 amount, bytes calldata signature) external {
        bytes32 digest = keccak256(abi.encode(msg.sender, amount));
        address recovered = digest.toEthSignedMessageHash().recover(signature);
        require(recovered == signer, "bad signature");

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");
    }
}

contract SecureSignedPayout {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable signer;
    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    constructor(address authorizedSigner) payable {
        require(authorizedSigner != address(0), "zero signer");
        signer = authorizedSigner;
    }

    function claim(uint256 amount, uint256 nonce, bytes calldata signature) external {
        require(!nonceUsed[msg.sender][nonce], "nonce used");

        bytes32 digest = keccak256(
            abi.encode(address(this), block.chainid, msg.sender, amount, nonce)
        );
        address recovered = digest.toEthSignedMessageHash().recover(signature);
        require(recovered == signer, "bad signature");

        nonceUsed[msg.sender][nonce] = true;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");
    }
}
