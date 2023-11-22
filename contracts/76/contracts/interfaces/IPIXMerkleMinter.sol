// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IPIX.sol";

/**
* @title Interface defining the PIX merkle minter
*/
interface IPIXMerkleMinter {
    /**
    * @notice Mints a pix and sends it to a new owner
    * @param destination Address of new owner
    * @param oldOwner Address of previous owner
    * @param info Info regarding the pix
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    * @return The token Id
    */
    function mintToNewOwner(
        address destination,
        address oldOwner,
        IPIX.PIXInfo memory info,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProofs
    ) external returns (uint256);
    /**
    * @notice Mints multiple PIX and sends them to a new owner
    * @param destination Address of new owner
    * @param oldOwner Address of previous owner
    * @param info Array info structs regarding the pix
    * @param merkleRoot Array containing the merkle roots
    * @param merkleProofs Arrays containing the corresponding merkle proofs
    * @return The token Ids of minted PIX
    */
    function mintToNewOwnerInBatch(
        address destination,
        address oldOwner,
        IPIX.PIXInfo[] memory info,
        bytes32[] calldata merkleRoot,
        bytes32[][] calldata merkleProofs
    ) external returns (uint256[] memory);
}
