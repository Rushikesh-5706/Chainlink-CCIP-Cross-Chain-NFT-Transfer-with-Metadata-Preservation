# Chainlink CCIP Cross-Chain NFT Bridge

A production-grade cross-chain NFT bridge that transfers ERC-721 NFTs between **Avalanche Fuji** and **Arbitrum Sepolia** testnets using **Chainlink CCIP** (Cross-Chain Interoperability Protocol) with full metadata preservation via the burn-and-mint pattern.

---

## Architecture

```
Source Chain (Avalanche Fuji)                          Destination Chain (Arbitrum Sepolia)
+---------------------------+                          +-------------------------------+
|                           |     Chainlink CCIP       |                               |
|  1. User approves NFT     |  ------------------->   |  5. CCIPReceiver triggered     |
|  2. User approves LINK    |   Encoded payload:       |  6. Validate trusted remote   |
|  3. Bridge burns NFT      |   (receiver, tokenId,    |  7. Idempotency check         |
|  4. Bridge sends CCIP msg |    tokenURI)             |  8. Mint NFT with same ID     |
|                           |                          |  9. Set same tokenURI         |
+---------------------------+                          +-------------------------------+
```

**Pattern:** Burn-and-mint. The NFT is burned on the source chain and re-minted with the same token ID and metadata URI on the destination chain. CCIP fees are paid in LINK tokens.

---

## Deployer Wallet

| Property | Value |
|----------|-------|
| Address | `0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80` |

---

## Deployed Contract Addresses

All contracts are deployed and verified on-chain.

### Avalanche Fuji (Chain ID: 43113)

| Contract | Address | Deployment Tx Hash |
|----------|---------|-------------------|
| CrossChainNFT | `0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8` | `0xa93319035b9193c400dacff8ae44a5199b4fe5f75fc62992564d0046b11d3f41` |
| CCIPNFTBridge | `0x20ea0caf3e9940a2dfae87fc59c51fb4959ce797` | `0x494e76f0c891811daa3967a0898d8a09ae4c07cb71ea393e622aee0819c091df` |

Explorer links:
- NFT Contract: https://testnet.snowtrace.io/address/0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8
- Bridge Contract: https://testnet.snowtrace.io/address/0x20ea0caf3e9940a2dfae87fc59c51fb4959ce797

### Arbitrum Sepolia (Chain ID: 421614)

| Contract | Address | Deployment Tx Hash |
|----------|---------|-------------------|
| CrossChainNFT | `0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8` | `0x1b426fb3731b2437a640f49faec83ceb400c9418a35870e25bb8372144f151cc` |
| CCIPNFTBridge | `0x20ea0caf3e9940a2dfae87fc59c51fb4959ce797` | `0x3ad91977abec8d6bc948fde72ee96a03e0a2a79c7240d5fa47d414cd3e16b2f0` |

Explorer links:
- NFT Contract: https://sepolia.arbiscan.io/address/0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8
- Bridge Contract: https://sepolia.arbiscan.io/address/0x20ea0caf3e9940a2dfae87fc59c51fb4959ce797

### Configuration Transactions (Trusted Remote Setup)

| Chain | Action | Tx Hash |
|-------|--------|---------|
| Fuji | setTrustedRemote(Arbitrum Sepolia) | `0xad209d041c31310eebcaefa90fe10ac1d6822f32386fd9cde9ab5a3c20c3d192` |
| Arbitrum Sepolia | setTrustedRemote(Fuji) | `0xcf7214327ab9bcdedeaef144ffad7ccb130d73a9af5a307af407fab4ffbb5344` |

---

## Pre-Minted Test Token

| Property | Value |
|----------|-------|
| Token ID | `1` |
| Chain | Avalanche Fuji |
| Owner | `0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80` |
| Token URI | `https://raw.githubusercontent.com/Rushikesh-5706/Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation/main/metadata/1.json` |
| Mint Tx Hash | `0x49b0847d8d48d428de2151e24cdc91149a0f71b4c3f913aef10416e65a2c898d` |

You can verify on-chain:

