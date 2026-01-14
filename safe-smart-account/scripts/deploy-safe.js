/* eslint-disable @typescript-eslint/no-var-requires */
/* eslint-disable no-console */
// Direct deployment script for Safe contracts on Hetu chain
// This bypasses hardhat-deploy to avoid CREATE2 deployer issues

const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    console.log("\n==========================================");
    console.log("Safe Wallet Direct Deployment");
    console.log("==========================================\n");

    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString(), "\n");

    const deployments = {};
    const deploymentsDir = path.join(__dirname, "..", "deployments", "custom");

    // Create deployments directory
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    // Deploy Safe Singleton
    console.log("1. Deploying Safe Singleton...");
    const Safe = await hre.ethers.getContractFactory("Safe");
    const safe = await Safe.deploy();
    await safe.deployed();
    console.log("   ✅ Safe deployed to:", safe.address);
    deployments.Safe = safe.address;
    saveDeployment("Safe", safe.address, Safe.interface, deploymentsDir);

    // Deploy SafeL2
    console.log("\n2. Deploying SafeL2...");
    const SafeL2 = await hre.ethers.getContractFactory("SafeL2");
    const safeL2 = await SafeL2.deploy();
    await safeL2.deployed();
    console.log("   ✅ SafeL2 deployed to:", safeL2.address);
    deployments.SafeL2 = safeL2.address;
    saveDeployment("SafeL2", safeL2.address, SafeL2.interface, deploymentsDir);

    // Deploy SafeProxyFactory
    console.log("\n3. Deploying SafeProxyFactory...");
    const SafeProxyFactory = await hre.ethers.getContractFactory("SafeProxyFactory");
    const safeProxyFactory = await SafeProxyFactory.deploy();
    await safeProxyFactory.deployed();
    console.log("   ✅ SafeProxyFactory deployed to:", safeProxyFactory.address);
    deployments.SafeProxyFactory = safeProxyFactory.address;
    saveDeployment("SafeProxyFactory", safeProxyFactory.address, SafeProxyFactory.interface, deploymentsDir);

    // Deploy CompatibilityFallbackHandler
    console.log("\n4. Deploying CompatibilityFallbackHandler...");
    const CompatibilityFallbackHandler = await hre.ethers.getContractFactory("CompatibilityFallbackHandler");
    const compatibilityFallbackHandler = await CompatibilityFallbackHandler.deploy();
    await compatibilityFallbackHandler.deployed();
    console.log("   ✅ CompatibilityFallbackHandler deployed to:", compatibilityFallbackHandler.address);
    deployments.CompatibilityFallbackHandler = compatibilityFallbackHandler.address;
    saveDeployment("CompatibilityFallbackHandler", compatibilityFallbackHandler.address, CompatibilityFallbackHandler.interface, deploymentsDir);

    // Deploy MultiSend
    console.log("\n5. Deploying MultiSend...");
    const MultiSend = await hre.ethers.getContractFactory("MultiSend");
    const multiSend = await MultiSend.deploy();
    await multiSend.deployed();
    console.log("   ✅ MultiSend deployed to:", multiSend.address);
    deployments.MultiSend = multiSend.address;
    saveDeployment("MultiSend", multiSend.address, MultiSend.interface, deploymentsDir);

    // Deploy MultiSendCallOnly
    console.log("\n6. Deploying MultiSendCallOnly...");
    const MultiSendCallOnly = await hre.ethers.getContractFactory("MultiSendCallOnly");
    const multiSendCallOnly = await MultiSendCallOnly.deploy();
    await multiSendCallOnly.deployed();
    console.log("   ✅ MultiSendCallOnly deployed to:", multiSendCallOnly.address);
    deployments.MultiSendCallOnly = multiSendCallOnly.address;
    saveDeployment("MultiSendCallOnly", multiSendCallOnly.address, MultiSendCallOnly.interface, deploymentsDir);

    // Deploy SignMessageLib
    console.log("\n7. Deploying SignMessageLib...");
    const SignMessageLib = await hre.ethers.getContractFactory("SignMessageLib");
    const signMessageLib = await SignMessageLib.deploy();
    await signMessageLib.deployed();
    console.log("   ✅ SignMessageLib deployed to:", signMessageLib.address);
    deployments.SignMessageLib = signMessageLib.address;
    saveDeployment("SignMessageLib", signMessageLib.address, SignMessageLib.interface, deploymentsDir);

    // Deploy CreateCall
    console.log("\n8. Deploying CreateCall...");
    const CreateCall = await hre.ethers.getContractFactory("CreateCall");
    const createCall = await CreateCall.deploy();
    await createCall.deployed();
    console.log("   ✅ CreateCall deployed to:", createCall.address);
    deployments.CreateCall = createCall.address;
    saveDeployment("CreateCall", createCall.address, CreateCall.interface, deploymentsDir);

    // Deploy SimulateTxAccessor
    console.log("\n9. Deploying SimulateTxAccessor...");
    const SimulateTxAccessor = await hre.ethers.getContractFactory("SimulateTxAccessor");
    const simulateTxAccessor = await SimulateTxAccessor.deploy();
    await simulateTxAccessor.deployed();
    console.log("   ✅ SimulateTxAccessor deployed to:", simulateTxAccessor.address);
    deployments.SimulateTxAccessor = simulateTxAccessor.address;
    saveDeployment("SimulateTxAccessor", simulateTxAccessor.address, SimulateTxAccessor.interface, deploymentsDir);

    // Save summary
    const summaryPath = path.join(__dirname, "..", "hetu-safe-addresses.json");
    fs.writeFileSync(summaryPath, JSON.stringify(deployments, null, 2));

    console.log("\n==========================================");
    console.log("Deployment Complete!");
    console.log("==========================================\n");
    console.log("All contracts deployed successfully!");
    console.log("Addresses saved to:", summaryPath);
    console.log("\nRun 'node get-addresses.js' to view all addresses\n");
}

function saveDeployment(name, address, contractInterface, deploymentsDir) {
    const deployment = {
        address: address,
        abi: contractInterface.format("json"),
    };
    const filePath = path.join(deploymentsDir, `${name}.json`);
    fs.writeFileSync(filePath, JSON.stringify(deployment, null, 2));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
