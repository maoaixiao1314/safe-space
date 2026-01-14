const { ethers } = require('hardhat');

async function main() {
  console.log('Creating Safe with SafeL2 singleton...\n');

  const [deployer] = await ethers.getSigners();
  console.log('Deployer:', deployer.address);

  // Contract addresses
  const SAFE_L2 = '0xA9a2Fd746af6Db05B659Df146235D2E60413D166';
  const PROXY_FACTORY = '0x0db4Db2f66Be999DB9756589A54c4625fF6E7128';

  // Safe configuration
  const owners = [deployer.address];
  const threshold = 1;

  console.log('Configuration:');
  console.log('- Owner:', owners[0]);
  console.log('- Threshold:', threshold);
  console.log('- SafeL2:', SAFE_L2);
  console.log('');

  // Get SafeL2 contract to encode setup
  const safeL2 = await ethers.getContractAt('SafeL2', SAFE_L2);
  
  // Encode setup call
  const setupData = safeL2.interface.encodeFunctionData('setup', [
    owners,
    threshold,
    ethers.constants.AddressZero,
    '0x',
    ethers.constants.AddressZero,
    ethers.constants.AddressZero,
    0,
    ethers.constants.AddressZero,
  ]);

  console.log('Setup data:', setupData);
  console.log('');

  // Get ProxyFactory contract
  const proxyFactory = await ethers.getContractAt('SafeProxyFactory', PROXY_FACTORY);

  // Generate salt
  const salt = ethers.utils.randomBytes(32);
  console.log('Salt:', ethers.utils.hexlify(salt));
  console.log('');

  // Create proxy
  console.log('Creating Safe proxy...');
  const tx = await proxyFactory.createProxyWithNonce(
    SAFE_L2,
    setupData,
    ethers.BigNumber.from(salt)
  );

  console.log('Transaction hash:', tx.hash);
  console.log('Waiting for confirmation...');

  const receipt = await tx.wait();
  console.log('✅ Confirmed in block', receipt.blockNumber);

  // Get Safe address from event
  const event = receipt.events?.find(e => e.event === 'ProxyCreation');
  const safeAddress = event?.args?.proxy;

  console.log('');
  console.log('========================================');
  console.log('✅ Safe Created Successfully!');
  console.log('========================================');
  console.log('');
  console.log('Safe Address:', safeAddress);
  console.log('Master Copy:', SAFE_L2, '(SafeL2)');
  console.log('Owner:', deployer.address);
  console.log('Threshold:', threshold);
  console.log('');

  // Verify setup
  const safe = await ethers.getContractAt('Safe', safeAddress);
  const actualOwners = await safe.getOwners();
  const actualThreshold = await safe.getThreshold();

  console.log('Verification:');
  console.log('- Owners:', actualOwners);
  console.log('- Threshold:', actualThreshold.toString());
  console.log('');

  // Save to file
  const fs = require('fs');
  const config = {
    safeAddress: safeAddress,
    masterCopy: SAFE_L2,
    owner: deployer.address,
    threshold: threshold,
    deploymentTx: tx.hash,
    timestamp: new Date().toISOString(),
  };
  
  fs.writeFileSync('new-safe-config.json', JSON.stringify(config, null, 2));
  console.log('Configuration saved to: new-safe-config.json');
  console.log('');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