```bash
# Verify owner of tokenId=1 on Fuji
cast call 0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8 "ownerOf(uint256)(address)" 1 \
  --rpc-url https://avax-fuji.g.alchemy.com/v2/YOUR_KEY
# Expected output: 0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80

# Verify tokenURI of tokenId=1 on Fuji
cast call 0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8 "tokenURI(uint256)(string)" 1 \
  --rpc-url https://avax-fuji.g.alchemy.com/v2/YOUR_KEY
# Expected output: https://raw.githubusercontent.com/Rushikesh-5706/Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation/main/metadata/1.json
```

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Node.js | 18+ |
| Foundry (forge, cast) | Latest stable |
| Docker | 20+ |
| Docker Compose | v2+ |

Testnet tokens needed:
- AVAX on Avalanche Fuji (for gas) -- Faucet: https://core.app/tools/testnet-faucet/
- ETH on Arbitrum Sepolia (for gas) -- Faucet: https://faucets.chain.link/arbitrum-sepolia
- LINK on Avalanche Fuji (for CCIP fees) -- Faucet: https://faucets.chain.link/fuji

---

## Setup Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/Rushikesh-5706/Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation.git
cd Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation
```

### Step 2: Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Step 3: Install Foundry Dependencies

```bash
forge install
```

### Step 4: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set:
- `PRIVATE_KEY` -- your wallet private key (with 0x prefix)
- `FUJI_RPC_URL` -- Avalanche Fuji RPC URL
- `ARBITRUM_SEPOLIA_RPC_URL` -- Arbitrum Sepolia RPC URL

### Step 5: Build Contracts

```bash
forge build
```

Expected output:
```
[OK] Compiling...
Compiler run successful!
```

### Step 6: Run Tests

```bash
forge test -vvv
```

Expected output:
```
Ran 5 tests for test/CCIPNFTBridgeTest.t.sol:CCIPNFTBridgeTest
[PASS] test_CcipReceiveMintsWithCorrectTokenURI()
[PASS] test_DuplicateMintIdempotency()
[PASS] test_EstimateTransferCostReturnsNonZero()
[PASS] test_SendNFTBurnsOnSource()
[PASS] test_UntrustedSourceChainRejected()
Suite result: ok. 5 passed; 0 failed; 0 skipped

Ran 7 tests for test/CrossChainNFTTest.t.sol:CrossChainNFTTest
[PASS] test_BridgeBurnRevertsForNonBridge()
[PASS] test_BridgeBurnWorksByBridge()
[PASS] test_BurnRevertsWhenCallerIsNotOwner()
[PASS] test_BurnWorksWhenCallerIsOwner()
[PASS] test_MintSetsTokenURI()
[PASS] test_OnlyBridgeCanMint()
[PASS] test_OnlyOwnerCanSetBridge()
Suite result: ok. 7 passed; 0 failed; 0 skipped

Ran 2 test suites: 12 tests passed, 0 failed, 0 skipped (12 total tests)
```

### Step 7: Install Node.js Dependencies

```bash
npm install
```

---

## Deployment Instructions

Contracts are already deployed. If you need to redeploy:

### Deploy to Avalanche Fuji

```bash
source .env
forge script script/DeployFuji.s.sol --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
```

### Deploy to Arbitrum Sepolia

```bash
source .env
forge script script/DeployArbitrumSepolia.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Configure Trusted Remotes

After both deployments, add `FUJI_BRIDGE_ADDRESS` and `ARBITRUM_SEPOLIA_BRIDGE_ADDRESS` to your `.env` with the deployed bridge addresses, then:

