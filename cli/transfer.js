#!/usr/bin/env node

const { ethers } = require('ethers');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const yargs = require('yargs');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '..', '.env') });

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message }) => {
      return `[${timestamp}] ${level.toUpperCase()}: ${message}`;
    })
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({
      filename: path.join(__dirname, '..', 'logs', 'transfers.log'),
    }),
  ],
});

// Chain configurations
const CHAIN_CONFIG = {
  'avalanche-fuji': {
    rpcUrl: process.env.FUJI_RPC_URL,
    chainSelector: process.env.FUJI_CHAIN_SELECTOR,
    linkToken: process.env.LINK_TOKEN_FUJI || '0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846',
  },
  'arbitrum-sepolia': {
    rpcUrl: process.env.ARBITRUM_SEPOLIA_RPC_URL,
    chainSelector: process.env.ARBITRUM_SEPOLIA_CHAIN_SELECTOR,
    linkToken: process.env.LINK_TOKEN_ARBITRUM_SEPOLIA || '0xb1D4538B4571d411F07960EF2838Ce337FE1E80E',
  },
};

// Minimal ERC20 ABI for LINK token operations
const ERC20_ABI = [
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function balanceOf(address account) external view returns (uint256)',
  'function allowance(address owner, address spender) external view returns (uint256)',
  'function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)'
];

// Parse CLI arguments
const argv = yargs
  .usage('Usage: npm run transfer -- --tokenId=<id> --from=<chain> --to=<chain> --receiver=<address>')
  .option('tokenId', {
    describe: 'Token ID to transfer',
    type: 'number',
    demandOption: true,
  })
  .option('from', {
    describe: 'Source chain (avalanche-fuji)',
    type: 'string',
    demandOption: true,
    choices: ['avalanche-fuji'],
  })
  .option('to', {
    describe: 'Destination chain (arbitrum-sepolia)',
    type: 'string',
    demandOption: true,
    choices: ['arbitrum-sepolia'],
  })
  .option('receiver', {
    describe: 'Receiver address on destination chain',
    type: 'string',
    demandOption: true,
  })
  .check((argv) => {
    if (!ethers.isAddress(argv.receiver)) {
      throw new Error(`Invalid receiver address: ${argv.receiver}`);
    }
    if (!Number.isInteger(argv.tokenId) || argv.tokenId < 0) {
      throw new Error(`Invalid tokenId: ${argv.tokenId}`);
    }
    return true;
  })
  .strict()
  .help()
  .parseSync();

