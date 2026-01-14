const { ethers } = require('hardhat');
const Safe = require('@safe-global/protocol-kit').default;

async function main() {
  const safeAddress = '0x70D014424eBB6B2032Db660A14d3BFC2d770b388';
  const safeTxHash = '0x37bbd00884726046d77f6aec7a4d71c80d2ee2264b6dae21c84befcf39c2f11f';
  
  // Get signer
  const [signer] = await ethers.getSigners();
  console.log('Executing with account:', signer.address);
  
  // Initialize Safe SDK
  const provider = ethers.provider;
  const protocolKit = await Safe.init({
    provider: provider._getConnection().url,
    signer: signer.address,
    safeAddress: safeAddress,
  });
  
  console.log('\nFetching transaction from Transaction Service...');
  
  // Fetch transaction from service
  const transaction = await fetch(
    `http://localhost:8000/api/v1/multisig-transactions/${safeTxHash}/`
  ).then(res => res.json());
  
  console.log('Transaction details:');
  console.log('  To:', transaction.to);
  console.log('  Value:', ethers.formatEther(transaction.value), 'ETH');
  console.log('  Confirmations:', transaction.confirmations.length, '/', transaction.confirmationsRequired);
  console.log('  Is Executed:', transaction.isExecuted);
  
  if (transaction.isExecuted) {
    console.log('\n❌ Transaction already executed!');
    return;
  }
  
  if (transaction.confirmations.length < transaction.confirmationsRequired) {
    console.log('\n❌ Not enough confirmations!');
    console.log('  Required:', transaction.confirmationsRequired);
    console.log('  Current:', transaction.confirmations.length);
    return;
  }
  
  console.log('\n✅ Transaction ready to execute!');
  console.log('\nExecuting transaction...');
  
  // Build safe transaction
  const safeTransaction = {
    to: transaction.to,
    value: transaction.value,
    data: transaction.data || '0x',
    operation: transaction.operation,
    safeTxGas: transaction.safeTxGas,
    baseGas: transaction.baseGas,
    gasPrice: transaction.gasPrice,
    gasToken: transaction.gasToken,
    refundReceiver: transaction.refundReceiver,
    nonce: transaction.nonce,
  };
  
  // Add signatures
  const signatures = transaction.confirmations.map(c => ({
    signer: c.owner,
    data: c.signature,
  }));
  
  try {
    // Execute the transaction
    const executeTxResponse = await protocolKit.executeTransaction(safeTransaction, {
      signatures: signatures
    });
    
    console.log('\n✅ Transaction executed!');
    console.log('  Transaction hash:', executeTxResponse.hash);
    
    console.log('\nWaiting for confirmation...');
    const receipt = await executeTxResponse.wait();
    
    console.log('\n✅ Transaction confirmed!');
    console.log('  Block number:', receipt.blockNumber);
    console.log('  Gas used:', receipt.gasUsed.toString());
    console.log('  Status:', receipt.status === 1 ? 'Success' : 'Failed');
    
  } catch (error) {
    console.error('\n❌ Execution failed:', error.message);
    if (error.data) {
      console.error('Error data:', error.data);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