```bash
source .env

# Configure Fuji bridge to trust Arbitrum Sepolia bridge
forge script script/Configure.s.sol --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy

# Configure Arbitrum Sepolia bridge to trust Fuji bridge
forge script script/Configure.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## CLI Usage

### Transfer Command

```bash
npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
```

### CLI Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `--tokenId` | integer | Yes | Token ID to transfer |
| `--from` | string | Yes | Source chain: `avalanche-fuji` |
| `--to` | string | Yes | Destination chain: `arbitrum-sepolia` |
| `--receiver` | string | Yes | Receiver address on destination chain (must be valid Ethereum address) |

### Expected CLI Output

```
[2026-02-27 16:00:00] INFO: Transfer started: tokenId=1 from=avalanche-fuji to=arbitrum-sepolia receiver=0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
[2026-02-27 16:00:01] INFO: Connected as: 0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
[2026-02-27 16:00:02] INFO: Estimated CCIP fee: 0.0XXX LINK
[2026-02-27 16:00:03] INFO: Approving LINK token for bridge...
[2026-02-27 16:00:10] INFO: LINK approval tx: 0x<real_tx_hash>
[2026-02-27 16:00:11] INFO: Approving NFT for bridge...
[2026-02-27 16:00:18] INFO: NFT approval tx: 0x<real_tx_hash>
[2026-02-27 16:00:19] INFO: Sending NFT via CCIP...
[2026-02-27 16:00:30] INFO: SOURCE TX HASH: 0x<real_tx_hash>
[2026-02-27 16:00:30] INFO: CCIP MESSAGE ID: 0x<real_ccip_message_id>
[2026-02-27 16:00:30] INFO: Transfer initiated successfully. Track at: https://ccip.chain.link/msg/0x<ccip_message_id>
[2026-02-27 16:00:30] INFO: Transfer record saved to data/nft_transfers.json
```

### What Happens After Transfer

1. The NFT is burned on Avalanche Fuji (source chain)
2. A CCIP message is sent to Arbitrum Sepolia (destination chain)
3. After approximately 15-20 minutes, the CCIP message is delivered
4. The NFT is minted on Arbitrum Sepolia with the same tokenId and tokenURI
5. You can verify: `cast call 0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8 "ownerOf(uint256)(address)" 1 --rpc-url $ARBITRUM_SEPOLIA_RPC_URL`

### Tracking Transfers

Track any transfer on the CCIP Explorer using the CCIP Message ID:

```
https://ccip.chain.link/msg/<CCIP_MESSAGE_ID>
```

---

## Docker Usage

### Build and Start Container

```bash
docker-compose up -d --build
```

Expected output:
```
[+] Building ...
[+] Running 1/1
 - Container ccip-nft-bridge-cli  Started
```

### Verify Container is Running

```bash
docker ps --filter name=ccip-nft-bridge-cli
```

Expected output:
```
CONTAINER ID   IMAGE    COMMAND                  CREATED          STATUS          NAMES
xxxxxxxxxxxx   ...      "docker-entrypoint.s..."  X seconds ago   Up X seconds    ccip-nft-bridge-cli
```

### Run Transfer Inside Container

```bash
docker exec ccip-nft-bridge-cli npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
```

### Push Docker Image to Docker Hub

```bash
docker tag ccip-nft-bridge-cli rushi5706/ccip-nft-bridge-cli:latest
docker push rushi5706/ccip-nft-bridge-cli:latest
```

Docker Hub: https://hub.docker.com/r/rushi5706/ccip-nft-bridge-cli

---

## Transfer Logs and Records

| File | Purpose | Format |
|------|---------|--------|
| `logs/transfers.log` | Timestamped operation log | Text with `[TIMESTAMP] LEVEL: message` format |
| `data/nft_transfers.json` | Structured transfer history | JSON array with transfer records including metadata |

### Transfer Record Schema (data/nft_transfers.json)

```json
{
  "transferId": "uuid-v4",
  "tokenId": "1",
  "sourceChain": "avalanche-fuji",
  "destinationChain": "arbitrum-sepolia",
  "sender": "0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80",
  "receiver": "0x...",
  "ccipMessageId": "0x...",
  "sourceTxHash": "0x...",
  "destinationTxHash": null,
  "status": "initiated",
  "metadata": {
    "name": "CrossChainNFT #1",
    "description": "A cross-chain NFT bridged using Chainlink CCIP",
    "image": "https://ipfs.io/ipfs/QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco/I/m/Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project.jpg"
  },
  "timestamp": "2026-02-27T10:30:00.000Z"
}
```

---

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `PRIVATE_KEY` | Deployer wallet private key | `0x41139dc8...` |
| `FUJI_RPC_URL` | Avalanche Fuji RPC endpoint | `https://avax-fuji.g.alchemy.com/v2/...` |
| `ARBITRUM_SEPOLIA_RPC_URL` | Arbitrum Sepolia RPC endpoint | `https://arb-sepolia.g.alchemy.com/v2/...` |
| `CCIP_ROUTER_FUJI` | CCIP Router on Fuji | `0xF694E193200268f9a4868e4Aa017A0118C9a8177` |
| `CCIP_ROUTER_ARBITRUM_SEPOLIA` | CCIP Router on Arbitrum Sepolia | `0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165` |
| `LINK_TOKEN_FUJI` | LINK token on Fuji | `0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846` |
| `LINK_TOKEN_ARBITRUM_SEPOLIA` | LINK token on Arbitrum Sepolia | `0xb1D4538B4571d411F07960EF2838Ce337FE1E80E` |
| `FUJI_CHAIN_SELECTOR` | CCIP chain selector for Fuji | `14767482510784806043` |
| `ARBITRUM_SEPOLIA_CHAIN_SELECTOR` | CCIP chain selector for Arbitrum Sepolia | `3478487238524512106` |

