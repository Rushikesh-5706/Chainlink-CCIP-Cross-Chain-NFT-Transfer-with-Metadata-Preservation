// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";

contract CrossChainNFTTest is Test {
    CrossChainNFT public nft;
    address public owner;
    address public bridge;
    address public user;

    function setUp() public {
        owner = address(this);
        bridge = makeAddr("bridge");
        user = makeAddr("user");

        nft = new CrossChainNFT("CrossChainNFT", "CCNFT", owner);
        nft.setBridge(bridge);
    }

    function test_OnlyOwnerCanSetBridge() public {
        vm.prank(user);
        vm.expectRevert();
        nft.setBridge(user);

        // Owner can set bridge
        nft.setBridge(bridge);
        assertEq(nft.bridge(), bridge);
    }

    function test_OnlyBridgeOrOwnerCanMint() public {
        vm.prank(user);
        vm.expectRevert("Not bridge or owner");
        nft.mint(user, 1, "https://example.com/1.json");

        vm.prank(bridge);
        nft.mint(user, 1, "https://example.com/1.json");
        assertEq(nft.ownerOf(1), user);
        
        vm.prank(owner);
        nft.mint(user, 2, "https://example.com/2.json");
        assertEq(nft.ownerOf(2), user);
    }

    function test_MintSetsTokenURI() public {
        string memory uri = "https://example.com/metadata/1.json";

        vm.prank(bridge);
        nft.mint(user, 1, uri);

        assertEq(nft.tokenURI(1), uri);
    }

    function test_BurnWorksWhenCallerIsOwner() public {
        vm.prank(bridge);
        nft.mint(user, 1, "https://example.com/1.json");

        vm.prank(user);
        nft.burn(1);

        vm.expectRevert();
        nft.ownerOf(1);
    }

    function test_BurnRevertsWhenCallerIsNotOwner() public {
        vm.prank(bridge);
        nft.mint(user, 1, "https://example.com/1.json");

        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        nft.burn(1);
    }

    function test_BridgeBurnWorksByBridge() public {
        vm.prank(bridge);
        nft.mint(user, 1, "https://example.com/1.json");

        vm.prank(bridge);
        nft.bridgeBurn(1);

        vm.expectRevert();
        nft.ownerOf(1);
    }

    function test_BridgeBurnRevertsForNonBridge() public {
        vm.prank(bridge);
        nft.mint(user, 1, "https://example.com/1.json");

        vm.prank(user);
        vm.expectRevert("Caller is not the bridge");
        nft.bridgeBurn(1);
    }
}
