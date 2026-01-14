# Safe Wallet Deployment Guide for Hetu Chain

This guide will help you deploy Safe v1.4.1 smart contracts to your Hetu chain.

## Prerequisites

- Node.js and Yarn installed
- A funded account on Hetu chain (for gas fees)
- Hetu chain RPC endpoint
- Hetu chain ID

## Quick Start

### 1. Configure Environment Variables

Edit the `.env` file with your Hetu chain details:

```bash
# Your private key (IMPORTANT: Keep this secure!)
PK="0x1234567890abcdef..."

# Your Hetu chain RPC endpoint
NODE_URL="http://your-hetu-rpc:8545"

# Your Hetu chain ID
CHAIN_ID="1234"
```

**Security Note**: Never commit your `.env` file with real private keys to version control!

### 2. Run the Deployment Script

Make the script executable and run it:

```bash
chmod +x deploy-hetu.sh
./deploy-hetu.sh
```

Or deploy manually:

```bash
yarn deploy-all custom
```

### 3. Verify Deployment

After deployment, check the `deployments/custom/` directory for contract addresses.

## What Gets Deployed

The deployment will create the following contracts on your Hetu chain:

### Core Contracts

1. **Safe Singleton** (`Safe.sol`)
   - The main Safe wallet logic contract
   - All Safe proxies delegate calls to this contract

2. **Safe Proxy Factory** (`SafeProxyFactory.sol`)
   - Factory contract for creating new Safe wallet instances
   - Uses CREATE2 for deterministic addresses

3. **Compatibility Fallback Handler** (`CompatibilityFallbackHandler.sol`)
   - Handles compatibility with older Safe versions
   - Provides additional functionality for Safe wallets

### Libraries and Utilities

4. **Multi-Send** (`MultiSend.sol`)
   - Allows batching multiple transactions into one
   - Useful for complex operations

5. **Multi-Send Call Only** (`MultiSendCallOnly.sol`)
   - Similar to MultiSend but only allows CALL operations (no DELEGATECALL)
   - More secure for certain use cases

6. **Sign Message Library** (`SignMessageLib.sol`)
   - Allows Safe wallets to sign messages
   - Useful for off-chain signatures

7. **Create Call** (`CreateCall.sol`)
   - Allows Safe wallets to deploy new contracts
   - Uses CREATE or CREATE2

## Manual Deployment Steps

If you prefer to deploy step by step:

### Step 1: Set up environment

```bash
cd safe-deployment
yarn install
```

### Step 2: Configure your network

Edit `.env` file with your Hetu chain configuration.

### Step 3: Deploy contracts

```bash
# Deploy all contracts
yarn deploy-all custom

# Or deploy specific contracts
yarn deploy --network custom --tags singleton
yarn deploy --network custom --tags factory
yarn deploy --network custom --tags libraries
```

## Testing Your Deployment

### Create a Test Safe Wallet

After deployment, you can create a test Safe wallet using the deployed contracts:

```javascript
// Example using ethers.js
const { ethers } = require("ethers");

// Connect to Hetu chain
const provider = new ethers.providers.JsonRpcProvider("YOUR_HETU_RPC_URL");
const wallet = new ethers.Wallet("YOUR_PRIVATE_KEY", provider);

// Load deployed contract addresses from deployments/custom/
const SafeProxyFactory = await ethers.getContractAt(
  "SafeProxyFactory",
  "DEPLOYED_FACTORY_ADDRESS",
  wallet
);

// Create a new Safe
const owners = ["0xOwner1Address", "0xOwner2Address"];
const threshold = 2; // Require 2 signatures

// Setup data for Safe initialization
const Safe = await ethers.getContractAt("Safe", "DEPLOYED_SINGLETON_ADDRESS");
const setupData = Safe.interface.encodeFunctionData("setup", [
  owners,
  threshold,
  ethers.constants.AddressZero,
  "0x",
  ethers.constants.AddressZero,
  ethers.constants.AddressZero,
  0,
  ethers.constants.AddressZero,
]);

// Deploy Safe proxy
const tx = await SafeProxyFactory.createProxyWithNonce(
  "DEPLOYED_SINGLETON_ADDRESS",
  setupData,
  Date.now()
);

const receipt = await tx.wait();
console.log("Safe created at:", receipt.events[0].args.proxy);
```

## Contract Addresses

After deployment, you'll find all contract addresses in:

```
deployments/custom/
├── Safe.json
├── SafeProxyFactory.json
├── CompatibilityFallbackHandler.json
├── MultiSend.json
├── MultiSendCallOnly.json
├── SignMessageLib.json
└── CreateCall.json
```

Each JSON file contains:
- Contract address
- ABI (Application Binary Interface)
- Deployment transaction hash
- Constructor arguments

## Troubleshooting

### Issue: "Insufficient funds for gas"

**Solution**: Ensure your deployer account has enough native tokens on Hetu chain.

### Issue: "Network not found"

**Solution**: Verify your `NODE_URL` in `.env` is correct and the Hetu chain is running.

### Issue: "Nonce too low"

**Solution**: The account may have pending transactions. Wait for them to complete or reset the nonce.

### Issue: "Contract deployment failed"

**Solution**: 
1. Check gas limits in `hardhat.config.ts`
2. Verify your Hetu chain supports the required EVM opcodes
3. Check Hetu chain logs for more details

## Advanced Configuration

### Custom Gas Settings

If you need to adjust gas settings for Hetu chain, edit `hardhat.config.ts`:

```typescript
networks: {
  custom: {
    ...sharedNetworkConfig,
    url: NODE_URL,
    gasPrice: 20000000000, // 20 gwei
    gas: 8000000, // 8M gas limit
  }
}
```

### Deterministic Deployment

Safe uses deterministic deployment via the Singleton Factory. If your Hetu chain doesn't have the factory deployed, you may need to:

1. Deploy the Singleton Factory first
2. Or modify the deployment scripts to skip deterministic deployment

## Integration with Safe Web Interface

To use the Safe web interface with your Hetu chain deployment:

1. Fork the Safe web app: https://github.com/safe-global/safe-wallet-web
2. Add Hetu chain configuration
3. Update contract addresses to match your deployment
4. Deploy your custom Safe web interface

## Security Considerations

1. **Private Key Security**: Never expose your private keys
2. **Test First**: Deploy to a testnet before mainnet
3. **Verify Contracts**: If possible, verify contracts on a block explorer
4. **Audit**: Consider auditing any modifications to the contracts
5. **Access Control**: Limit who has access to deployment keys

## Support and Resources

- Safe Contracts Documentation: https://docs.safe.global/
- Safe Contracts GitHub: https://github.com/safe-global/safe-contracts
- Safe Developer Portal: https://docs.safe.global/safe-core-aa-sdk/protocol-kit

## Next Steps

After successful deployment:

1. ✅ Document all deployed contract addresses
2. ✅ Create a test Safe wallet to verify functionality
3. ✅ Set up monitoring for your Safe contracts
4. ✅ Configure your frontend/dApp to use the deployed contracts
5. ✅ Consider setting up a Safe Transaction Service for better UX

## License

Safe Contracts are licensed under LGPL-3.0
