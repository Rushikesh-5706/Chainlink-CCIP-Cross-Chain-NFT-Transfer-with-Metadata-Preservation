// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";
import {CCIPNFTBridge} from "../src/CCIPNFTBridge.sol";

contract DeployFuji is Script {
    address constant CCIP_ROUTER_FUJI = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address constant LINK_TOKEN_FUJI = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        CrossChainNFT nft = new CrossChainNFT("CrossChainNFT", "CCNFT", deployer);
        console.log("CrossChainNFT deployed at:", address(nft));

        CCIPNFTBridge bridge = new CCIPNFTBridge(CCIP_ROUTER_FUJI, LINK_TOKEN_FUJI, address(nft));
        console.log("CCIPNFTBridge deployed at:", address(bridge));

        nft.setBridge(deployer);
        nft.mint(deployer, 1, "https://raw.githubusercontent.com/Rushikesh-5706/Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation/main/metadata/1.json");
        console.log("Minted tokenId=1 to deployer:", deployer);

        nft.setBridge(address(bridge));
        console.log("Bridge formally set on NFT contract");

        vm.stopBroadcast();
    }
}
