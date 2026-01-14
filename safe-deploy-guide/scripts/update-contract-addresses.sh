#!/bin/bash

# 更新 Hetu 链的 Safe 合约地址
# 用法: ./update-contract-addresses.sh [CHAIN_ID]
# 不传参数默认为 565000 (测试网)

set -e

# 获取链 ID 参数（默认测试网）
CHAIN_ID=${1:-565000}

echo "=========================================="
echo "  更新 Safe 合约地址 (Chain ID: $CHAIN_ID)"
echo "=========================================="
echo ""

# Safe 合约地址（从部署结果中获取）
# ⚠️ 已更新为 2025-10-15 最新部署的地址
# ⚠️ 重要：对于 L2 链，SAFE_SINGLETON 应该使用 SafeL2 地址！
SAFE_SINGLETON="eF53e7B1bC9b520d71C7B667E97E8E90cF7ad758"  # ✅ SafeL2（用于 L2 链）
SAFE_L1="c53E2b4a2C981B7AaB422eE93e8aE6ED6B6e19Fc"  # Safe L1（仅用于注册，不用于 safe_singleton_address）
SAFE_L2="eF53e7B1bC9b520d71C7B667E97E8E90cF7ad758"  # SafeL2
SAFE_PROXY_FACTORY="F33dd7eAaeBb410b53cc2B088CD944F7910A791A"
FALLBACK_HANDLER="240beE66cf9109826ab954eD17D4753539Af8A7b"
MULTI_SEND="6E913540ac3135F7EE14336cDbdD903d1deDa8FA"
MULTI_SEND_CALL_ONLY="fb80593E2B6339Fa57013D87c4e932aA4E10644D"
SIGN_MESSAGE_LIB="82C6723F6c459546591DBAc5eB0EbcC54cBe77B8"
CREATE_CALL="d762DEcFffb9B1cE53bF42B2B645b1D123f0B456"
SIMULATE_TX_ACCESSOR="eD33bA24d653c3D696ccc7e872D12909977B02D3"

echo "更新数据库中的合约地址..."

docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
UPDATE chains_chain SET
    safe_singleton_address = decode('$SAFE_SINGLETON', 'hex'),
    safe_proxy_factory_address = decode('$SAFE_PROXY_FACTORY', 'hex'),
    fallback_handler_address = decode('$FALLBACK_HANDLER', 'hex'),
    multi_send_address = decode('$MULTI_SEND', 'hex'),
    multi_send_call_only_address = decode('$MULTI_SEND_CALL_ONLY', 'hex'),
    sign_message_lib_address = decode('$SIGN_MESSAGE_LIB', 'hex'),
    create_call_address = decode('$CREATE_CALL', 'hex'),
    simulate_tx_accessor_address = decode('$SIMULATE_TX_ACCESSOR', 'hex'),
    l2 = true
WHERE id = $CHAIN_ID;
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ 成功更新链 $CHAIN_ID 的合约地址"
else
    echo "❌ 更新合约地址失败"
    exit 1
fi

# 重要：注册 SafeL2 到 Transaction Service
echo ""
echo "注册 SafeL2 master copy 到 Transaction Service..."
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
INSERT INTO history_safemastercopy (address, initial_block_number, tx_block_number, version, deployer, l2)
VALUES (decode('$SAFE_L2', 'hex'), 0, 0, '1.4.1', 'L2', true)
ON CONFLICT (address) DO UPDATE SET l2 = true, version = '1.4.1', deployer = 'L2';
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ SafeL2 注册成功"
else
    echo "❌ SafeL2 注册失败"
    exit 1
fi

# 验证 SafeL2 注册
echo "验证 SafeL2 注册状态..."
SAFEL2_REGISTERED=$(docker exec safe-postgres psql -U postgres -d safe_transaction_db -t -c "
SELECT COUNT(*) FROM history_safemastercopy WHERE address = decode('$SAFE_L2', 'hex') AND l2 = true;
" | xargs)

if [ "$SAFEL2_REGISTERED" = "1" ]; then
    echo "✅ SafeL2 master copy 已正确注册 (L2 模式)"
else
    echo "⚠️  SafeL2 未正确注册，请手动检查"
fi

echo ""
echo "验证配置..."
RESPONSE=$(curl -s http://localhost:8001/api/v1/chains/$CHAIN_ID/)
if echo "$RESPONSE" | grep -q "safeSingletonAddress"; then
    echo "✅ 配置验证成功"
    echo ""
    echo "合约地址："
    echo "$RESPONSE" | jq -r '.contractAddresses | to_entries[] | "  \(.key): \(.value)"'
else
    echo "❌ 配置验证失败"
    echo "$RESPONSE"
    exit 1
fi

echo ""
echo "=========================================="
echo "  更新完成"
echo "=========================================="
