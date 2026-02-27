// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";
import {CCIPNFTBridge} from "../src/CCIPNFTBridge.sol";

contract DeployArbitrumSepolia is Script {
    address constant CCIP_ROUTER_ARBITRUM_SEPOLIA = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address constant LINK_TOKEN_ARBITRUM_SEPOLIA = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        CrossChainNFT nft = new CrossChainNFT("CrossChainNFT", "CCNFT", deployer);
        console.log("CrossChainNFT deployed at:", address(nft));

        CCIPNFTBridge bridge = new CCIPNFTBridge(CCIP_ROUTER_ARBITRUM_SEPOLIA, LINK_TOKEN_ARBITRUM_SEPOLIA, address(nft));
        console.log("CCIPNFTBridge deployed at:", address(bridge));

        nft.setBridge(address(bridge));
        console.log("Bridge set on NFT contract");

        vm.stopBroadcast();
    }
}
