#!/bin/bash

# 添加 Hetu 链配置到 Safe Config Service
# 用法: ./add-hetu-chain.sh [CHAIN_ID]
# 不传参数默认为 565000 (测试网)

set -e

# 获取链 ID 参数（默认测试网）
CHAIN_ID=${1:-565000}

echo "=========================================="
echo "  添加 Hetu 链配置 (Chain ID: $CHAIN_ID)"
echo "=========================================="
echo ""

# 根据链 ID 设置配置
if [ "$CHAIN_ID" = "560000" ]; then
    CHAIN_NAME="Hetu"
    SHORT_NAME="hetu"
    DESCRIPTION="Hetu Blockchain Network"
    IS_TESTNET="false"
    RPC_URI="https://rpc.v1.hetu.org"
    EXPLORER_BASE="https://explorer.hetu.org"
elif [ "$CHAIN_ID" = "565000" ]; then
    CHAIN_NAME="Hetu Testnet"
    SHORT_NAME="hetu-test"
    DESCRIPTION="Hetu Testnet - Custom Test Chain"
    IS_TESTNET="true"
    RPC_URI="http://161.97.161.133:18545"
    EXPLORER_BASE="http://161.97.161.133:18545"
else
    echo "❌ 不支持的链 ID: $CHAIN_ID"
    echo "支持的链 ID: 560000 (主网), 565000 (测试网)"
    exit 1
fi

# 等待 Config Service 启动
echo "等待 Config Service 启动..."
sleep 5

# 检查链是否已存在
echo "检查链 $CHAIN_ID 配置是否已存在..."
CHAIN_EXISTS=$(docker exec safe-postgres psql -U postgres -d safe_transaction_db -t -c "SELECT COUNT(*) FROM chains_chain WHERE id = $CHAIN_ID;")

if [ "$CHAIN_EXISTS" -gt 0 ]; then
    echo "⚠️  链 $CHAIN_ID 配置已存在，跳过添加"
else
    echo "添加链 $CHAIN_ID 配置到数据库..."
    
    # 添加链配置
    docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
    INSERT INTO chains_chain (
        id, name, short_name, description, l2, is_testnet, hidden, zk,
        rpc_uri, rpc_authentication,
        safe_apps_rpc_uri, safe_apps_rpc_authentication,
        public_rpc_uri, public_rpc_authentication,
        block_explorer_uri_address_template,
        block_explorer_uri_tx_hash_template,
        block_explorer_uri_api_template,
        currency_name, currency_symbol, currency_decimals, currency_logo_uri,
        transaction_service_uri, vpc_transaction_service_uri,
        theme_text_color, theme_background_color,
        ens_registry_address, recommended_master_copy_version, relevance,
        balances_provider_enabled
    ) VALUES (
        $CHAIN_ID, '$CHAIN_NAME', '$SHORT_NAME', '$DESCRIPTION', true, $IS_TESTNET, false, false,
        '$RPC_URI', '',
        '$RPC_URI', '',
        '$RPC_URI', '',
        '$EXPLORER_BASE/address/{{address}}', '$EXPLORER_BASE/tx/{{txHash}}', '$EXPLORER_BASE/api',
        'Hetu', 'HETU', 18, 'https://example.com/logo.png',
        'http://transaction-service:8888', 'http://transaction-service:8888',
        '#ffffff', '#000000',
        NULL, '1.3.0', 100,
        false
    );
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ 成功添加链 $CHAIN_ID 配置"
    else
        echo "❌ 添加链配置失败"
        exit 1
    fi
fi

# 检查 Gas Price 配置是否已存在
echo "检查 Gas Price 配置是否已存在..."
GASPRICE_EXISTS=$(docker exec safe-postgres psql -U postgres -d safe_transaction_db -t -c "SELECT COUNT(*) FROM chains_gasprice WHERE chain_id = $CHAIN_ID;")

if [ "$GASPRICE_EXISTS" -gt 0 ]; then
    echo "⚠️  Gas Price 配置已存在，跳过添加"
else
    echo "添加 Gas Price 配置..."
    
    # 添加 Gas Price 配置
    docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
    INSERT INTO chains_gasprice (
        chain_id, oracle_uri, oracle_parameter, gwei_factor, fixed_wei_value, rank
    ) VALUES (
        $CHAIN_ID, NULL, '', '1000000000', '1000000000', 1
    );
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ 成功添加 Gas Price 配置"
    else
        echo "❌ 添加 Gas Price 配置失败"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "  配置添加完成"
echo "=========================================="
echo ""
echo "验证配置："
echo "  curl http://localhost:8001/api/v1/chains/$CHAIN_ID/"
echo ""

# 验证配置
echo "正在验证配置..."
RESPONSE=$(curl -s http://localhost:8001/api/v1/chains/$CHAIN_ID/)
if echo "$RESPONSE" | grep -q "chainId"; then
    echo "✅ 链 $CHAIN_ID 配置验证成功"
    echo ""
    echo "链信息："
    echo "$RESPONSE" | jq -r '"  Chain ID: \(.chainId)\n  Name: \(.chainName)\n  RPC: \(.rpcUri.value)\n  Transaction Service: \(.transactionService)"'
else
    echo "❌ 配置验证失败"
    echo "$RESPONSE"
    exit 1
fi
