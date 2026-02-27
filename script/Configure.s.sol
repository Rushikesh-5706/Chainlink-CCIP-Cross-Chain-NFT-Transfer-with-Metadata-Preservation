// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {CCIPNFTBridge} from "../src/CCIPNFTBridge.sol";

contract Configure is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        uint64 fujiChainSelector = uint64(vm.envUint("FUJI_CHAIN_SELECTOR"));
        uint64 arbSepoliaChainSelector = uint64(vm.envUint("ARBITRUM_SEPOLIA_CHAIN_SELECTOR"));
        address fujiBridge = vm.envAddress("FUJI_BRIDGE_ADDRESS");
        address arbSepoliaBridge = vm.envAddress("ARBITRUM_SEPOLIA_BRIDGE_ADDRESS");

        uint64 currentChainId = uint64(block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        if (currentChainId == 43113) {
            // Fuji — set Arbitrum Sepolia as trusted remote
            CCIPNFTBridge bridge = CCIPNFTBridge(fujiBridge);
            bridge.setTrustedRemote(arbSepoliaChainSelector, arbSepoliaBridge);
            console.log("Fuji bridge: set trusted remote for Arbitrum Sepolia");
        } else if (currentChainId == 421614) {
            // Arbitrum Sepolia — set Fuji as trusted remote
            CCIPNFTBridge bridge = CCIPNFTBridge(arbSepoliaBridge);
            bridge.setTrustedRemote(fujiChainSelector, fujiBridge);
            console.log("Arbitrum Sepolia bridge: set trusted remote for Fuji");
        } else {
            revert("Unknown chain ID");
        }

        vm.stopBroadcast();
    }
}
