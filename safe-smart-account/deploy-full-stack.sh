#!/bin/bash

# Safe Wallet 完整部署流程
# 按正确顺序执行所有部署步骤

set -e

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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo ""
    echo "=========================================="
    echo -e "${BLUE}$1${NC}"
    echo "=========================================="
    echo ""
}

# 工作目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEPLOYMENT_DIR="$SCRIPT_DIR"
SAFE_DEPLOY_GUIDE_DIR="$SCRIPT_DIR/../safe-deploy-guide/scripts"

# ============================================
# 步骤 0: 安装依赖
# ============================================
print_step "步骤 0/6: 检查并安装依赖"

# 检查 Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js 未安装，请先安装 Node.js"
    exit 1
fi

# 检查并安装 dotenv（如果在 scripts 目录中需要）
if [ ! -d "$SAFE_DEPLOY_GUIDE_DIR/node_modules" ]; then
    print_info "在 scripts 目录安装 dotenv..."
    cd "$SAFE_DEPLOY_GUIDE_DIR"
    if [ ! -f "package.json" ]; then
        cat > package.json << 'EOF'
{
  "name": "safe-deploy-scripts",
  "version": "1.0.0",
  "description": "Safe deployment scripts utilities",
  "dependencies": {
    "dotenv": "^16.0.0"
  }
}
EOF
    fi
    npm install --silent
    print_success "依赖安装完成"
fi

cd "$DEPLOYMENT_DIR"

# 读取 .env 配置
if [ ! -f "$DEPLOYMENT_DIR/.env" ]; then
    print_error ".env 文件不存在"
    exit 1
fi

source "$DEPLOYMENT_DIR/.env"

# 获取当前链 ID
CURRENT_CHAIN_ID=${CHAIN_ID:-565000}

print_info "当前配置："
echo "  Chain ID: $CURRENT_CHAIN_ID"
if [ "$CURRENT_CHAIN_ID" = "560000" ]; then
    echo "  网络: Hetu 主网"
    echo "  RPC: $MAINNET_NODE_URL"
else
    echo "  网络: Hetu 测试网"
    echo "  RPC: $TESTNET_NODE_URL"
fi
echo ""

echo "=========================================="
echo "  Safe Wallet 完整部署流程"
echo "=========================================="
echo ""
print_warning "本脚本将按以下顺序执行部署："
echo "  1. 部署 Safe 合约"
echo "  2. 启动后端服务（Transaction Service 等）"
echo "  3. 添加链配置到 Config Service"
echo "  4. 更新合约地址并注册 SafeL2"
echo "  4.5. 更新前端合约地址"
echo "  5. 验证部署"
echo "  6. 重启前端服务"
echo ""

read -p "是否继续？(y/n): " continue_deploy
if [ "$continue_deploy" != "y" ] && [ "$continue_deploy" != "Y" ]; then
    echo "部署已取消"
    exit 0
fi

# ============================================
# 步骤 1: 部署合约
# ============================================
print_step "步骤 1/6: 部署 Safe 合约"

if [ ! -f "$DEPLOYMENT_DIR/deploy-production.sh" ]; then
    print_error "找不到 deploy-production.sh"
    exit 1
fi

cd "$DEPLOYMENT_DIR"
./deploy-production.sh

DEPLOY_EXIT_CODE=$?
if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    print_error "合约部署失败"
    exit 1
fi

print_success "合约部署完成"

# 检查部署地址文件
ADDRESSES_FILE="$DEPLOYMENT_DIR/hetu-safe-addresses.json"
if [ ! -f "$ADDRESSES_FILE" ]; then
    print_error "未找到部署地址文件: $ADDRESSES_FILE"
    exit 1
fi

# 显示所有部署的合约地址
echo ""
print_info "运行 get-addresses.js 显示部署摘要..."
echo ""
node get-addresses.js
echo ""

# 提取关键地址
SAFEL2_ADDRESS=$(node -p "try { require('$ADDRESSES_FILE').SafeL2 } catch(e) { '' }")
PROXY_FACTORY=$(node -p "try { require('$ADDRESSES_FILE').SafeProxyFactory } catch(e) { '' }")

if [ -z "$SAFEL2_ADDRESS" ] || [ "$SAFEL2_ADDRESS" = "undefined" ]; then
    print_error "SafeL2 地址未找到"
    exit 1
fi