async function main() {
  const { tokenId, from: sourceChain, to: destChain, receiver } = argv;

  logger.info(`Transfer started: tokenId=${tokenId} from=${sourceChain} to=${destChain} receiver=${receiver}`);

  // Load deployment.json
  const deploymentPath = path.join(__dirname, '..', 'deployment.json');
  if (!fs.existsSync(deploymentPath)) {
    logger.error('deployment.json not found. Please deploy contracts first.');
    process.exit(1);
  }
  const deployment = JSON.parse(fs.readFileSync(deploymentPath, 'utf-8'));

  // Determine chain keys in deployment.json
  const chainKeyMap = {
    'avalanche-fuji': 'avalancheFuji',
    'arbitrum-sepolia': 'arbitrumSepolia',
  };

  const sourceDeployment = deployment[chainKeyMap[sourceChain]];
  const sourceConfig = CHAIN_CONFIG[sourceChain];
  const destConfig = CHAIN_CONFIG[destChain];

  if (!sourceDeployment) {
    logger.error(`No deployment found for chain: ${sourceChain}`);
    process.exit(1);
  }

  // Load ABIs from Foundry compiled output
  const bridgeArtifactPath = path.join(__dirname, 'abis', 'CCIPNFTBridge.json');
  const nftArtifactPath = path.join(__dirname, 'abis', 'CrossChainNFT.json');

  if (!fs.existsSync(bridgeArtifactPath) || !fs.existsSync(nftArtifactPath)) {
    logger.error('ABI files not found in cli/abis/. Repository may be corrupted.');
    process.exit(1);
  }

  const bridgeAbi = JSON.parse(fs.readFileSync(bridgeArtifactPath, 'utf-8')).abi;
  const nftAbi = JSON.parse(fs.readFileSync(nftArtifactPath, 'utf-8')).abi;

  // Connect to source chain
  let provider;
  try {
    provider = new ethers.JsonRpcProvider(sourceConfig.rpcUrl);
    await provider.getBlockNumber();
  } catch (err) {
    logger.error(`Could not connect to RPC: ${sourceConfig.rpcUrl}`);
    process.exit(1);
  }

  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  logger.info(`Connected as: ${wallet.address}`);

  // Instantiate contracts
  const bridgeContract = new ethers.Contract(sourceDeployment.bridgeContractAddress, bridgeAbi, wallet);
  const nftContract = new ethers.Contract(sourceDeployment.nftContractAddress, nftAbi, wallet);
  const linkContract = new ethers.Contract(sourceConfig.linkToken, ERC20_ABI, wallet);

  // Verify token exists and caller owns it
  let tokenOwner;
  try {
    tokenOwner = await nftContract.ownerOf(tokenId);
  } catch (err) {
    logger.error(`Token #${tokenId} does not exist on source chain`);
    process.exit(1);
  }

  if (tokenOwner.toLowerCase() !== wallet.address.toLowerCase()) {
    logger.error(`Wallet does not own token #${tokenId}. Owner: ${tokenOwner}`);
    process.exit(1);
  }

  // Get tokenURI for metadata
  let tokenURI;
  try {
    tokenURI = await nftContract.tokenURI(tokenId);
  } catch (err) {
    tokenURI = '';
  }

  // Fetch metadata if possible
  let metadata = {
    name: `CrossChainNFT #${tokenId}`,
    description: '',
    image: '',
  };
  if (tokenURI) {
    try {
      const response = await fetch(tokenURI);
      if (response.ok) {
        const metadataJson = await response.json();
        metadata.name = metadataJson.name || metadata.name;
        metadata.description = metadataJson.description || metadata.description;
        metadata.image = metadataJson.image || metadata.image;
      }
    } catch (err) {
      logger.info(`Could not fetch metadata from tokenURI, using defaults`);
    }
  }

  const destinationChainSelector = destConfig.chainSelector;

  // Estimate LINK fee
  let fee;
  try {
    fee = await bridgeContract.estimateTransferCost(BigInt(destinationChainSelector));
    logger.info(`Estimated CCIP fee: ${ethers.formatEther(fee)} LINK`);
  } catch (err) {
    logger.error(`Failed to estimate transfer cost: ${err.message}`);
    process.exit(1);
  }

  // Check LINK balance
  const linkBalance = await linkContract.balanceOf(wallet.address);
  const feeWithBuffer = (fee * 110n) / 100n;

  if (linkBalance < feeWithBuffer) {
    logger.error(
      `Insufficient LINK. Need: ${ethers.formatEther(feeWithBuffer)} LINK. Have: ${ethers.formatEther(linkBalance)} LINK`
    );
    process.exit(1);
  }

  // Approve LINK for bridge
  logger.info('Approving LINK token for bridge...');
  try {
    const approveLinkTx = await linkContract.approve(sourceDeployment.bridgeContractAddress, feeWithBuffer);
    await approveLinkTx.wait();
    logger.info(`LINK approval tx: ${approveLinkTx.hash}`);
  } catch (err) {
    logger.error(`LINK approval failed: ${err.message}`);
    process.exit(1);
  }

  // Approve NFT for bridge
  logger.info('Approving NFT for bridge...');
  try {
    const approveNftTx = await nftContract.approve(sourceDeployment.bridgeContractAddress, tokenId);
    await approveNftTx.wait();
    logger.info(`NFT approval tx: ${approveNftTx.hash}`);
  } catch (err) {
    logger.error(`NFT approval failed: ${err.message}`);
    process.exit(1);
  }

  // Execute transfer
  logger.info('Sending NFT via CCIP...');
  let receipt;
  let txHash;
  try {
    const sendTx = await bridgeContract.sendNFT(BigInt(destinationChainSelector), receiver, tokenId);
    receipt = await sendTx.wait();
    txHash = receipt.hash;
    logger.info(`SOURCE TX HASH: ${txHash}`);
  } catch (err) {
    logger.error(`Transfer failed: ${err.reason || err.message}`);
    if (err.data) {
      logger.error(`Revert data: ${err.data}`);
    }
    process.exit(1);
  }

  // Extract CCIP message ID from NFTSent event
  let ccipMessageId = null;
  try {
    const nftSentEvent = receipt.logs
      .map((log) => {
        try {
          return bridgeContract.interface.parseLog({ topics: log.topics, data: log.data });
        } catch {
          return null;
        }
      })
      .find((parsed) => parsed && parsed.name === 'NFTSent');

    if (nftSentEvent) {
      ccipMessageId = nftSentEvent.args.messageId || nftSentEvent.args[0];
    }
  } catch (err) {
    logger.info(`Could not parse NFTSent event: ${err.message}`);
  }

  if (ccipMessageId) {
    logger.info(`CCIP MESSAGE ID: ${ccipMessageId}`);
    logger.info(`Transfer initiated successfully. Track at: https://ccip.chain.link/msg/${ccipMessageId}`);
  } else {
    logger.info('Transfer initiated but could not extract CCIP message ID from logs');
  }

  // Save to data/nft_transfers.json
  const transfersPath = path.join(__dirname, '..', 'data', 'nft_transfers.json');
  let transfers = [];
  try {
    const existing = fs.readFileSync(transfersPath, 'utf-8');
    transfers = JSON.parse(existing);
  } catch {
    transfers = [];
  }

  const transferEntry = {
    transferId: uuidv4(),
    tokenId: String(tokenId),
    sourceChain: sourceChain,
    destinationChain: destChain,
    sender: wallet.address,
    receiver: receiver,
    ccipMessageId: ccipMessageId || null,
    sourceTxHash: txHash,
    destinationTxHash: null,
    status: 'initiated',
    metadata: metadata,
    timestamp: new Date().toISOString(),
  };

  transfers.push(transferEntry);
  fs.writeFileSync(transfersPath, JSON.stringify(transfers, null, 2));
  logger.info('Transfer record saved to data/nft_transfers.json');
}

main().catch((err) => {
  logger.error(`Unexpected error: ${err.message}`);
  logger.error(err.stack);
  process.exit(1);
});
