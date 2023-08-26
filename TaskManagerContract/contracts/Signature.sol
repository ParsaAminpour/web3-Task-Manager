// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import  "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import  "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Signature {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    error ECDSAInvalidSignature();

    error ECDSAInvalidSignatureLength(uint256 length);

    error ECDSAInvalidSignatureS(bytes32 s);


    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}



library MessageHashUtils {

    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        // memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) -> length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c -> length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32 digest) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}


/** NOTE: this contract will remove in the end of the project  */
contract TestManager {
    using MessageHashUtils for bytes32;
    // using SignatureChecker for bytes32;
    // using ECDSA for bytes32;

    string public message_interface;

    constructor(string memory _message) {
        message_interface = _message;
    }

    function hashed() public view returns(bytes32) {
        return keccak256(abi.encodePacked(message_interface, msg.sender));
    }

    function getSignedMessageg(bytes32 HashedMessage) public pure returns(bytes32) {
        return HashedMessage.toEthSignedMessageHash();
    }

    function verification(bytes32 hash_for_verify, bytes32 sign_for_verify) public pure returns(address) {
    }

    function bytes32ToBytes(bytes32 input) public pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
          mstore(add(b, 32), input) // set the bytes data
        }
        return b;
    }
}