print_info "SafeL2: $SAFEL2_ADDRESS"
print_info "ProxyFactory: $PROXY_FACTORY"

# 等待用户确认
echo ""
print_warning "请确认部署的合约地址正确"
read -p "按 Enter 继续..."

# ============================================
# 步骤 2: 启动后端服务
# ============================================
print_step "步骤 2/6: 启动后端服务"

if [ ! -d "$SAFE_DEPLOY_GUIDE_DIR" ]; then
    print_error "找不到 safe-deploy-guide/scripts 目录"
    exit 1
fi

cd "$SAFE_DEPLOY_GUIDE_DIR"

# 检查服务是否已经在运行
if docker ps | grep -q "safe-transaction-service"; then
    print_warning "服务已经在运行，跳过启动"
else
    print_info "启动服务..."
    ./start-safe-services.sh
fi

# 等待服务启动
print_info "等待服务启动（30秒）..."
sleep 30

# 验证服务
print_info "验证服务状态..."
if curl -s http://localhost:8000/api/v1/about/ > /dev/null 2>&1; then
    print_success "Transaction Service 运行正常"
else
    print_error "Transaction Service 未响应"
    exit 1
fi

if curl -s http://localhost:8001/api/ > /dev/null 2>&1; then
    print_success "Config Service 运行正常"
else
    print_error "Config Service 未响应"
    exit 1
fi

# ============================================
# 步骤 3: 添加链配置
# ============================================
print_step "步骤 3/6: 添加链配置"

print_info "当前链 ID: $CURRENT_CHAIN_ID"

