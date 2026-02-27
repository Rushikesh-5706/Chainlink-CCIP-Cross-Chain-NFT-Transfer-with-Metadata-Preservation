// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";
import {CCIPNFTBridge} from "../src/CCIPNFTBridge.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Mock CCIP Router for testing
contract MockCCIPRouter {
    uint256 public constant MOCK_FEE = 0.1 ether;
    bytes32 public constant MOCK_MESSAGE_ID = keccak256("mock_message");

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external pure returns (uint256) {
        return MOCK_FEE;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage calldata) external payable returns (bytes32) {
        return MOCK_MESSAGE_ID;
    }
}

// Mock LINK token for testing
contract MockLINK is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }
}

contract CCIPNFTBridgeTest is Test {
    CrossChainNFT public nft;
    CCIPNFTBridge public bridge;
    MockCCIPRouter public mockRouter;
    MockLINK public mockLink;

    address public owner;
    address public user;
    uint64 public constant DEST_CHAIN_SELECTOR = 3478487238524512106;
    uint64 public constant SOURCE_CHAIN_SELECTOR = 14767482510784806043;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        mockRouter = new MockCCIPRouter();
        mockLink = new MockLINK();

        nft = new CrossChainNFT("CrossChainNFT", "CCNFT", owner);
        bridge = new CCIPNFTBridge(address(mockRouter), address(mockLink), address(nft));

        nft.setBridge(address(bridge));

        // Set trusted remote for destination chain
        bridge.setTrustedRemote(DEST_CHAIN_SELECTOR, address(0xdead));
        bridge.setTrustedRemote(SOURCE_CHAIN_SELECTOR, address(0xbeef));
    }

    function _mintAndPrepare(address to, uint256 tokenId, string memory uri) internal {
        // Temporarily set bridge to this contract to mint
        nft.setBridge(owner);
        nft.mint(to, tokenId, uri);
        nft.setBridge(address(bridge));
    }

    function test_SendNFTBurnsOnSource() public {
        _mintAndPrepare(user, 1, "https://example.com/1.json");

        // Give user LINK and approve
        mockLink.mint(user, 1 ether);

        vm.startPrank(user);
        mockLink.approve(address(bridge), 1 ether);
        nft.approve(address(bridge), 1);
        bridge.sendNFT(DEST_CHAIN_SELECTOR, user, 1);
        vm.stopPrank();

        // Token should no longer exist
        vm.expectRevert();
        nft.ownerOf(1);
    }

    function test_CcipReceiveMintsWithCorrectTokenURI() public {
        string memory uri = "https://example.com/metadata/1.json";

        // Build CCIP message as if from trusted remote
        bytes memory data = abi.encode(user, uint256(1), uri);
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: keccak256("test"),
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(address(0xbeef)),
            data: data,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        // Call ccipReceive as the router
        vm.prank(address(mockRouter));
        bridge.ccipReceive(message);

        // Verify mint
        assertEq(nft.ownerOf(1), user);
        assertEq(nft.tokenURI(1), uri);
    }

    function test_UntrustedSourceChainRejected() public {
        bytes memory data = abi.encode(user, uint256(1), "uri");
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: keccak256("test"),
            sourceChainSelector: 9999999,
            sender: abi.encode(address(0xdead)),
            data: data,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.prank(address(mockRouter));
        vm.expectRevert("Untrusted source chain");
        bridge.ccipReceive(message);
    }

    function test_EstimateTransferCostReturnsNonZero() public view {
        uint256 cost = bridge.estimateTransferCost(DEST_CHAIN_SELECTOR);
        assertGt(cost, 0);
        assertEq(cost, mockRouter.MOCK_FEE());
    }

    function test_DuplicateMintIdempotency() public {
        string memory uri = "https://example.com/1.json";

        // First receive — should mint
        bytes memory data = abi.encode(user, uint256(1), uri);
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: keccak256("test1"),
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(address(0xbeef)),
            data: data,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.prank(address(mockRouter));
        bridge.ccipReceive(message);
        assertEq(nft.ownerOf(1), user);

        // Second receive with same tokenId — should NOT revert, just skip
        Client.Any2EVMMessage memory message2 = Client.Any2EVMMessage({
            messageId: keccak256("test2"),
            sourceChainSelector: SOURCE_CHAIN_SELECTOR,
            sender: abi.encode(address(0xbeef)),
            data: data,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.prank(address(mockRouter));
        bridge.ccipReceive(message2);

        // Token should still be owned by user (not reverted)
        assertEq(nft.ownerOf(1), user);
    }
}
