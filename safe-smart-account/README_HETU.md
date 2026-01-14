# Safe Wallet Deployment for Hetu Chain

Complete setup for deploying Safe v1.4.1 smart contracts to your Hetu blockchain.

## 📋 Overview

This repository contains everything you need to deploy Safe (formerly Gnosis Safe) multi-signature wallet contracts to your Hetu chain. Safe is the most trusted platform for managing digital assets on Ethereum and EVM-compatible chains.

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
yarn install
```

### Step 2: Configure Your Hetu Chain

Edit the `.env` file with your Hetu chain details:

```bash
# Your deployer private key (must have funds for gas)
PK="0xYOUR_PRIVATE_KEY_HERE"

# Your Hetu chain RPC endpoint
NODE_URL="http://your-hetu-rpc-url:8545"

# Your Hetu chain ID (optional, will auto-detect if not set)
CHAIN_ID="1234"
```

⚠️ **Security Warning**: Never commit your `.env` file with real private keys!

### Step 3: Deploy Safe Contracts

Run the deployment script:

```bash
chmod +x deploy-hetu.sh
./deploy-hetu.sh
```

Or manually:

```bash
yarn deploy-all custom
```

### Step 4: View Deployed Addresses

```bash
node get-addresses.js
```

## 📦 What Gets Deployed

The deployment includes all core Safe v1.4.1 contracts:

| Contract | Description |
|----------|-------------|
| **Safe** | Main Safe wallet logic (singleton) |
| **SafeProxyFactory** | Factory for creating new Safe instances |
| **CompatibilityFallbackHandler** | Handles compatibility and additional features |
| **MultiSend** | Batch multiple transactions |
| **MultiSendCallOnly** | Batch transactions (CALL only) |
| **SignMessageLib** | Enable message signing |
| **CreateCall** | Deploy contracts from Safe |
| **SimulateTxAccessor** | Simulate transactions |

## 📁 Project Structure

```
safe-deployment/
├── .env                          # Your Hetu chain configuration
├── deploy-hetu.sh               # Automated deployment script
├── get-addresses.js             # Extract deployed addresses
├── HETU_DEPLOYMENT_GUIDE.md     # Detailed deployment guide
├── README_HETU.md               # This file
├── contracts/                   # Safe smart contracts
├── src/deploy/                  # Deployment scripts
└── deployments/custom/          # Deployed contract addresses (after deployment)
```

## 🔧 Configuration Options

### Using Private Key (Recommended)

```bash
PK="0x1234567890abcdef..."
NODE_URL="http://localhost:8545"
```

### Using Mnemonic

```bash
MNEMONIC="word1 word2 word3 ... word12"
NODE_URL="http://localhost:8545"
```

### Custom Gas Settings

Edit `hardhat.config.ts` to adjust gas settings:

```typescript
custom: {
  url: NODE_URL,
  gasPrice: 20000000000,  // 20 gwei
  gas: 8000000,           // 8M gas limit
}
```

## 📝 Deployment Checklist

- [ ] Hetu chain is running and accessible
- [ ] Deployer account has sufficient funds for gas
- [ ] `.env` file is configured with correct values
- [ ] Dependencies are installed (`yarn install`)
- [ ] Run deployment: `./deploy-hetu.sh`
- [ ] Verify deployment: `node get-addresses.js`
- [ ] Save contract addresses for your application
- [ ] Test creating a Safe wallet

## 🧪 Testing Your Deployment

After deployment, you can create a test Safe wallet. See `HETU_DEPLOYMENT_GUIDE.md` for detailed examples.

Quick test using Hardhat console:

```bash
npx hardhat console --network custom
```

Then in the console:

```javascript
const SafeProxyFactory = await ethers.getContractAt(
  "SafeProxyFactory",
  "YOUR_FACTORY_ADDRESS"
);

// Create a Safe with 1 owner and threshold of 1
const [owner] = await ethers.getSigners();
const Safe = await ethers.getContractAt("Safe", "YOUR_SINGLETON_ADDRESS");

const setupData = Safe.interface.encodeFunctionData("setup", [
  [owner.address],  // owners
  1,                // threshold
  ethers.constants.AddressZero,
  "0x",
  ethers.constants.AddressZero,
  ethers.constants.AddressZero,
  0,
  ethers.constants.AddressZero,
]);

const tx = await SafeProxyFactory.createProxyWithNonce(
  "YOUR_SINGLETON_ADDRESS",
  setupData,
  Date.now()
);

const receipt = await tx.wait();
console.log("Safe created at:", receipt.events[0].args.proxy);
```

## 🔍 Verifying Deployment

Check that all contracts were deployed successfully:

```bash
node get-addresses.js
```

Expected output:
```
========================================
Safe Contracts Deployed on Hetu Chain
========================================

✅ Safe                              0x1234...
✅ SafeProxyFactory                  0x5678...
✅ CompatibilityFallbackHandler      0x9abc...
...
```

## 📚 Documentation

- **[HETU_DEPLOYMENT_GUIDE.md](./HETU_DEPLOYMENT_GUIDE.md)** - Comprehensive deployment guide
- **[Safe Documentation](https://docs.safe.global/)** - Official Safe documentation
- **[Safe Contracts GitHub](https://github.com/safe-global/safe-contracts)** - Source code

## 🛠️ Troubleshooting

### "Insufficient funds for gas"
Ensure your deployer account has enough native tokens on Hetu chain.

### "Network not found"
Verify `NODE_URL` in `.env` is correct and Hetu chain is running.

### "Deterministic deployment failed"
Hetu chain may not have the Singleton Factory. You may need to:
1. Deploy the factory first, or
2. Modify deployment scripts to skip deterministic deployment

### "Contract deployment failed"
1. Check Hetu chain logs for errors
2. Verify EVM compatibility
3. Adjust gas limits in `hardhat.config.ts`

## 🔐 Security Best Practices

1. **Never commit private keys** - Use `.gitignore` for `.env`
2. **Test on testnet first** - Before deploying to mainnet
3. **Verify contracts** - If block explorer is available
4. **Backup addresses** - Save all deployed contract addresses
5. **Limit access** - Restrict who has deployment keys

## 📞 Support

For issues specific to:
- **Safe Contracts**: [GitHub Issues](https://github.com/safe-global/safe-contracts/issues)
- **Hetu Chain**: Contact your Hetu chain administrator
- **This Deployment**: Check `HETU_DEPLOYMENT_GUIDE.md`

## 📄 License

Safe Contracts are licensed under LGPL-3.0

## 🎯 Next Steps

After successful deployment:

1. ✅ Save all contract addresses
2. ✅ Create a test Safe wallet
3. ✅ Integrate with your dApp/frontend
4. ✅ Set up Safe Transaction Service (optional)
5. ✅ Configure Safe web interface (optional)

---

**Need help?** See the detailed guide: [HETU_DEPLOYMENT_GUIDE.md](./HETU_DEPLOYMENT_GUIDE.md)
