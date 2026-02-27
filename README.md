# Chainlink CCIP Cross-Chain NFT Bridge

A cross-chain NFT bridge that transfers ERC-721 NFTs between **Avalanche Fuji** and **Arbitrum Sepolia** testnets using **Chainlink CCIP** (Cross-Chain Interoperability Protocol) with full metadata preservation.

## Architecture Overview

This project implements the **burn-and-mint** pattern for cross-chain NFT transfers:

1. **Source Chain (Avalanche Fuji):** The user approves and sends their NFT to the bridge contract. The bridge burns the NFT on the source chain, encodes the token ID, receiver address, and token URI into a CCIP message, and sends it to the destination chain via Chainlink CCIP.

2. **Destination Chain (Arbitrum Sepolia):** The bridge contract on the destination chain receives the CCIP message, decodes it, and mints a new NFT with the same token ID and token URI to the receiver address. An idempotency check prevents duplicate mints.

3. **Fee Payment:** Transfer fees are paid in LINK tokens. The CLI estimates the fee, prompts for LINK approval, and handles the entire flow automatically.

```
┌──────────────────┐        CCIP Message          ┌──────────────────┐
│  Avalanche Fuji  │ ──────────────────────────▶  │ Arbitrum Sepolia  │
│                  │                               │                   │
│  1. Approve NFT  │                               │  4. Receive msg   │
│  2. Burn NFT     │                               │  5. Mint NFT      │
│  3. Send CCIP    │                               │  6. Set tokenURI  │
└──────────────────┘                               └───────────────────┘
```

## Prerequisites

- **Node.js** 18+
- **Foundry** (forge, cast)
- **Docker** & Docker Compose
- Testnet AVAX (Fuji) and ETH (Arbitrum Sepolia) for gas
- Testnet LINK tokens on Avalanche Fuji for CCIP fees

## Deployer Address

```
0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
```

## Deployed Contract Addresses

| Chain | Contract | Address |
|---|---|---|
| Avalanche Fuji | CrossChainNFT | `0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8` |
| Avalanche Fuji | CCIPNFTBridge | `0x20ea0caf3e9940a2dfae87fc59c51fb4959ce797` |
| Arbitrum Sepolia | CrossChainNFT | `0x28d83b3c8f1a99a5ae5ae356dd64509e3dad73e8` |
| Arbitrum Sepolia | CCIPNFTBridge | `0x20ea0caf3e9940a2dfae87fc59c51fb4959ce797` |

## Test Token

**Token ID: 1** is pre-minted on Avalanche Fuji to the deployer address (`0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80`).

Token URI: `https://raw.githubusercontent.com/Rushikesh-5706/Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation/main/metadata/1.json`

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Rushikesh-5706/Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation.git
cd Chainlink-CCIP-Cross-Chain-NFT-Transfer-with-Metadata-Preservation
```

### 2. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 3. Install Foundry Dependencies

```bash
forge install
```

### 4. Configure Environment

```bash
cp .env.example .env
# Edit .env with your private key and RPC URLs
```

### 5. Build Contracts

```bash
forge build
```

### 6. Run Tests

```bash
forge test -vvv
```

### 7. Install Node.js Dependencies

```bash
npm install
```

## Deployment Instructions

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

After both deployments, add `FUJI_BRIDGE_ADDRESS` and `ARBITRUM_SEPOLIA_BRIDGE_ADDRESS` to your `.env`, then:

```bash
source .env
forge script script/Configure.s.sol --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy
forge script script/Configure.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## CLI Usage

Transfer an NFT from Avalanche Fuji to Arbitrum Sepolia:

```bash
npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=<DESTINATION_ADDRESS>
```

### Parameters

| Parameter | Description | Required |
|---|---|---|
| `--tokenId` | The token ID to transfer | Yes |
| `--from` | Source chain (`avalanche-fuji`) | Yes |
| `--to` | Destination chain (`arbitrum-sepolia`) | Yes |
| `--receiver` | Receiver address on destination chain | Yes |

### Example

```bash
npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
```

## Docker Usage

### Build and Start Container

```bash
docker-compose up -d --build
```

### Run Transfer Inside Container

```bash
docker exec ccip-nft-bridge-cli npm run transfer -- --tokenId=1 --from=avalanche-fuji --to=arbitrum-sepolia --receiver=0xE5c22fE12ecc70035C3B4e014e8cAdEF75782a80
```

### Push to Docker Hub

```bash
docker tag ccip-nft-bridge-cli rushi5706/ccip-nft-bridge-cli:latest
docker push rushi5706/ccip-nft-bridge-cli:latest
```

## Tracking Transfers

After a transfer is initiated, you can track its status on the CCIP Explorer:

```
https://ccip.chain.link/msg/<CCIP_MESSAGE_ID>
```

The CCIP message ID is displayed in the CLI output and saved to `data/nft_transfers.json`.

## Transfer Logs

- **Console & File:** `logs/transfers.log` — timestamped transfer operations log
- **JSON Records:** `data/nft_transfers.json` — structured transfer history with metadata

## Environment Variables

| Variable | Description |
|---|---|
| `PRIVATE_KEY` | Deployer wallet private key |
| `FUJI_RPC_URL` | Avalanche Fuji RPC endpoint |
| `ARBITRUM_SEPOLIA_RPC_URL` | Arbitrum Sepolia RPC endpoint |
| `CCIP_ROUTER_FUJI` | CCIP Router address on Fuji |
| `CCIP_ROUTER_ARBITRUM_SEPOLIA` | CCIP Router address on Arbitrum Sepolia |
| `LINK_TOKEN_FUJI` | LINK token address on Fuji |
| `LINK_TOKEN_ARBITRUM_SEPOLIA` | LINK token address on Arbitrum Sepolia |
| `FUJI_CHAIN_SELECTOR` | CCIP chain selector for Fuji |
| `ARBITRUM_SEPOLIA_CHAIN_SELECTOR` | CCIP chain selector for Arbitrum Sepolia |

## Project Structure

```
├── src/
│   ├── CrossChainNFT.sol          # ERC721 with bridge-restricted mint/burn
│   └── CCIPNFTBridge.sol          # CCIP bridge with burn-and-mint logic
├── script/
│   ├── DeployFuji.s.sol           # Fuji deployment script
│   ├── DeployArbitrumSepolia.s.sol # Arbitrum Sepolia deployment script
│   └── Configure.s.sol           # Trusted remote configuration
├── test/
│   ├── CrossChainNFTTest.t.sol    # NFT contract tests
│   └── CCIPNFTBridgeTest.t.sol    # Bridge contract tests
├── cli/
│   └── transfer.js               # Node.js CLI for cross-chain transfers
├── data/
│   └── nft_transfers.json         # Transfer records
├── logs/
│   └── transfers.log             # Transfer operation logs
├── metadata/
│   └── 1.json                    # NFT metadata for tokenId=1
├── deployment.json               # Deployed contract addresses
├── foundry.toml                  # Foundry configuration
├── package.json                  # Node.js dependencies
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Docker Compose setup
├── .env.example                  # Environment variable template
├── .dockerignore                 # Docker build exclusions
├── .gitignore                    # Git exclusions
└── README.md                     # This file
```

## License

MIT
