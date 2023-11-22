// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
@title Interface defining a PIX
*/
interface IPIX {

    /**
    * @notice Event emitted when a trader has been added/removed
    * @param trader The address of the trader
    * @param approved Whether the trader is approved
    */
    event TraderUpdated(address indexed trader, bool approved);

    /**
    * @notice Event emitted when a moderator has been added/removed
    * @param moderator The address of the moderator
    * @param approved Whether the address is a moderator or not
    */
    event ModeratorUpdated(address indexed moderator, bool approved);

    /**
    * @notice Event emitted when a pack price is updated
    * @param mode The index of the pack
    * @param price The price of the pack
    */
    event PackPriceUpdated(uint256 indexed mode, uint256 price);

    /**
    * @notice Event emitted when the pix combine price is updated
    * @param price The price
    */
    event CombinePriceUpdated(uint256 price);

    /**
    * @notice Event emitted when the accepted payment tokens are updated
    * @param token Address to the token
    * @param approved Whether the token is approved for purchasing.
    */
    event PaymentTokenUpdated(address indexed token, bool approved);

    /**
    * @notice Event emitted when the treasury is updated
    * @param treasury The address of the new treasury
    * @param fee The fee of the new treasury
    */
    event TreasuryUpdated(address treasury, uint256 fee);

    /**
    * @notice Event for when a PIX or territory is minted
    * @param account The account to which the PIX belongs
    * @param tokenId The ERC-721 token Id
    * @param pixId The PIX Id
    * @param category Denotes the tier of the PIX
    * @param size Denotes the territory class of the PIX
    */
    event PIXMinted(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed pixId,
        PIXCategory category,
        PIXSize size
    );

    /**
    * @notice Event for when pix are combined into a larger territory
    * @param tokenId The token ID of the pix
    * @param category The tier of the PIX
    * @param size Denotes the NEW territory class of the PIX
    */
    event Combined(uint256 indexed tokenId, PIXCategory category, PIXSize size);

    /**
    * @notice Event emitted when a pack is requested
    * @param dropId The Id of the drop
    * @param playerId The player id requesting the drop
    * @param mode The index of the pack
    * @param purchasedPacks Broken!
    * @param count The numbers of packs requested
    */
    event Requested(
        uint256 indexed dropId,
        uint256 indexed playerId,
        uint256 indexed mode,
        uint256 purchasedPacks,
        uint256 count
    );

    /**
    * @notice Event for when pix are combined into a larger territory
    * @param tokenId The token ID of the pix
    * @param tokenIds A list of token IDs that are being combined
    * @param category The tier of the PIX
    * @param size Denotes the NEW territory class of the PIX
    */
    event CombinedWithBurned(uint256 indexed tokenId, uint[] tokenIds, PIXCategory category, PIXSize size);
    
    /// Enumeration to keep track of PIX teirs
    enum PIXCategory {
        Legendary,
        Rare,
        Uncommon,
        Common,
        Outliers
    }

    /// Enumeration to keep track of PIX territory sizes, incl. single PIX
    enum PIXSize {
        Pix,
        Area,
        Sector,
        Zone,
        Domain
    }

    /**
    @notice Struct containing information about the Planet IX treasury
    @param treasury The treasury address
    @param fee The treasury fee
    */
    struct Treasury {
        address treasury;
        uint256 fee;
    }

    /**
    @notice Struct containing information about a PIX
    @param category The teir of the PIX
    @param size The size of the PIX
    */
    struct PIXInfo {
        uint256 pixId;
        PIXCategory category;
        PIXSize size;
    }

    /**
    * @notice Struct to hold information regarding a pack drop
    * @param maxCount Max number of packs that can be sold
    * @param requestCount The number of packs requested
    * @param limitForPlayer The per-player limit
    * @param startTime The start time of the drop
    * @param endTime The end time of the drop
    */
    struct DropInfo {
        uint256 maxCount;
        uint256 requestCount;
        uint256 limitForPlayer;
        uint256 startTime;
        uint256 endTime;
    }

    /**
    * @notice Struct containing a request for a pack
    * @param playerId The Id of the requesting player
    * @param dropId The Id of the drop.
    */
    struct PackRequest {
        uint256 playerId;
        uint256 dropId;
    }

    /**
    * @notice Checks if a PIX is a territory
    * @param tokenId The PIX in question
    * @return True if the PIX is not a singular PIX
    */
    function isTerritory(uint256 tokenId) external view returns (bool);

    /**
    @dev Always returns false in PIX.sol
    */
    function pixesInLand(uint256[] calldata tokenIds) external view returns (bool);

    /**
    * @dev Intended as wrapper for ERC-721 minting
    * @notice Mints a PIX
    * @param to The owner of the new PIX
    * @param info Data regarding the PIX
    */
    function safeMint(address to, PIXInfo memory info) external;

    /**
    * @notice Retrieves the id of the latest token
    * @return The id
    * @dev Is implemented as a state variable in PIX.sol
    */
    function lastTokenId() external view returns (uint256);

    /**
    @notice Returns the tier of the PIX corresponding to the given ID
    @param tokenId The token ID of the PIX.
    @return The tier
    */
    function getTier(uint256 tokenId) external view returns (uint256);

    /**
    * @notice Used to get information regarding a pix
    * @param tokenId The id of the PIX
    * @return Information struct
    */
    function getInfo(uint256 tokenId) external view returns (PIXInfo memory);
}
