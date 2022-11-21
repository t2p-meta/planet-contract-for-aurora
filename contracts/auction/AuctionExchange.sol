// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import '../lib/math/SafeMath.sol';
import '../lib/interface/IERC1155.sol';
import '../lib/utils/StringLibrary.sol';
import '../lib/utils/BytesLibrary.sol';
import '../lib/contracts/ERC165.sol';
import '../exchange/OwnableOperatorRole.sol';
import '../exchange/ERC20TransferProxy.sol';
import '../exchange/TransferProxy.sol';
import './AuctionState.sol';
import '../exchange/TransferProxyForDeprecated.sol';
import './AuctionDomain.sol';

import '../lib/contracts/HasSecondarySaleFees.sol';
import '../lib/utils/Ownable.sol';

contract AuctionExchange is Ownable, AuctionDomain {
    using SafeMath for uint256;
    using UintLibrary for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    enum FeeSide {
        NONE,
        SELL,
        BUY
    }

    event Auction(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        uint256 sellValue,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 buyValue,
        address buyer,
        uint256 endTime,
        uint256 buying,
        uint256 salt
    );

    event Cancel(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 salt
    );

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    uint256 private constant UINT256_MAX = 2**256 - 1;

    address payable public beneficiary;
    address public buyerFeeSigner;

    TransferProxy public transferProxy;
    TransferProxyForDeprecated public transferProxyForDeprecated;
    ERC20TransferProxy public erc20TransferProxy;
    AuctionState public state;

    constructor(
        TransferProxy _transferProxy,
        TransferProxyForDeprecated _transferProxyForDeprecated,
        ERC20TransferProxy _erc20TransferProxy,
        AuctionState _state,
        address payable _beneficiary,
        address _buyerFeeSigner
    ) {
        transferProxy = _transferProxy;
        transferProxyForDeprecated = _transferProxyForDeprecated;
        erc20TransferProxy = _erc20TransferProxy;
        state = _state;
        beneficiary = _beneficiary;
        buyerFeeSigner = _buyerFeeSigner;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }

    function exchange(
        AuctionOrder calldata order,
        Sig calldata ownerSig,
        uint256 buying,
        Sig calldata buyerSig,
        address[] calldata recipients,
        uint256 buyerFee,
        Sig calldata buyerFeeSig,
        address buyer
    ) external payable {
        FeeSide feeSide = getFeeSide(buyer);
        require(feeSide == FeeSide.BUY || order.key.buyAsset.assetType != AssetType.ETH, 'incorrect feeSide');

        validateOrder(order, ownerSig, buying, buyer, buyerSig, recipients, buyerFee, buyerFeeSig);

        verifyOpenAndModifyOrderState(order.key);
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            validateEthTransfer(buying, buyerFee);
        }
        transferWithEncourage(order, buying, recipients, buyerFee, buyer);
        /*
        uint restValue = encourageRecipients(order, recipients, buying, buyer);
        transfer(order.key.sellAsset, order.selling, order.key.owner, buyer);
        transferWithFees(order.key.buyAsset, buying, restValue, buyer, order.key.owner, order.sellerFee, buyerFee, order.key.sellAsset);
        */
        emitAuction(order, buying, buyer);
    }

    function transferWithEncourage(
        AuctionOrder memory order,
        uint256 buying,
        address[] memory recipients,
        uint256 buyerFee,
        address buyer
    ) internal {
        uint256 restValue = encourageRecipients(order, recipients, buying, buyer);
        transfer(order.key.sellAsset, order.selling, order.key.owner, buyer);
        transferWithFees(
            order.key.buyAsset,
            buying,
            restValue,
            buyer,
            order.key.owner,
            order.sellerFee,
            buyerFee,
            order.key.sellAsset
        );
    }

    function validateOrder(
        AuctionOrder memory order,
        Sig memory ownerSig,
        uint256 buying,
        address buyer,
        Sig memory buyerSig,
        address[] memory recipients,
        uint256 buyerFee,
        Sig memory buyerFeeSig
    ) internal view {
        require(order.endTime < block.timestamp, 'incorrect timestamp');
        require(order.expiredTime > block.timestamp, 'order expired');
        require(order.buying <= buying, 'incorrect buying');

        validateOrderSig(order, ownerSig);
        validateBuyerSig(order, buying, buyer, buyerSig);
        validateBuyerFeeSig(order, buying, buyer, recipients, buyerFee, buyerFeeSig);
    }

    function encourageRecipients(
        AuctionOrder memory order,
        address[] memory recipients,
        uint256 buying,
        address buyer
    ) internal returns (uint256) {
        if (recipients.length == 0) {
            return buying;
        }
        uint256 restValue = buying;
        uint256 encourage = buying.bp(order.encourage);
        encourage = encourage.div(recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(order.key.buyAsset, encourage, buyer, recipients[i]);
            restValue = restValue.sub(encourage);
        }
        return restValue;
    }

    function validateEthTransfer(uint256 value, uint256 buyerFee) internal view {
        uint256 buyerFeeValue = value.bp(buyerFee);
        require(msg.value == value + buyerFeeValue, 'msg.value is incorrect');
    }

    function cancel(OrderKey calldata key) external {
        require(key.owner == msg.sender, 'not an owner');
        state.setCompleted(key);
        emit Cancel(
            key.sellAsset.token,
            key.sellAsset.tokenId,
            msg.sender,
            key.buyAsset.token,
            key.buyAsset.tokenId,
            key.salt
        );
    }

    function validateOrderSig(AuctionOrder memory order, Sig memory sig) internal pure {
        require(prepareMessage(order).recover(sig.v, sig.r, sig.s) == order.key.owner, 'incorrect signature');
    }

    function validateBuyerSig(
        AuctionOrder memory order,
        uint256 buying,
        address buyer,
        Sig memory sig
    ) internal pure {
        require(prepareBuyerMessage(order, buying).recover(sig.v, sig.r, sig.s) == buyer, 'incorrect buyer signature');
    }

    function validateBuyerFeeSig(
        AuctionOrder memory order,
        uint256 buying,
        address buyer,
        address[] memory recipients,
        uint256 buyerFee,
        Sig memory sig
    ) internal view {
        require(
            prepareBuyerFeeMessage(order, buying, buyer, recipients, buyerFee).recover(sig.v, sig.r, sig.s) ==
                buyerFeeSigner,
            'incorrect buyer fee signature'
        );
    }

    function prepareBuyerFeeMessage(
        AuctionOrder memory order,
        uint256 buying,
        address buyer,
        address[] memory recipients,
        uint256 fee
    ) public pure returns (string memory) {
        return keccak256(abi.encode(order, buying, buyer, recipients, fee)).toString();
    }

    function prepareMessage(AuctionOrder memory order) public pure returns (string memory) {
        return keccak256(abi.encode(order)).toString();
    }

    function prepareBuyerMessage(AuctionOrder memory order, uint256 buying) public pure returns (string memory) {
        return keccak256(abi.encode(order, buying)).toString();
    }

    function transfer(
        Asset memory asset,
        uint256 value,
        address from,
        address to
    ) internal {
        if (asset.assetType == AssetType.ETH) {
            address payable toPayable = payable(to);
            toPayable.transfer(value);
        } else if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenId == 0, 'tokenId  be 0');
            erc20TransferProxy.erc20safeTransferFrom(IERC20(asset.token), from, to, value);
        } else if (asset.assetType == AssetType.ERC721) {
            require(value == 1, 'value  be 1 for ERC-721');
            transferProxy.erc721safeTransferFrom(IERC721(asset.token), from, to, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC721Deprecated) {
            require(value == 1, 'value  be 1 for ERC-721');
            transferProxyForDeprecated.erc721TransferFrom(IERC721(asset.token), from, to, asset.tokenId);
        } else {
            transferProxy.erc1155safeTransferFrom(IERC1155(asset.token), from, to, asset.tokenId, value, '');
        }
    }

    function transferWithFees(
        Asset memory firstType,
        uint256 value,
        uint256 _restValue,
        address from,
        address to,
        uint256 sellerFee,
        uint256 buyerFee,
        Asset memory secondType
    ) internal {
        uint256 restValue = transferFeeToBeneficiary(firstType, from, value, _restValue, sellerFee, buyerFee);
        if (
            (secondType.assetType == AssetType.ERC1155 &&
                IERC1155(secondType.token).supportsInterface(_INTERFACE_ID_FEES)) ||
            ((secondType.assetType == AssetType.ERC721 || secondType.assetType == AssetType.ERC721Deprecated) &&
                IERC721(secondType.token).supportsInterface(_INTERFACE_ID_FEES))
        ) {
            HasSecondarySaleFees withFees = HasSecondarySaleFees(secondType.token);
            address payable[] memory recipients = withFees.getFeeRecipients(secondType.tokenId);
            uint256[] memory fees = withFees.getFeeBps(secondType.tokenId);
            require(fees.length == recipients.length);
            for (uint256 i = 0; i < fees.length; i++) {
                (uint256 newRestValue, uint256 current) = subFeeInBp(restValue, value, fees[i]);
                restValue = newRestValue;
                transfer(firstType, current, from, recipients[i]);
            }
        }
        address payable toPayable = payable(to);
        transfer(firstType, restValue, from, toPayable);
    }

    function transferFeeToBeneficiary(
        Asset memory asset,
        address from,
        uint256 total,
        uint256 _restValue,
        uint256 sellerFee,
        uint256 buyerFee
    ) internal returns (uint256) {
        (uint256 restValue, uint256 sellerFeeValue) = subFeeInBp(_restValue, total, sellerFee);
        uint256 buyerFeeValue = total.bp(buyerFee);
        uint256 beneficiaryFee = buyerFeeValue.add(sellerFeeValue);
        if (beneficiaryFee > 0) {
            transfer(asset, beneficiaryFee, from, beneficiary);
        }
        return restValue;
    }

    function emitAuction(
        AuctionOrder memory order,
        uint256 buying,
        address buyer
    ) internal {
        emit Auction(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            order.selling,
            order.key.owner,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId,
            order.buying,
            buyer,
            order.endTime,
            buying,
            order.key.salt
        );
    }

    function subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint256 value, uint256 fee) internal pure returns (uint256 newValue, uint256 realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function verifyOpenAndModifyOrderState(OrderKey memory key) internal {
        bool completed = state.getCompleted(key);
        require(!completed, 'order completed');
        state.setCompleted(key);
    }

    function getFeeSide(address buyer) internal view returns (FeeSide) {
        if (buyer == msg.sender) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }
}
