// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import './BlindDomain.sol';
import '../exchange/OwnableOperatorRole.sol';

contract BlindState is OwnableOperatorRole {
    // keccak256(BlindKey) => completed
    mapping(bytes32 => uint256[]) public completed;

    function getCompleted(BlindDomain.BlindKey calldata key) external view returns (uint256[] memory) {
        return completed[getCompletedKey(key)];
    }

    function setCompleted(BlindDomain.BlindKey calldata key, uint256 index) external onlyOperator {
        bytes32 _key = getCompletedKey(key);
        if (completed[_key].length == 0) {
            completed[_key] = new uint256[](key.sellAssets.length);
        }
        completed[_key][index] = completed[_key][index] + 1;
    }

    function getCompletedKey(BlindDomain.BlindKey memory key) public pure returns (bytes32) {
        return keccak256(abi.encode(key));
    }
}
