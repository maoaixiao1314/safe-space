/**
 * Deploy Safe Proxy with SafeL2 Singleton
 * 
 * This script deploys a new Safe proxy using SafeL2 singleton for L2 mode compatibility.
 * SafeL2 emits SafeMultiSigTransaction events which are properly indexed in L2 mode.
 * 
 * Usage:
 *   PRIVATE_KEY=0x... node scripts/deploy-safe-l2.js
 */

const { ethers } = require('hardhat');

// Contract addresses on Hetu chain (with proper checksums)
const SAFE_L2_ADDRESS = '0x0c61A6cfC69Ea0E3A031D81A80331f8DDbaE9f33';
const PROXY_FACTORY = '0x8F5c50f13daaF6C8c8BC2C1Ab7Bc1BA0d34c2e32';

async function main() {
  console.log('==================================================');
  console.log('Deploy Safe Proxy with SafeL2 Singleton');
  console.log('==================================================\n');

  // Get signer
  const [deployer] = await ethers.getSigners();
  console.log('Deployer address:', deployer.address);

  // Check balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log('Balance:', ethers.utils.formatEther(balance), 'HETU');

  if (balance.isZero()) {
    console.error('\n❌ Error: Deployer has no balance');
    console.log('\nPlease fund the account first:');
    console.log(`Address: ${deployer.address}`);
    process.exit(1);
  }

  console.log('\nConfiguration:');
  console.log('- SafeL2 Singleton:', SAFE_L2_ADDRESS);
  console.log('- ProxyFactory:', PROXY_FACTORY);
  console.log('- Network:', (await ethers.provider.getNetwork()).name);
  console.log('- ChainId:', (await ethers.provider.getNetwork()).chainId);

  // Safe configuration
  const owners = [deployer.address];
  const threshold = 1;

  console.log('\nSafe Configuration:');
  console.log('- Owners:', owners);
  console.log('- Threshold:', threshold);

  // Generate salt (random)
  const salt = ethers.utils.randomBytes(32);
  console.log('- Salt:', ethers.utils.hexlify(salt));

  // Encode setup() parameters
  const setupData = ethers.utils.defaultAbiCoder.encode(
    ['address[]', 'uint256', 'address', 'bytes', 'address', 'address', 'uint256', 'address'],
    [
      owners,
      threshold,
      ethers.constants.AddressZero,  // to
      '0x',                            // data
      ethers.constants.AddressZero,  // fallbackHandler
      ethers.constants.AddressZero,  // paymentToken
      0,                              // payment
      ethers.constants.AddressZero   // paymentReceiver
    ]
  );

  // Get ProxyFactory contract
  const proxyFactoryAbi = [
    'function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce) public returns (address proxy)',
    'event ProxyCreation(address indexed proxy, address singleton)'
  ];
  const proxyFactory = new ethers.Contract(PROXY_FACTORY, proxyFactoryAbi, deployer);

  console.log('\n🚀 Deploying Safe proxy...');

  // Deploy
  const tx = await proxyFactory.createProxyWithNonce(
    SAFE_L2_ADDRESS,
    setupData,
    ethers.BigNumber.from(salt)
  );

  console.log('Transaction hash:', tx.hash);
  console.log('Waiting for confirmation...');

  const receipt = await tx.wait();
  console.log('✅ Transaction confirmed in block', receipt.blockNumber);

  // Get Safe address from ProxyCreation event
  const proxyCreationEvent = receipt.events?.find(e => e.event === 'ProxyCreation');
  const safeAddress = proxyCreationEvent?.args?.proxy;

  console.log('\n==================================================');
  console.log('✅ Safe Deployed Successfully!');
  console.log('==================================================\n');
  console.log('Safe Address:', safeAddress);
  console.log('Master Copy:', SAFE_L2_ADDRESS, '(SafeL2)');
  console.log('Owner:', deployer.address);
  console.log('Threshold:', threshold);
  console.log('\nTransaction:', tx.hash);
  console.log('Explorer: https://explorer.hetu.io/tx/' + tx.hash);

  console.log('\n==================================================');
  console.log('Next Steps:');
  console.log('==================================================\n');
  console.log('1. Verify Safe in Transaction Service:');
  console.log(`   curl http://localhost:8000/api/v1/safes/${safeAddress}/`);
  console.log('\n2. Update Safe Web configuration:');
  console.log('   Edit apps/web/src/hooks/coreSDK/safeCoreSDK.ts');
  console.log(`   Use Safe address: ${safeAddress}`);
  console.log('\n3. Transfer funds from old Safe:');
  console.log('   Old Safe: 0x3DEC5f5745630F0441E296d8E2870c69bfA1430C');
  console.log(`   New Safe: ${safeAddress}`);
  console.log('\n4. Test transaction creation:');
  console.log('   - Create transaction in Safe Web');
  console.log('   - Execute transaction');
  console.log('   - Verify SafeMultiSigTransaction event is emitted');
  console.log('   - Check ethereum_tx_id is updated in database');
  console.log('\n');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
