// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import '../lib/interface/IERC721.sol';
import '../lib/math/SafeMath.sol';
import '../lib/contracts/ERC721Base.sol';
import '../lib/utils/Ownable.sol';

/**
 * @title Full ERC721 Token with support for tokenURIPrefix
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract Finger721 is Ownable, IERC721, ERC721Base {
    using SafeMath for uint256;

    address public minter;
    address payable public beneficiary;

    constructor(
        string memory name,
        string memory symbol,
        address _minter,
        address payable _beneficiary,
        string memory contractURI,
        string memory tokenURIPrefix
    ) ERC721Base(name, symbol, contractURI, tokenURIPrefix) {
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
        minter = _minter;
        beneficiary = _beneficiary;
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, 'incorrect minter');
        _;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) external onlyMinter {
        Fee[] memory fees = new Fee[](1);
        fees[0].recipient = beneficiary;
        fees[0].value = 500;

        _mint(to, tokenId, fees);
        _setTokenURI(tokenId, uri);
    }
}