---

## Foundry Test Coverage

| Test File | Test Name | What It Verifies |
|-----------|-----------|-----------------|
| CrossChainNFTTest.t.sol | test_OnlyOwnerCanSetBridge | Only contract owner can call setBridge |
| CrossChainNFTTest.t.sol | test_OnlyBridgeCanMint | Only bridge address can mint NFTs |
| CrossChainNFTTest.t.sol | test_MintSetsTokenURI | mint correctly stores and returns tokenURI |
| CrossChainNFTTest.t.sol | test_BurnWorksWhenCallerIsOwner | Token owner can burn their NFT |
| CrossChainNFTTest.t.sol | test_BurnRevertsWhenCallerIsNotOwner | Non-owner cannot burn an NFT |
| CrossChainNFTTest.t.sol | test_BridgeBurnWorksByBridge | Bridge can call bridgeBurn |
| CrossChainNFTTest.t.sol | test_BridgeBurnRevertsForNonBridge | Non-bridge cannot call bridgeBurn |
| CCIPNFTBridgeTest.t.sol | test_SendNFTBurnsOnSource | sendNFT burns the NFT on source chain |
| CCIPNFTBridgeTest.t.sol | test_CcipReceiveMintsWithCorrectTokenURI | _ccipReceive mints NFT with correct URI |
| CCIPNFTBridgeTest.t.sol | test_UntrustedSourceChainRejected | Messages from untrusted chains are rejected |
| CCIPNFTBridgeTest.t.sol | test_EstimateTransferCostReturnsNonZero | Fee estimation returns valid non-zero amount |
| CCIPNFTBridgeTest.t.sol | test_DuplicateMintIdempotency | Duplicate CCIP messages do not cause reverts |

---

## Project Structure

```
/
+-- src/
|   +-- CrossChainNFT.sol              ERC721URIStorage + Ownable, bridge-only mint/burn
|   +-- CCIPNFTBridge.sol              CCIPReceiver with burn-mint logic, LINK fees
+-- script/
|   +-- DeployFuji.s.sol               Fuji deployment (NFT + Bridge + mint tokenId=1)
|   +-- DeployArbitrumSepolia.s.sol    Arbitrum Sepolia deployment (NFT + Bridge)
|   +-- Configure.s.sol               Set trusted remotes on both chains
+-- test/
|   +-- CrossChainNFTTest.t.sol        7 tests for NFT access control and mint/burn
|   +-- CCIPNFTBridgeTest.t.sol        5 tests for bridge send/receive/idempotency
+-- cli/
|   +-- transfer.js                    Node.js CLI for cross-chain NFT transfers
+-- data/
|   +-- nft_transfers.json             JSON transfer records (starts as [])
+-- logs/
|   +-- transfers.log                  Operation log file
+-- metadata/
|   +-- 1.json                         NFT metadata for tokenId=1
+-- lib/                               Foundry dependencies (OpenZeppelin, Chainlink, forge-std)
+-- deployment.json                    Real deployed contract addresses
+-- foundry.toml                       Foundry config with remappings
+-- package.json                       Node.js dependencies and scripts
+-- package-lock.json                  Locked dependency versions
+-- Dockerfile                         Docker image for CLI
+-- docker-compose.yml                 Docker Compose service config
+-- .env.example                       Environment variable template
+-- .dockerignore                      Docker build exclusions
+-- .gitignore                         Git exclusions
+-- README.md                          This file
```

---

## License

MIT
