// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CrossChainNFT} from "./CrossChainNFT.sol";

contract CCIPNFTBridge is CCIPReceiver, IERC721Receiver, Ownable {
    CrossChainNFT public immutable nft;
    IRouterClient public router;
    IERC20 public linkToken;
    mapping(uint64 => address) public trustedRemotes;

    event NFTSent(
        bytes32 messageId,
        uint64 destinationChainSelector,
        address receiver,
        uint256 tokenId,
        string tokenURI
    );

    event NFTReceived(
        bytes32 messageId,
        uint64 sourceChainSelector,
        address sender,
        uint256 tokenId,
        address receiver
    );

    constructor(
        address _router,
        address _link,
        address _nft
    ) CCIPReceiver(_router) Ownable(msg.sender) {
        router = IRouterClient(_router);
        linkToken = IERC20(_link);
        nft = CrossChainNFT(_nft);
    }

    function setTrustedRemote(uint64 chainSelector, address remoteAddress) external onlyOwner {
        trustedRemotes[chainSelector] = remoteAddress;
    }

    function sendNFT(
        uint64 destinationChainSelector,
        address receiver,
        uint256 tokenId
    ) external returns (bytes32 messageId) {
        string memory uri = nft.tokenURI(tokenId);

        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        nft.bridgeBurn(tokenId);

        bytes memory data = abi.encode(receiver, tokenId, uri);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(trustedRemotes[destinationChainSelector]),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000})),
            feeToken: address(linkToken)
        });

        uint256 fee = router.getFee(destinationChainSelector, message);

        linkToken.transferFrom(msg.sender, address(this), fee);
        linkToken.approve(address(router), fee);

        messageId = router.ccipSend(destinationChainSelector, message);

        emit NFTSent(messageId, destinationChainSelector, receiver, tokenId, uri);

        return messageId;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        require(trustedRemotes[message.sourceChainSelector] != address(0), "Untrusted source chain");

        address sender = abi.decode(message.sender, (address));
        require(sender == trustedRemotes[message.sourceChainSelector], "Untrusted sender");

        (address receiver, uint256 tokenId, string memory uri) = abi.decode(
            message.data,
            (address, uint256, string)
        );

        try nft.ownerOf(tokenId) returns (address) {
            return;
        } catch {
            // Token doesn't exist, proceed with mint
        }

        nft.mint(receiver, tokenId, uri);

        emit NFTReceived(message.messageId, message.sourceChainSelector, sender, tokenId, receiver);
    }

    function estimateTransferCost(uint64 destinationChainSelector) external view returns (uint256) {
        bytes memory dummyData = abi.encode(address(0), uint256(0), "");

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(trustedRemotes[destinationChainSelector]),
            data: dummyData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000})),
            feeToken: address(linkToken)
        });

        return router.getFee(destinationChainSelector, message);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override(CCIPReceiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
