// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./PIXBaseSale.sol";
import "../interfaces/IPIXMerkleMinter.sol";
import "../libraries/DecimalMath.sol";

/**
* @title Contract to handle fixed-price sales of PIX
*/
contract PIXFixedSale is PIXBaseSale, EIP712Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DecimalMath for uint256;

    /**
    * @notice Event emitted upon requesting a sale
    * @param seller The address of the seller
    * @param saleId The id of the sale
    * @param nftToken The address of the token
    * @param tokenIds The tokenId's of the tokens
    * @param price The suggested price
    */
    event SaleRequested(
        address indexed seller,
        uint256 indexed saleId,
        address nftToken,
        uint256[] tokenIds,
        uint256 price
    );

    /**
    * @notice Event emitted when a sale is updated
    * @param saleId The id of the sale
    * @param newPrice The new price of the sale
    */
    event SaleUpdated(uint256 indexed saleId, uint256 newPrice);

    /**
    * @notice Event emitted when a sale is completed using a signature
    * @param seller Address of seller
    * @param buyer Address of buyer
    * @param nftToken Address of token being sold
    * @param tokenId The id of the token being sold
    * @param price The sale price
    */
    event PurchasedWithSignature(
        address indexed seller,
        address indexed buyer,
        address nftToken,
        uint256 tokenId,
        uint256 price
    );

    /**
    * @notice Struct containing information about a fixed sale
    * @param seller Seller address
    * @param nftToken NFT token address
    * @param price Fixed sale price
    * @param tokenIds List of tokenIds
    */
    struct FixedSaleInfo {
        address seller; // Seller address
        address nftToken; // NFT token address
        uint256 price; // Fixed sale price
        uint256[] tokenIds; // List of tokenIds
    }

    mapping(uint256 => FixedSaleInfo) public saleInfo;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public nonces;

    bytes32 private constant BID_MESSAGE =
        keccak256(
            "BidMessage(address bidder,uint256 price,address nftToken,uint256 tokenId,uint256 nonce)"
        );

    address public burnHolder;

    mapping(address => mapping(uint256 => uint256)) public noncesForSale;
    bytes32 private constant OFFER_MESSAGE =
        keccak256("OfferMessage(address bidder,uint256 price,uint256 saleId,uint256 nonce)");

    bytes32 private constant BID_MESSAGE_WITH_HASH =
        keccak256(
            "BidMessageWithHash(address bidder,uint256 price,address seller,PIXInfo info)PIXInfo(uint256 pixId,uint8 category,uint8 size)"
        );

    bytes32 private constant PIXINFO_TYPEHASH =
        keccak256("PIXInfo(uint256 pixId,uint8 category,uint8 size)");

    bytes32 private constant BID_MESSAGE_WITH_HASH_V1 =
        keccak256("BidMessageWithHash(address bidder,uint256 price,address seller,PIXInfo info)");

    IPIXMerkleMinter public pixMerkleMinter;

    mapping(uint256 => uint256) public expirationTimes; // disabled

    /**
    * @notice The intializer for this contract
    * @param _pixt Address of the IXT contract
    * @param _pix Address of the PIX contract
    */
    function initialize(address _pixt, address _pix) external initializer {
        __PIXBaseSale_init(_pixt, _pix);
        __EIP712_init("PlanetIX", "1");
    }

    /** @notice request sale for fixed price
     *  @param _nftToken NFT token address for sale
     *  @param _tokenIds List of tokenIds
     *  @param _price fixed sale price
     */
    function requestSale(
        address _nftToken,
        uint256[] calldata _tokenIds,
        uint256 _price
    ) external onlyWhitelistedNFT(_nftToken) {
        require(_price > 0, "Sale: PRICE_ZERO");
        require(_tokenIds.length > 0, "Sale: NO_TOKENS");

        for (uint256 i; i < _tokenIds.length; i += 1) {
            IERC721Upgradeable(_nftToken).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        _registerSaleRequest(msg.sender, _nftToken, _price, _tokenIds);
    }

    /** @notice update sale info
     *  @param _saleId Sale id to update
     *  @param _price new price
     */
    function updateSale(uint256 _saleId, uint256 _price) external {
        require(saleInfo[_saleId].seller == msg.sender, "Sale: NOT_SELLER");
        require(_price > 0, "Sale: PRICE_ZERO");

        saleInfo[_saleId].price = _price;

        emit SaleUpdated(_saleId, _price);
    }

    /** @notice cancel sale request
     *  @param _saleId Sale id to cancel
     */
    function cancelSale(uint256 _saleId) public {
        FixedSaleInfo storage _saleInfo = saleInfo[_saleId];
        require(_saleInfo.seller == msg.sender, "Sale: NOT_SELLER");

        for (uint256 i; i < _saleInfo.tokenIds.length; i += 1) {
            IERC721Upgradeable(_saleInfo.nftToken).safeTransferFrom(
                address(this),
                msg.sender,
                _saleInfo.tokenIds[i]
            );
        }

        emit SaleCancelled(_saleId);
        delete saleInfo[_saleId];
    }

    /** @notice Bulk cancel sale request
     *  @param _saleIds An array of sale id to cancel
     */
    function bulkCancelSale(uint256[] calldata _saleIds) external {
        for (uint256 i; i < _saleIds.length; i++) {
            cancelSale(_saleIds[i]);
        }
    }

    /** @notice purchase NFT in fixed price
     *  @param buyer buyer address
     *  @param price bid amount
     *  @param nftToken nft token address
     *  @param tokenId nft token id
     */
    function sellNFTWithSignature(
        address buyer,
        uint256 price,
        address nftToken,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyWhitelistedNFT(nftToken) {
        uint256 nonce = nonces[buyer][nftToken][tokenId]++;
        bytes32 structHash = keccak256(
            abi.encode(BID_MESSAGE, buyer, price, nftToken, tokenId, nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == buyer, "Sale: INVALID_SIGNATURE");
        require(msg.sender == IERC721Upgradeable(nftToken).ownerOf(tokenId), "Sale: NOT_SELLER");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        _acceptPaymentForSell(msg.sender, buyer, price, nftToken, tokenIds);

        IERC721Upgradeable(nftToken).safeTransferFrom(msg.sender, buyer, tokenId);

        address _buyer = buyer;
        address _nftToken = nftToken;
        uint256 _tokenId = tokenId;
        uint256 _price = price;

        emit PurchasedWithSignature(msg.sender, _buyer, _nftToken, _tokenId, _price);
    }

    /** @notice purchase sale of NFT in fixed price
     *  @param buyer buyer address
     *  @param price bid amount
     *  @param saleId sale id
     */
    function sellSaleWithSignature(
        address buyer,
        uint256 price,
        uint256 saleId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = noncesForSale[buyer][saleId]++;
        bytes32 structHash = keccak256(abi.encode(OFFER_MESSAGE, buyer, price, saleId, nonce));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == buyer, "Sale: INVALID_SIGNATURE");
        require(msg.sender == saleInfo[saleId].seller, "Sale: NOT_SELLER");

        address _buyer = buyer;
        uint256 _price = price;
        uint256 _saleId = saleId;
        address _nftToken = saleInfo[saleId].nftToken;
        uint256[] memory tokenIds = saleInfo[saleId].tokenIds;

        _acceptPaymentForSell(msg.sender, _buyer, _price, _nftToken, tokenIds);

        for (uint256 i; i < tokenIds.length; i += 1) {
            IERC721Upgradeable(_nftToken).safeTransferFrom(address(this), _buyer, tokenIds[i]);
        }

        emit Purchased(msg.sender, _buyer, _saleId, _price);
    }

    /** @notice purchase NFT in fixed price
     *  @param _saleId Sale ID
     */
    function purchaseNFT(uint256 _saleId) external {
        FixedSaleInfo memory _saleInfo = saleInfo[_saleId];
        require(_saleInfo.price > 0, "Sale: INVALID_ID");

        _acceptPaymentForSell(
            _saleInfo.seller,
            msg.sender,
            _saleInfo.price,
            _saleInfo.nftToken,
            _saleInfo.tokenIds
        );

        for (uint256 i; i < _saleInfo.tokenIds.length; i += 1) {
            IERC721Upgradeable(_saleInfo.nftToken).safeTransferFrom(
                address(this),
                msg.sender,
                _saleInfo.tokenIds[i]
            );
        }

        emit Purchased(_saleInfo.seller, msg.sender, _saleId, _saleInfo.price);

        delete saleInfo[_saleId];
    }

    /**
    * @notice Used to set the holder for the burned tokens
    * @param holder The holder
    */
    function setBurnHolder(address holder) external onlyOwner {
        burnHolder = holder;
    }

    /**
    * @notice Sets the merkle minter
    * @param _pixMerkleMinter Address of the merkle minter
    */
    function setPixMerkleMinter(address _pixMerkleMinter) external onlyOwner {
        pixMerkleMinter = IPIXMerkleMinter(_pixMerkleMinter);
    }

    /**
    * @notice Lists an unminted PIX using merkle hash
    * @param _tokenIds The ids of the tokens
    * @param _price The price
    * @param info Array of pix info for the tokens
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    */
    function requestSaleWithHash(
        uint256[] calldata _tokenIds,
        uint256 _price,
        IPIX.PIXInfo[] memory info,
        bytes32[] calldata merkleRoot,
        bytes32[][] calldata merkleProofs
    ) external onlyWhitelistedNFT(pixNFT) {
        require(_price > 0, "Sale: PRICE_ZERO");

        uint256[] memory mintedTokenIds = pixMerkleMinter.mintToNewOwnerInBatch(
            address(this),
            msg.sender,
            info,
            merkleRoot,
            merkleProofs
        );

        uint256 tokenLength = _tokenIds.length;
        uint256[] memory saleTokenIds = new uint256[](tokenLength + mintedTokenIds.length);

        for (uint256 i; i < tokenLength; i += 1) {
            saleTokenIds[i] = _tokenIds[i];
            IERC721Upgradeable(pixNFT).safeTransferFrom(msg.sender, address(this), saleTokenIds[i]);
        }
        for (uint256 i = 0; i < mintedTokenIds.length; i += 1) {
            saleTokenIds[i + tokenLength] = mintedTokenIds[i];
        }

        _registerSaleRequest(msg.sender, pixNFT, _price, saleTokenIds);
    }

    /**
    * @notice Validates a buyers signature
    * @param buyer The buyers address
    * @param price The sale price
    * @param info The PIX info
    * @param v Signature
    * @param r Signature
    * @param s Signature
    */
    function _isValidV2Signature(
        address buyer,
        uint256 price,
        IPIX.PIXInfo memory info,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                BID_MESSAGE_WITH_HASH,
                buyer,
                price,
                msg.sender,
                keccak256(abi.encode(PIXINFO_TYPEHASH, info.pixId, info.category, info.size))
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        return signer == buyer;
    }

    /**
    * @notice Validates a buyers signature
    * @param buyer The buyers address
    * @param price The sale price
    * @param info The PIX info
    * @param v Signature
    * @param r Signature
    * @param s Signature
    */
    function _isValidV1Signature(
        address buyer,
        uint256 price,
        IPIX.PIXInfo memory info,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(BID_MESSAGE_WITH_HASH_V1, buyer, price, msg.sender, info)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        return signer == buyer;
    }

    /**
    * @notice Sells a not yet minted PIX using the buyers signature
    * @param buyer The buyers address
    * @param price The sale price
    * @param info Info regarding the pix
    * @param merkleRoot The merkle root
    * @param merkleProofs The merkle proofs
    * @param v Signature
    * @param r Signature
    * @param s Signature
    */
    function sellNFTWithSignatureWithHash(
        address buyer,
        uint256 price,
        IPIX.PIXInfo memory info,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProofs,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 tokenId = pixMerkleMinter.mintToNewOwner(
            buyer,
            msg.sender,
            info,
            merkleRoot,
            merkleProofs
        );

        require(
            _isValidV1Signature(buyer, price, info, v, r, s) ||
                _isValidV2Signature(buyer, price, info, v, r, s),
            "Sale: INVALID_SIGNATURE"
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        _acceptPaymentForSell(msg.sender, buyer, price, pixNFT, tokenIds);

        address _buyer = buyer;
        uint256 _tokenId = tokenId;
        uint256 _price = price;

        emit PurchasedWithSignature(msg.sender, _buyer, pixNFT, _tokenId, _price);
    }

    /**
    * @notice Handles the nitty-gritty of listing a token
    * @param seller The sellers address
    * @param nftToken The tokens address
    * @param price The sale price
    * @param tokenIds The Ids of the tokens to be sold
    */
    function _registerSaleRequest(
        address seller,
        address nftToken,
        uint256 price,
        uint256[] memory tokenIds
    ) private {
        lastSaleId += 1;
        saleInfo[lastSaleId] = FixedSaleInfo({
            seller: seller,
            nftToken: nftToken,
            price: price,
            tokenIds: tokenIds
        });

        emit SaleRequested(seller, lastSaleId, nftToken, tokenIds, price);
    }

    /**
    * @notice Handles the nitty-gritty of transferring funds between buyer and seller
    * @param seller The sellers address
    * @param buyer The buyers address
    * @param price The sale price
    * @param nftToken The address of the sold token
    * @param tokenIds The token Ids of the sold tokens
    */
    function _acceptPaymentForSell(
        address seller,
        address buyer,
        uint256 price,
        address nftToken,
        uint256[] memory tokenIds
    ) private {
        Treasury memory treasury;
        if (nftToken == pixNFT && IPIX(pixNFT).pixesInLand(tokenIds)) {
            treasury = landTreasury;
        } else {
            treasury = pixtTreasury;
        }

        uint256 fee = price.decimalMul(treasury.fee);
        uint256 burnFee = price.decimalMul(treasury.burnFee);
        uint256 tradeAmount = price - fee - burnFee;
        IERC20Upgradeable(pixToken).safeTransferFrom(buyer, seller, tradeAmount);
        if (fee > 0) {
            IERC20Upgradeable(pixToken).safeTransferFrom(buyer, treasury.treasury, fee);
        }
        if (burnFee > 0) {
            if (burnHolder == address(0)) ERC20Burnable(pixToken).burnFrom(buyer, burnFee);
            else IERC20Upgradeable(pixToken).safeTransferFrom(buyer, burnHolder, burnFee);
        }
    }
}
