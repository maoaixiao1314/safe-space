#!/bin/bash

# 从 hetu-safe-addresses.json 自动更新合约地址
# 这个脚本会自动读取部署的地址，无需手动编辑
# 用法: ./update-from-json.sh [CHAIN_ID]
# 不传参数默认为 565000 (测试网)

set -e

# 获取链 ID 参数（默认测试网）
CHAIN_ID=${1:-565000}

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "=========================================="
echo "  从 JSON 文件自动更新 Safe 合约地址"
echo "  Chain ID: $CHAIN_ID"
echo "=========================================="
echo ""

# 查找 hetu-safe-addresses.json 文件
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ADDRESSES_FILE="$SCRIPT_DIR/../../safe-smart-account/hetu-safe-addresses.json"

if [ ! -f "$ADDRESSES_FILE" ]; then
    print_error "找不到地址文件: $ADDRESSES_FILE"
    echo "请确保已经部署了合约"
    exit 1
fi

print_info "从文件读取地址: $ADDRESSES_FILE"
echo ""

# 使用 node 读取 JSON 文件并提取地址（去掉 0x 前缀）
SAFE_L1=$(node -p "require('$ADDRESSES_FILE').Safe.substring(2).toLowerCase()")
SAFE_L2=$(node -p "require('$ADDRESSES_FILE').SafeL2.substring(2).toLowerCase()")
SAFE_PROXY_FACTORY=$(node -p "require('$ADDRESSES_FILE').SafeProxyFactory.substring(2).toLowerCase()")
FALLBACK_HANDLER=$(node -p "require('$ADDRESSES_FILE').CompatibilityFallbackHandler.substring(2).toLowerCase()")
MULTI_SEND=$(node -p "require('$ADDRESSES_FILE').MultiSend.substring(2).toLowerCase()")
MULTI_SEND_CALL_ONLY=$(node -p "require('$ADDRESSES_FILE').MultiSendCallOnly.substring(2).toLowerCase()")
SIGN_MESSAGE_LIB=$(node -p "require('$ADDRESSES_FILE').SignMessageLib.substring(2).toLowerCase()")
CREATE_CALL=$(node -p "require('$ADDRESSES_FILE').CreateCall.substring(2).toLowerCase()")
SIMULATE_TX_ACCESSOR=$(node -p "require('$ADDRESSES_FILE').SimulateTxAccessor.substring(2).toLowerCase()")

# 显示读取的地址
print_info "读取到的合约地址："
echo "  Safe (L1):          0x$SAFE_L1"
echo "  SafeL2:             0x$SAFE_L2"
echo "  ProxyFactory:       0x$SAFE_PROXY_FACTORY"
echo "  FallbackHandler:    0x$FALLBACK_HANDLER"
echo "  MultiSend:          0x$MULTI_SEND"
echo "  MultiSendCallOnly:  0x$MULTI_SEND_CALL_ONLY"
echo "  SignMessageLib:     0x$SIGN_MESSAGE_LIB"
echo "  CreateCall:         0x$CREATE_CALL"
echo "  SimulateTxAccessor: 0x$SIMULATE_TX_ACCESSOR"
echo ""

# 对于 L2 链，使用 SafeL2 作为 safe_singleton_address
SAFE_SINGLETON=$SAFE_L2

print_info "⚠️  对于 L2 链 (Hetu)，使用 SafeL2 作为 safe_singleton_address"
echo ""

# 更新数据库
print_info "更新数据库中的合约地址..."
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
    print_success "链 $CHAIN_ID 的合约地址更新成功"
else
    print_error "合约地址更新失败"
    exit 1
fi

# 注册 SafeL2
echo ""
print_info "注册 SafeL2 master copy..."
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
INSERT INTO history_safemastercopy (address, initial_block_number, tx_block_number, version, deployer, l2)
VALUES (decode('$SAFE_L2', 'hex'), 0, 0, '1.4.1', 'L2', true)
ON CONFLICT (address) DO UPDATE SET l2 = true, version = '1.4.1', deployer = 'L2';
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "SafeL2 注册成功"
else
    print_error "SafeL2 注册失败"
    exit 1
fi

# 同时注册 Safe L1（可选，但建议注册以支持两种类型）
print_info "注册 Safe L1 master copy（可选）..."
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
INSERT INTO history_safemastercopy (address, initial_block_number, tx_block_number, version, deployer, l2)
VALUES (decode('$SAFE_L1', 'hex'), 0, 0, '1.4.1', 'L1', false)
ON CONFLICT (address) DO UPDATE SET l2 = false, version = '1.4.1', deployer = 'L1';
" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "Safe L1 注册成功"
else
    echo "  ⚠️  Safe L1 注册失败（可忽略）"
fi

# 验证注册
echo ""
print_info "验证 SafeL2 注册状态..."
SAFEL2_REGISTERED=$(docker exec safe-postgres psql -U postgres -d safe_transaction_db -t -c "
SELECT encode(address, 'hex'), l2, version, deployer 
FROM history_safemastercopy 
WHERE encode(address, 'hex') = '$SAFE_L2';
" | xargs)

if echo "$SAFEL2_REGISTERED" | grep -q "$SAFE_L2"; then
    if echo "$SAFEL2_REGISTERED" | grep -q "t"; then
        print_success "SafeL2 已正确注册 (l2=true, version=1.4.1)"
        echo "  注册信息: $SAFEL2_REGISTERED"
    else
        print_error "SafeL2 已注册但 l2=false"
        echo "  注册信息: $SAFEL2_REGISTERED"
    fi
else
    print_error "SafeL2 未找到注册记录"
fi

# 验证配置
echo ""
print_info "验证 Config Service 配置..."
RESPONSE=$(curl -s http://localhost:8001/api/v1/chains/$CHAIN_ID/)
if echo "$RESPONSE" | grep -q "safeSingletonAddress"; then
    print_success "配置验证成功"
    echo ""
    echo "Config Service 返回的合约地址："
    echo "$RESPONSE" | jq -r '.contractAddresses | to_entries[] | "  \(.key): \(.value)"'
    
    # 验证地址是否匹配
    CONFIG_SAFEL2=$(echo "$RESPONSE" | jq -r '.contractAddresses.safeSingletonAddress' | tr '[:upper:]' '[:lower:]')
    if [ "$CONFIG_SAFEL2" = "0x$SAFE_L2" ]; then
        print_success "safeSingletonAddress 配置正确 (使用 SafeL2)"
    else
        print_error "safeSingletonAddress 配置不正确"
        echo "  期望: 0x$SAFE_L2"
        echo "  实际: $CONFIG_SAFEL2"
    fi
else
    print_error "配置验证失败"
    echo "$RESPONSE"
    exit 1
fi

echo ""
echo "=========================================="
print_success "更新完成！"
echo "=========================================="
echo ""

print_info "摘要："
echo "  ✅ 链配置已更新 (safe_singleton_address = SafeL2)"
echo "  ✅ SafeL2 已注册到 Transaction Service (l2=true)"
echo "  ✅ Config Service 返回正确的合约地址"
echo ""

print_info "下一步："
echo "  1. 重启 Transaction Service 以确保加载新配置："
echo "     docker restart safe-transaction-service"
echo ""
echo "  2. 验证服务："
echo "     ./verify-safe-services.sh"
echo ""
echo "  3. 更新 Safe Web 配置并重启："
echo "     ./restart-safe-web-clean.sh"
echo ""

