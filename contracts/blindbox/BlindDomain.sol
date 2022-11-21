// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract BlindDomain {
    enum AssetType {
        ETH,
        ERC20,
        ERC1155,
        ERC721,
        ERC721Deprecated,
        ERC721COPY
    }

    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct BlindKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint256 salt;
        Asset[] sellAssets;
        Asset buyAsset;
    }

    struct BlindBox {
        BlindKey key;
        uint256 opening;
        bool repeat;
        uint256 startTime;
        uint256 endTime;
        uint256 buying;
        uint256[] assetAmounts;
        uint256 sellerFee;
        string[] uris;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
