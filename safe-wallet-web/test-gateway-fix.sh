#!/bin/bash

# Connect Wallet 修复验证脚本

echo "======================================"
echo "Connect Wallet 修复验证"
echo "======================================"
echo ""

# 1. 检查 Gateway 服务
echo "1. 检查 Gateway 服务状态..."
GATEWAY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/v1/chains?cursor=limit=1)

if [ "$GATEWAY_RESPONSE" = "200" ]; then
    echo "   ✅ Gateway 服务正常 (HTTP $GATEWAY_RESPONSE)"
    curl -s "http://localhost:3001/v1/chains?cursor=limit=1" | jq -r '.results[0] | "   链ID: \(.chainId), 名称: \(.chainName)"' 2>/dev/null || echo "   (无法解析 JSON)"
else
    echo "   ❌ Gateway 服务异常 (HTTP $GATEWAY_RESPONSE)"
    exit 1
fi
echo ""

# 2. 检查环境配置
echo "2. 检查环境配置..."
if grep -q "NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=http://localhost:3001" /home/ubuntu/safe-space/safe-wallet-web/apps/web/.env; then
    echo "   ✅ Gateway URL 配置正确"
else
    echo "   ❌ Gateway URL 配置错误"
    echo "   当前配置:"
    grep "GATEWAY_URL" /home/ubuntu/safe-space/safe-wallet-web/apps/web/.env | head -2
fi
echo ""

# 3. 检查链配置文件
echo "3. 检查链配置文件..."
if [ -f "/home/ubuntu/safe-space/safe-wallet-web/apps/web/config/chains/hetu.json" ]; then
    echo "   ✅ Hetu 链配置文件存在"
    jq -r '"   链ID: \(.chainId), 名称: \(.chainName)"' /home/ubuntu/safe-space/safe-wallet-web/apps/web/config/chains/hetu.json 2>/dev/null || echo "   (无法解析配置文件)"
else
    echo "   ⚠️  Hetu 链配置文件不存在（使用 API 加载）"
fi
echo ""

# 4. 检查开发服务器
echo "4. 检查开发服务器..."
if lsof -i:3000 > /dev/null 2>&1; then
    echo "   ⚠️  开发服务器正在运行"
    echo "   📝 注意：修改 .env 后需要重启服务器"
    echo "   💡 按 Ctrl+C 停止服务器，然后运行: yarn dev"
else
    echo "   ℹ️  开发服务器未运行"
    echo "   💡 启动命令: cd /home/ubuntu/safe-space/safe-wallet-web && yarn dev"
fi
echo ""

# 5. 提供测试说明
echo "======================================"
echo "测试步骤"
echo "======================================"
echo ""
echo "1. 重启开发服务器（如果正在运行）:"
echo "   cd /home/ubuntu/safe-space/safe-wallet-web"
echo "   # 按 Ctrl+C 停止当前服务器"
echo "   yarn dev"
echo ""
echo "2. 打开浏览器访问: http://localhost:3000"
echo ""
echo "3. 打开浏览器开发者工具 (F12)"
echo ""
echo "4. 点击 'Connect wallet' 按钮"
echo ""
echo "5. 检查控制台日志:"
echo "   ✅ 应该看到: '🔧 useLoadChains: { dataLength: 1 }'"
echo "   ✅ 应该看到: '🔧 useInitOnboard: Chain configs loaded: 1 chains'"
echo "   ✅ 应该看到钱包选择界面"
echo ""
echo "6. 检查 Network 标签:"
echo "   ✅ /v1/chains 请求返回 200 状态"
echo ""
echo "======================================"
echo "故障排查"
echo "======================================"
echo ""
echo "如果仍然无法连接："
echo ""
echo "1. 确认环境变量已生效:"
echo "   重启开发服务器非常重要！"
echo ""
echo "2. 检查浏览器控制台错误:"
echo "   - CORS 错误 → 检查 Gateway 服务配置"
echo "   - 404 错误 → 检查 URL 配置"
echo "   - Network 错误 → 检查服务是否运行"
echo ""
echo "3. 手动测试 Gateway API:"
echo "   curl http://localhost:3001/v1/chains?cursor=limit=1"
echo ""
echo "======================================"

exit 0
