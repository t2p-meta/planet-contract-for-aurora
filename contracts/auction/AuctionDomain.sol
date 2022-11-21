// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import '../exchange/ExchangeDomain.sol';

contract AuctionDomain is ExchangeDomain {
    struct AuctionOrder {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        uint256 endTime;
        uint256 expiredTime;
        uint256 encourage; // Encourage non buyers
        /* fee for selling */
        uint256 sellerFee;
    }
}