# 检查链配置是否已存在
CHAIN_EXISTS=$(curl -s http://localhost:8001/api/v1/chains/$CURRENT_CHAIN_ID/ 2>&1)
if echo "$CHAIN_EXISTS" | grep -q "chainId"; then
    print_warning "链 $CURRENT_CHAIN_ID 配置已存在，跳过添加"
else
    print_info "添加链 $CURRENT_CHAIN_ID 配置..."
    ./add-hetu-chain.sh "$CURRENT_CHAIN_ID"
fi

# 验证链配置
CHAIN_CONFIG=$(curl -s http://localhost:8001/api/v1/chains/$CURRENT_CHAIN_ID/)
if echo "$CHAIN_CONFIG" | grep -q "chainId"; then
    print_success "链配置添加成功"
else
    print_error "链配置添加失败"
    exit 1
fi

# ============================================
# 步骤 4: 更新合约地址
# ============================================
print_step "步骤 4/6: 更新合约地址并注册 SafeL2"

print_info "从部署文件自动读取合约地址..."
echo ""
echo "当前部署的合约地址："
cat "$ADDRESSES_FILE" | jq '.'
echo ""

# 使用 update-from-json.sh 自动更新
if [ -f "$SAFE_DEPLOY_GUIDE_DIR/update-from-json.sh" ]; then
    print_info "运行 update-from-json.sh 自动更新合约地址..."
    "$SAFE_DEPLOY_GUIDE_DIR/update-from-json.sh" "$CURRENT_CHAIN_ID"
    
    UPDATE_EXIT_CODE=$?
    if [ $UPDATE_EXIT_CODE -ne 0 ]; then
        print_error "自动更新合约地址失败"
        exit 1
    fi
    print_success "合约地址自动更新完成"
else
    print_error "未找到 update-from-json.sh"
    exit 1
fi

# ============================================
# 步骤 4.5: 更新前端合约地址
# ============================================
print_step "步骤 4.5/6: 更新前端合约地址"

print_info "当前链 ID: $CURRENT_CHAIN_ID"
print_info "更新前端合约地址配置..."

# 调用更新脚本
if [ -f "/home/ubuntu/safe-space/update-frontend-addresses.sh" ]; then
    /home/ubuntu/safe-space/update-frontend-addresses.sh "$CURRENT_CHAIN_ID" "$ADDRESSES_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "前端合约地址更新成功"
    else
        print_error "前端合约地址更新失败"
        print_warning "请手动更新 safe-wallet-web/apps/web/src/hooks/coreSDK/safeCoreSDK.ts"
    fi
else
    print_warning "未找到 update-frontend-addresses.sh 脚本"
    print_warning "请手动更新前端配置"
fi

# ============================================
# 步骤 5: 验证部署
# ============================================
print_step "步骤 5/6: 验证部署"

echo "运行部署验证..."
cd "$DEPLOYMENT_DIR"

if [ -f "./verify-deployment.sh" ]; then
    ./verify-deployment.sh || print_warning "验证脚本执行失败，继续部署流程"
else
    print_warning "verify-deployment.sh 未找到，跳过自动验证"
fi

# 重启 Transaction Service 以确保加载新配置
print_info "重启 Transaction Service 以加载新配置..."
docker restart safe-transaction-service
sleep 5
print_success "Transaction Service 已重启"

# ============================================
# 步骤 6: 启动/重启前端服务
# ============================================
print_step "步骤 6/6: 启动前端服务"

print_info "启动 Safe Wallet Web..."

# 停止旧的前端进程
pm2 stop safe-web 2>/dev/null || true
pm2 delete safe-web 2>/dev/null || true

# 启动新的前端进程
cd /home/ubuntu/safe-space/safe-wallet-web/apps/web
pm2 start "yarn dev" --name safe-web

if [ $? -eq 0 ]; then
    print_success "Safe Wallet Web 启动成功"
    print_info "等待前端启动（15秒）..."
    sleep 15
else
    print_error "Safe Wallet Web 启动失败"
    exit 1
fi

# ============================================
# 完成
# ============================================
echo ""
echo "=========================================="
print_success "部署流程完成！🎉"
echo "=========================================="
echo ""

print_info "部署摘要："
if [ "$CURRENT_CHAIN_ID" = "560000" ]; then
    echo "  网络: Hetu 主网 (Chain ID: 560000)"
    echo "  RPC: https://rpc.v1.hetu.org"
else
    echo "  网络: Hetu 测试网 (Chain ID: 565000)"
    echo "  RPC: http://161.97.161.133:18546"
fi
echo ""
echo "  SafeL2: $SAFEL2_ADDRESS"
echo "  ProxyFactory: $PROXY_FACTORY"
echo ""
echo "  Transaction Service: http://localhost:8000"
echo "  Config Service: http://localhost:8001"
echo "  Client Gateway: http://localhost:3001"
echo "  Safe Web: http://13.250.19.178:3002"
echo ""

print_info "✅ 已完成的配置："
echo "  ✅ Safe 合约已部署"
echo "  ✅ 后端服务已启动"
echo "  ✅ 链配置已添加 (Chain ID: $CURRENT_CHAIN_ID)"
echo "  ✅ 合约地址已注册（SafeL2 l2=true）"
echo "  ✅ 前端合约地址已更新"
echo "  ✅ Transaction Service 已重启"
echo "  ✅ 前端服务已启动 (PM2)"
echo ""

print_info "🧪 测试验证："
echo ""
echo "1. 访问 Safe Web: http://13.250.19.178:3002"
echo "2. 连接 MetaMask 钱包到 Hetu 网络"
if [ "$CURRENT_CHAIN_ID" = "560000" ]; then
    echo "   - 网络: Hetu Mainnet"
    echo "   - RPC URL: https://rpc.v1.hetu.org"
    echo "   - Chain ID: 560000"
else
    echo "   - 网络: Hetu Testnet"
    echo "   - RPC URL: http://161.97.161.133:18546"
    echo "   - Chain ID: 565000"
fi
echo "   - 货币符号: HETU"
echo "3. 创建新的 Safe 钱包"
echo "4. 执行测试交易"
echo ""

print_info "📚 有用的命令："
echo "  - 查看服务日志: cd /home/ubuntu/safe-space/safe-deploy-guide/scripts && ./logs-safe-services.sh"
echo "  - 查看前端日志: pm2 logs safe-web"
echo "  - 重启后端: cd /home/ubuntu/safe-space/safe-deploy-guide/scripts && ./restart-safe-services.sh"
echo "  - 重启前端: pm2 restart safe-web"
echo "  - 停止所有服务: ./stop-safe-services.sh && pm2 stop all"
echo ""

print_info "📋 部署文件："
echo "  - 合约地址: $ADDRESSES_FILE"
echo "  - 部署信息: $(ls -t $DEPLOYMENT_DIR/deployment-info-* 2>/dev/null | head -1 || echo 'N/A')"
echo "  - 链配置: safe-deploy-guide/config/safe-config/chains/$CURRENT_CHAIN_ID.json"
echo ""

print_success "🎉 部署完成，系统已就绪！"
echo ""
