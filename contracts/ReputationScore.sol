// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ReputationScore is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public constant TOKEN_URI =
        "https://bafybeic34xrr77voiycvgjf7sld6f677syfbmccqydkxbdkadsn6abmlxy.ipfs.w3s.link/karmascorebadge.png";

    // tokenId => validity
    mapping(uint256 => uint256) public validity;

    constructor() ERC721("ReputationScore", "RS") {}

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        validity[tokenId] = block.timestamp + 365 days;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, TOKEN_URI);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        require(
            from == address(0) || to == address(0),
            "Err: token transfer is BLOCKED"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function isValidNFC(uint256 tokenId) public view returns (bool) {
        return validity[tokenId] >= block.timestamp;
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
