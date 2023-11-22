// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../core/PIXT.sol";
import "../interfaces/IPIX.sol";
import "../libraries/DecimalMath.sol";

/**
* @title Abstract contract for various PIX sale methods
*/
abstract contract PIXBaseSale is OwnableUpgradeable, ERC721HolderUpgradeable {
    using DecimalMath for uint256;

    /**
    * @notice Event emitted when a PIX is purchased
    * @param seller The address of the seller
    * @param buyer The address of the buyer
    * @param saleId The Id of the sale
    * @param price The price of the sale
    */
    event Purchased(
        address indexed seller,
        address indexed buyer,
        uint256 indexed saleId,
        uint256 price
    );

    /**
    * @notice Event emitted upon the cancellation of a sale
    * @param saleId The Id of the sale
    */
    event SaleCancelled(uint256 indexed saleId);

    /**
    * @notice Event emitted upon updating the treasury
    * @param treasury The address of the updated treasury
    * @param fee The treasury fee
    * @param burnFee The fee that will be burned
    * @param mode (What is this precisely?)
    */
    event TreasuryUpdated(address treasury, uint256 fee, uint256 burnFee, bool mode);

    /**
    * @notice Struct to hold treasury information
    * @param treasury Address of the treasury
    * @param fee Fee of the treasury
    * @param burnFee Burn fee
    */
    struct Treasury {
        address treasury;
        uint256 fee;
        uint256 burnFee;
    }

    // treasury information
    Treasury public landTreasury;
    Treasury public pixtTreasury;

    // PIXT token
    address public pixToken;
    address public pixNFT;

    // Whitelisted NFT tokens
    mapping(address => bool) public whitelistedNFTs;

    // Last sale id
    uint256 public lastSaleId;

    /**
    * @notice Modifier to only allow whitelisted NFTs
    * @param token The address of the token that is to be checked against the whitelist
    */
    modifier onlyWhitelistedNFT(address token) {
        require(whitelistedNFTs[token], "Sale: NOT_WHITELISTED_NFT");
        _;
    }

    /**
    * @notice Initializer for the base sale
    * @param pixt Address of the IXT contract
    * @param pix Address of the PIX contract
    */
    function __PIXBaseSale_init(address pixt, address pix) internal initializer {
        require(pixt != address(0), "Sale: INVALID_PIXT");
        require(pix != address(0), "Sale: INVALID_PIX");
        pixToken = pixt;
        pixNFT = pix;
        __Ownable_init();
        __ERC721Holder_init();
    }

    /**
    * @notice Used to set the treasury
    * @param _treasury The address of the new treasury
    * @param _fee The treasury fee
    * @param _burnFee The treasury burn fee
    * @param _mode Decides between setting the land vs pixt treasury
    */
    function setTreasury(
        address _treasury,
        uint256 _fee,
        uint256 _burnFee,
        bool _mode
    ) external onlyOwner {
        require(_treasury != address(0), "Sale: INVALID_TREASURY");
        require((_fee + _burnFee).isLessThanAndEqualToDenominator(), "Sale: FEE_OVERFLOWN");
        Treasury memory treasury = Treasury(_treasury, _fee, _burnFee);
        if (_mode) {
            landTreasury = treasury;
        } else {
            pixtTreasury = treasury;
        }

        emit TreasuryUpdated(_treasury, _fee, _burnFee, _mode);
    }

    /**
    * @notice Used to set the whitelist
    * @param _token Address of token to manage
    * @param _whitelist Whether the token should be whitelisted
    */
    function setWhitelistedNFTs(address _token, bool _whitelist) external onlyOwner {
        whitelistedNFTs[_token] = _whitelist;
    }
}
