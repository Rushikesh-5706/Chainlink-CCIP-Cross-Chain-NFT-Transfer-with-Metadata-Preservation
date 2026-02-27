// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainNFT is ERC721URIStorage, Ownable {
    address public bridge;

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {}

    modifier onlyBridge() {
        require(msg.sender == bridge, "Caller is not the bridge");
        _;
    }

    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    function mint(address to, uint256 tokenId, string memory tokenURI_) external onlyBridge {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(
            owner == msg.sender ||
            getApproved(tokenId) == msg.sender ||
            isApprovedForAll(owner, msg.sender),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function bridgeBurn(uint256 tokenId) external onlyBridge {
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
