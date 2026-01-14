#!/bin/bash

echo "=========================================="
echo "🔍 EC2 部署状态检查"
echo "=========================================="
echo ""

PUBLIC_IP="13.250.19.178"
PORT="3002"

# 1. 测试 API 代理
echo "1. 测试 API 代理..."
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://${PUBLIC_IP}:${PORT}/api/gateway/v1/chains?cursor=limit=1")

if [ "$API_RESPONSE" = "200" ]; then
    echo "   ✅ API 代理工作正常 (HTTP $API_RESPONSE)"
    echo "   URL: http://${PUBLIC_IP}:${PORT}/api/gateway/v1/chains"
else
    echo "   ❌ API 代理失败 (HTTP $API_RESPONSE)"
    exit 1
fi
echo ""

# 2. 检查返回的链配置
echo "2. 检查链配置数据..."
CHAIN_DATA=$(curl -s "http://${PUBLIC_IP}:${PORT}/api/gateway/v1/chains?cursor=limit=1")
CHAIN_ID=$(echo "$CHAIN_DATA" | jq -r '.results[0].chainId' 2>/dev/null)

if [ "$CHAIN_ID" = "560000" ]; then
    echo "   ✅ 链配置正确: Hetu (Chain ID: $CHAIN_ID)"
else
    echo "   ⚠️  链配置异常: $CHAIN_ID"
fi
echo ""

# 3. 检查环境变量配置
echo "3. 检查 .env 配置..."
ENV_FILE="/home/ubuntu/safe-space/safe-wallet-web/apps/web/.env"
if grep -q "NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway" "$ENV_FILE"; then
    echo "   ✅ Gateway URL 配置正确"
else
    echo "   ❌ Gateway URL 配置错误"
    grep "GATEWAY_URL" "$ENV_FILE"
fi
echo ""

# 4. 检查构建配置
echo "4. 检查前端构建..."
if [ -d "/home/ubuntu/safe-space/safe-wallet-web/apps/web/.next" ]; then
    echo "   ✅ .next 构建目录存在"
    echo "   ⚠️  如果修改了 .env，需要重启服务器以重新构建"
else
    echo "   ⚠️  .next 目录不存在"
fi
echo ""

echo "=========================================="
echo "📋 修复步骤"
echo "=========================================="
echo ""
echo "如果 Connect Wallet 仍然不工作，按以下步骤操作："
echo ""
echo "1️⃣  清除浏览器缓存："
echo "   - 打开浏览器开发者工具 (F12)"
echo "   - 右键点击刷新按钮"
echo "   - 选择 '清空缓存并硬性重新加载'"
echo ""
echo "2️⃣  或者重启 Next.js 服务器："
echo "   cd /home/ubuntu/safe-space/safe-wallet-web"
echo "   # 按 Ctrl+C 停止当前服务器"
echo "   yarn dev"
echo ""
echo "3️⃣  访问页面并测试："
echo "   http://${PUBLIC_IP}:${PORT}"
echo ""
echo "4️⃣  在浏览器控制台检查以下内容："
echo "   - Network 标签: 查看 /api/gateway/v1/chains 请求"
echo "   - Console 标签: 查看是否有错误"
echo ""
echo "=========================================="
echo "🧪 快速测试命令"
echo "=========================================="
echo ""
echo "测试 API 代理:"
echo "curl \"http://${PUBLIC_IP}:${PORT}/api/gateway/v1/chains?cursor=limit=1\" | jq '.results[0] | {chainId, chainName}'"
echo ""
echo "检查前端页面:"
echo "curl -I \"http://${PUBLIC_IP}:${PORT}\""
echo ""
echo "=========================================="
