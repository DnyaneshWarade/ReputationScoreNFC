// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./lib/GenesisUtils.sol";
import "./interfaces/ICircuitValidator.sol";
import "./verifiers/ZKPVerifier.sol";

// contarct deployed at  : 0x6F6F2423E2Eb29A736e16D8D2d3Dd39e0d94870a
contract ERC721Verifier is
    ERC721URIStorage,
    ZKPVerifier,
    KeeperCompatibleInterface
{
    struct ExpirationDate {
        address nftAddress;
        uint256 nftId;
        uint256 expirationTimestamp;
    }

    ExpirationDate[] private expirationDates;

    uint64 public constant TRANSFER_REQUEST_ID = 1;

    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Karma Score Certified", "KSC") {}

    // add details to ExpirationDate struct
    function addExpirationDate(
        address _nftAddress,
        uint256 _nftId,
        uint256 _expirationTimestamp
    ) private {
        expirationDates.push(
            ExpirationDate({
                nftAddress: _nftAddress,
                nftId: _nftId,
                expirationTimestamp: _expirationTimestamp
            })
        );
    }

    // checkUpKeep
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        uint256 arrayLength = expirationDates.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (block.timestamp >= expirationDates[i].expirationTimestamp) {
                upkeepNeeded = true;
                return (upkeepNeeded, "");
            }
        }
        upkeepNeeded = false;
        return (upkeepNeeded, "");
    }

    // perfoemUpKeep
    function performUpkeep(bytes calldata /* performData */) external {
        uint256 arrayLength = expirationDates.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (block.timestamp >= expirationDates[i].expirationTimestamp) {
                IERC721(expirationDates[i].nftAddress).safeTransferFrom(
                    address(this),
                    address(0xdead),
                    expirationDates[i].nftId
                );
            }
        }
    }

    function _beforeProofSubmit(
        uint64 /* requestId */,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal view override {
        // check that challenge input of the proof is equal to the msg.sender
        address addr = GenesisUtils.int256ToAddress(
            inputs[validator.getChallengeInputIndex()]
        );
        require(
            _msgSender() == addr,
            "address in proof is not a sender address"
        );
    }

    function _afterProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal override {
        require(
            requestId == TRANSFER_REQUEST_ID && addressToId[_msgSender()] == 0,
            "proof can not be submitted more than once"
        );

        uint256 id = inputs[validator.getChallengeInputIndex()];
        // execute the airdrop
        if (idToAddress[id] == address(0)) {
            uint256 tokenId = _tokenIds.current();
            _tokenIds.increment();
            _safeMint(_msgSender(), tokenId);

            addressToId[_msgSender()] = id;
            idToAddress[id] = _msgSender();

            // get nft address
            IERC721 nft = IERC721(ERC721.ownerOf(tokenId));

            uint256 expirationTimestamp = block.timestamp + 365 days;
            addExpirationDate(address(nft), tokenId, expirationTimestamp);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure override {
        require(
            from == address(0) || to == address(0),
            "Your nft is your own not someone elses."
        );
    }

    function generateSVGforToken() public pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            "<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>",
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Verified Karma Score",
            "</text>",
            "</svg>"
        );
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    function getTokenURI(uint256 tokenId) public pure returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Karma Score',
            tokenId.toString(),
            '",',
            '"description": "Verified Karma Score",',
            '"image": "',
            generateSVGforToken(),
            '"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}
