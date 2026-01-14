#!/bin/bash

echo "=========================================="
echo "EC2 部署配置验证"
echo "=========================================="
echo ""

# 1. 检查环境变量配置
echo "1. 检查 .env 配置..."
if grep -q "NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway" /home/ubuntu/safe-space/safe-wallet-web/apps/web/.env; then
    echo "   ✅ Gateway URL 配置正确（使用 API 代理）"
else
    echo "   ❌ Gateway URL 配置错误"
    echo "   当前配置:"
    grep "GATEWAY_URL_PRODUCTION" /home/ubuntu/safe-space/safe-wallet-web/apps/web/.env
    echo ""
    echo "   应该是: NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway"
    exit 1
fi
echo ""

# 2. 检查 Gateway 服务（EC2 内部）
echo "2. 检查 Gateway 服务（EC2 内部）..."
GATEWAY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/v1/chains?cursor=limit=1)
if [ "$GATEWAY_STATUS" = "200" ]; then
    echo "   ✅ Gateway 服务正常 (HTTP $GATEWAY_STATUS)"
else
    echo "   ❌ Gateway 服务异常 (HTTP $GATEWAY_STATUS)"
    echo "   请检查 Docker 容器是否运行"
    exit 1
fi
echo ""

# 3. 检查 Next.js 服务
echo "3. 检查 Next.js 服务..."
if lsof -i:3000 > /dev/null 2>&1; then
    echo "   ✅ Next.js 服务正在运行（端口 3000）"
    
    # 测试 API 代理
    echo "   测试 API 代理..."
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/gateway/v1/chains?cursor=limit=1)
    if [ "$API_STATUS" = "200" ]; then
        echo "   ✅ API 代理工作正常 (HTTP $API_STATUS)"
    else
        echo "   ⚠️  API 代理可能有问题 (HTTP $API_STATUS)"
        echo "   提示：如果刚修改 .env，需要重启服务器"
    fi
else
    echo "   ❌ Next.js 服务未运行"
    echo "   启动命令: cd /home/ubuntu/safe-space/safe-wallet-web && yarn dev"
    exit 1
fi
echo ""

# 4. 获取 EC2 公网 IP
echo "4. 获取访问信息..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
if [ -n "$PUBLIC_IP" ]; then
    echo "   ✅ EC2 公网 IP: $PUBLIC_IP"
    echo ""
    echo "   📱 从本地浏览器访问:"
    echo "      http://$PUBLIC_IP:3000"
    echo ""
    echo "   🧪 测试 API 代理:"
    echo "      curl http://$PUBLIC_IP:3000/api/gateway/v1/chains?cursor=limit=1"
else
    echo "   ⚠️  无法获取公网 IP（可能不在 EC2 环境）"
    echo "   请手动获取服务器 IP 地址"
fi
echo ""

# 5. 检查防火墙/安全组
echo "5. 检查端口可访问性..."
echo "   ⚠️  请确保 AWS 安全组允许以下端口:"
echo "      - 端口 3000 (Next.js 前端)"
echo "      - 端口 18545 (Hetu RPC，如果需要外部访问)"
echo ""

echo "=========================================="
echo "下一步操作"
echo "=========================================="
echo ""
echo "1. 如果刚修改了 .env 文件:"
echo "   cd /home/ubuntu/safe-space/safe-wallet-web"
echo "   # 按 Ctrl+C 停止服务器"
echo "   yarn dev"
echo ""
echo "2. 从本地电脑的浏览器访问:"
if [ -n "$PUBLIC_IP" ]; then
    echo "   http://$PUBLIC_IP:3000"
else
    echo "   http://YOUR_EC2_IP:3000"
fi
echo ""
echo "3. 打开开发者工具 (F12)，点击 'Connect wallet'"
echo ""
echo "4. 检查控制台是否显示:"
echo "   ✅ '🔧 useLoadChains: { dataLength: 1 }'"
echo "   ✅ '🔧 useInitOnboard: Chain configs loaded'"
echo ""
echo "=========================================="
