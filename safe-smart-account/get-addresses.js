/* eslint-disable @typescript-eslint/no-var-requires */
/* eslint-disable no-console */
// Script to extract and display deployed Safe contract addresses
const fs = require("fs");
const path = require("path");

const DEPLOYMENTS_DIR = path.join(__dirname, "deployments", "custom");

const contracts = [
    "Safe",
    "SafeL2",
    "SafeProxyFactory",
    "CompatibilityFallbackHandler",
    "MultiSend",
    "MultiSendCallOnly",
    "SignMessageLib",
    "CreateCall",
    "SimulateTxAccessor",
];

console.log("\n========================================");
console.log("Safe Contracts Deployment Summary");
console.log("========================================\n");

// Try to read from hetu-safe-addresses.json first
const summaryFile = path.join(__dirname, "hetu-safe-addresses.json");
if (fs.existsSync(summaryFile)) {
    console.log("📋 Reading from: hetu-safe-addresses.json");
    try {
        const savedAddresses = JSON.parse(fs.readFileSync(summaryFile, "utf8"));
        console.log("\n✅ Deployed Contracts:\n");
        Object.entries(savedAddresses).forEach(([name, address]) => {
            console.log(`  ${name.padEnd(35)} ${address}`);
        });
        
        // Display additional info
        displayQuickReference(savedAddresses);
        displayNextSteps(savedAddresses);
        process.exit(0);
    } catch (error) {
        console.log("⚠️  Error reading summary file, checking deployments directory...\n");
    }
}

if (!fs.existsSync(DEPLOYMENTS_DIR)) {
    console.error("❌ Error: No deployment found!");
    console.error("\nPlease run deployment first:");
    console.error("  ./deploy-production.sh");
    console.error("  or");
    console.error("  ./deploy-direct.sh");
    process.exit(1);
}

const addresses = {};
let foundContracts = 0;

contracts.forEach((contractName) => {
    const filePath = path.join(DEPLOYMENTS_DIR, `${contractName}.json`);

    if (fs.existsSync(filePath)) {
        try {
            const data = JSON.parse(fs.readFileSync(filePath, "utf8"));
            addresses[contractName] = data.address;
            console.log(`✅ ${contractName.padEnd(35)} ${data.address}`);
            foundContracts++;
        } catch (error) {
            console.log(`❌ ${contractName.padEnd(35)} Error reading file`);
        }
    } else {
        console.log(`⚠️  ${contractName.padEnd(35)} Not deployed`);
    }
});

console.log("\n========================================");
console.log(`Total contracts deployed: ${foundContracts}/${contracts.length}`);
console.log("========================================\n");

// Save addresses to a JSON file for easy reference
const outputFile = path.join(__dirname, "hetu-safe-addresses.json");
fs.writeFileSync(outputFile, JSON.stringify(addresses, null, 2));
console.log(`\n💾 Contract addresses saved to: ${outputFile}\n`);

// Display quick reference and next steps
displayQuickReference(addresses);
displayNextSteps(addresses);

// Helper function to display quick reference
function displayQuickReference(addresses) {
    console.log("\n========================================");
    console.log("📋 Quick Reference");
    console.log("========================================\n");

    if (addresses.Safe) {
        console.log("🔷 Safe (L1 Singleton):");
        console.log(`   ${addresses.Safe}`);
        console.log("   Use for: Ethereum mainnet and L1 chains\n");
    }

    if (addresses.SafeL2) {
        console.log("🔶 SafeL2 (L2 Singleton):");
        console.log(`   ${addresses.SafeL2}`);
        console.log("   Use for: L2 chains (Polygon, Arbitrum, Hetu, etc.)");
        console.log("   ⚠️  Must be registered in Transaction Service!\n");
    }

    if (addresses.SafeProxyFactory) {
        console.log("🏭 SafeProxyFactory:");
        console.log(`   ${addresses.SafeProxyFactory}`);
        console.log("   Use for: Creating new Safe wallets\n");
    }

    if (addresses.CompatibilityFallbackHandler) {
        console.log("🔌 CompatibilityFallbackHandler:");
        console.log(`   ${addresses.CompatibilityFallbackHandler}\n`);
    }

    if (addresses.MultiSend) {
        console.log("📦 MultiSend:");
        console.log(`   ${addresses.MultiSend}\n`);
    }

    if (addresses.MultiSendCallOnly) {
        console.log("📦 MultiSendCallOnly:");
        console.log(`   ${addresses.MultiSendCallOnly}\n`);
    }
}

// Helper function to display next steps
function displayNextSteps(addresses) {
    console.log("========================================");
    console.log("🚀 Next Steps");
    console.log("========================================\n");

    if (!addresses.SafeL2 && !addresses.Safe) {
        console.log("⚠️  No Safe singleton deployed!");
        console.log("   Run: ./deploy-production.sh\n");
        return;
    }

    console.log("1️⃣  Start backend services (if not already running):");
    console.log("   cd ../safe-deploy-guide/scripts");
    console.log("   ./start-safe-services.sh\n");

    console.log("2️⃣  Add chain configuration:");
    console.log("   ./add-hetu-chain.sh\n");

    console.log("3️⃣  Update contract addresses:");
    console.log("   vim update-contract-addresses.sh");
    console.log("   # Replace contract addresses with:");
    if (addresses.SafeL2) {
        console.log(`   SAFE_L2="${addresses.SafeL2.replace('0x', '')}"`);
    }
    if (addresses.SafeProxyFactory) {
        console.log(`   SAFE_PROXY_FACTORY="${addresses.SafeProxyFactory.replace('0x', '')}"`);
    }
    console.log("   # ... (other addresses)");
    console.log("   ./update-contract-addresses.sh\n");

    console.log("4️⃣  Update Safe Web SDK configuration:");
    console.log("   Edit: safe-wallet-web/apps/web/src/hooks/coreSDK/safeCoreSDK.ts");
    console.log("   Update contractNetworks with these addresses\n");

    console.log("5️⃣  Create your first Safe:");
    console.log("   npx hardhat run scripts/create-safe-proxy.js --network your_network\n");

    console.log("6️⃣  Verify deployment:");
    console.log("   ./verify-deployment.sh\n");

    console.log("========================================");
    console.log("📚 Documentation");
    console.log("========================================\n");
    console.log("  - Full guide: PRODUCTION_DEPLOYMENT_GUIDE.md");
    console.log("  - Quick ref: QUICK_REFERENCE.md");
    console.log("  - Flow: DEPLOYMENT_FLOW_SUMMARY.md");
    console.log("  - Use correct Safe: ../USE_CORRECT_SAFE.md\n");
}
