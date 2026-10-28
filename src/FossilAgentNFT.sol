// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Fossil Agent NFT (FNFT)
/// @notice Holders of a .ai Agent ID (SPACE ID) get their first mint free;
///         every other mint costs 0.0005 BNB. Max 5 per wallet, 1000 supply.
contract FossilAgentNFT is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant PRICE = 0.0005 ether;
    IERC721 public constant AGENT_ID = IERC721(0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F);

    uint256 public totalMinted;
    string private _baseTokenURI;
    mapping(address => bool) public freeUsed;

    constructor(address initialOwner, string memory baseURI_)
        ERC721("Fossil Agent NFT", "FNFT")
        Ownable(initialOwner)
    {
        _baseTokenURI = baseURI_;
    }

    function hasAgentId(address user) public view returns (bool) {
        return AGENT_ID.balanceOf(user) > 0;
    }

    function freeAvailable(address user) public view returns (bool) {
        return hasAgentId(user) && !freeUsed[user];
    }

    function quote(address user, uint256 qty) public view returns (uint256) {
        uint256 paidQty = qty;
        if (qty > 0 && freeAvailable(user)) paidQty = qty - 1;
        return paidQty * PRICE;
    }

    function mint(uint256 qty) external payable {
        require(qty > 0 && qty <= MAX_PER_WALLET, "qty 1-5");
        require(totalMinted + qty <= MAX_SUPPLY, "sold out");
        require(balanceOf(msg.sender) + qty <= MAX_PER_WALLET, "max 5 per wallet");
        uint256 cost = quote(msg.sender, qty);
        require(msg.value >= cost, "insufficient payment");
        if (freeAvailable(msg.sender)) freeUsed[msg.sender] = true;
        for (uint256 i = 0; i < qty; i++) {
            totalMinted += 1;
            _safeMint(msg.sender, totalMinted);
        }
        if (msg.value > cost) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - cost}("");
            require(ok, "refund failed");
        }
    }

    function withdraw() external onlyOwner {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok, "withdraw failed");
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }
}
