#!/bin/bash

# 更新前端合约地址脚本
# 使用方法: ./update-frontend-addresses.sh <chain-id> <addresses-json-file>

set -e

CHAIN_ID=$1
ADDRESSES_FILE=$2

if [ -z "$CHAIN_ID" ] || [ -z "$ADDRESSES_FILE" ]; then
    echo "用法: ./update-frontend-addresses.sh <chain-id> <addresses-json-file>"
    echo "示例: ./update-frontend-addresses.sh 565000 /path/to/hetu-safe-addresses.json"
    exit 1
fi

if [ ! -f "$ADDRESSES_FILE" ]; then
    echo "错误: 文件不存在: $ADDRESSES_FILE"
    exit 1
fi

echo "=========================================="
echo "更新前端合约地址"
echo "=========================================="
echo "链 ID: $CHAIN_ID"
echo "地址文件: $ADDRESSES_FILE"
echo ""

# 读取合约地址（使用 SafeL2 作为 singleton）
SAFE_SINGLETON=$(jq -r '.SafeL2' "$ADDRESSES_FILE")
SAFE_PROXY_FACTORY=$(jq -r '.SafeProxyFactory' "$ADDRESSES_FILE")
MULTI_SEND=$(jq -r '.MultiSend' "$ADDRESSES_FILE")
MULTI_SEND_CALL_ONLY=$(jq -r '.MultiSendCallOnly' "$ADDRESSES_FILE")
FALLBACK_HANDLER=$(jq -r '.CompatibilityFallbackHandler' "$ADDRESSES_FILE")
SIGN_MESSAGE_LIB=$(jq -r '.SignMessageLib' "$ADDRESSES_FILE")
CREATE_CALL=$(jq -r '.CreateCall' "$ADDRESSES_FILE")
SIMULATE_TX_ACCESSOR=$(jq -r '.SimulateTxAccessor' "$ADDRESSES_FILE")

echo "读取到的合约地址:"
echo "  SafeL2 (singleton): $SAFE_SINGLETON"
echo "  SafeProxyFactory: $SAFE_PROXY_FACTORY"
echo "  MultiSend: $MULTI_SEND"
echo "  MultiSendCallOnly: $MULTI_SEND_CALL_ONLY"
echo "  FallbackHandler: $FALLBACK_HANDLER"
echo "  SignMessageLib: $SIGN_MESSAGE_LIB"
echo "  CreateCall: $CREATE_CALL"
echo "  SimulateTxAccessor: $SIMULATE_TX_ACCESSOR"
echo ""

# 确定是主网还是测试网
if [ "$CHAIN_ID" = "560000" ]; then
    NETWORK="MAINNET"
    CONSTANT_NAME="HETU_MAINNET_CHAIN_ID"
elif [ "$CHAIN_ID" = "565000" ]; then
    NETWORK="TESTNET"
    CONSTANT_NAME="HETU_TESTNET_CHAIN_ID"
else
    echo "错误: 不支持的链 ID: $CHAIN_ID"
    echo "仅支持: 560000 (主网) 或 565000 (测试网)"
    exit 1
fi

echo "网络: Hetu $NETWORK"
echo ""

# 前端文件路径
FRONTEND_FILE="/home/ubuntu/safe-space/safe-wallet-web/apps/web/src/hooks/coreSDK/safeCoreSDK.ts"

if [ ! -f "$FRONTEND_FILE" ]; then
    echo "错误: 前端文件不存在: $FRONTEND_FILE"
    exit 1
fi

# 创建备份
cp "$FRONTEND_FILE" "${FRONTEND_FILE}.backup"
echo "✅ 已创建备份: ${FRONTEND_FILE}.backup"

# 使用 sed 更新地址
# 注意：这个脚本需要找到对应的链 ID 块并更新地址

echo "正在更新 $NETWORK 的合约地址..."

# 创建临时的 Node.js 脚本来更新地址
cat > /tmp/update-addresses.js << 'NODEJS_SCRIPT'
const fs = require('fs');

const chainId = process.argv[2];
const addresses = {
    safeSingleton: process.argv[3],
    safeProxyFactory: process.argv[4],
    multiSend: process.argv[5],
    multiSendCallOnly: process.argv[6],
    fallbackHandler: process.argv[7],
    signMessageLib: process.argv[8],
    createCall: process.argv[9],
    simulateTxAccessor: process.argv[10]
};

const filePath = process.argv[11];
let content = fs.readFileSync(filePath, 'utf8');

// 根据 chainId 找到对应的块并替换
const isMainnet = chainId === '560000';
const chainIdConstant = isMainnet ? 'HETU_MAINNET_CHAIN_ID' : 'HETU_TESTNET_CHAIN_ID';

// 构建新的合约配置块
const newBlock = `      contractNetworks = {
        [chainId]: {
          safeSingletonAddress: '${addresses.safeSingleton}',
          safeProxyFactoryAddress: '${addresses.safeProxyFactory}',
          multiSendAddress: '${addresses.multiSend}',
          multiSendCallOnlyAddress: '${addresses.multiSendCallOnly}',
          fallbackHandlerAddress: '${addresses.fallbackHandler}',
          signMessageLibAddress: '${addresses.signMessageLib}',
          createCallAddress: '${addresses.createCall}',
          simulateTxAccessorAddress: '${addresses.simulateTxAccessor}',
        },
      }`;

// 匹配对应的块（从 if 到 }）
const pattern = new RegExp(
    `(if \\(chainId === ${chainIdConstant}\\) \\{[\\s\\S]*?contractNetworks = \\{[\\s\\S]*?\\}[\\s\\S]*?\\})`,
    'g'
);

const replacement = `if (chainId === ${chainIdConstant}) {
      // Hetu ${isMainnet ? 'Mainnet' : 'Testnet'} (${chainId}) contract addresses
${newBlock}
    }`;

content = content.replace(pattern, replacement);

fs.writeFileSync(filePath, content, 'utf8');
console.log(`✅ 已更新 ${isMainnet ? 'Mainnet' : 'Testnet'} 地址`);
NODEJS_SCRIPT

# 运行 Node.js 脚本
node /tmp/update-addresses.js \
    "$CHAIN_ID" \
    "$SAFE_SINGLETON" \
    "$SAFE_PROXY_FACTORY" \
    "$MULTI_SEND" \
    "$MULTI_SEND_CALL_ONLY" \
    "$FALLBACK_HANDLER" \
    "$SIGN_MESSAGE_LIB" \
    "$CREATE_CALL" \
    "$SIMULATE_TX_ACCESSOR" \
    "$FRONTEND_FILE"

# 清理临时文件
rm /tmp/update-addresses.js

echo ""
echo "=========================================="
echo "✅ 前端合约地址更新完成！"
echo "=========================================="
echo ""
echo "修改的文件: $FRONTEND_FILE"
echo "备份文件: ${FRONTEND_FILE}.backup"
echo ""
echo "如果需要恢复，请运行:"
echo "  cp ${FRONTEND_FILE}.backup $FRONTEND_FILE"
echo ""
