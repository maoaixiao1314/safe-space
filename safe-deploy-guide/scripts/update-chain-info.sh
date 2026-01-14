#!/bin/bash

# ===================================================================
# 更新 Hetu 链配置
# 主网 (560000): https://rpc.v1.hetu.org
# 测试网 (565000): http://161.97.161.133:18545
# ===================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔄 更新 Hetu 链配置${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

CONFIG_DIR="/home/ubuntu/safe-space/safe-deploy-guide/config/safe-config/chains"

# ===================================================================
# 1. 更新主网配置 (560000)
# ===================================================================
echo -e "${YELLOW}📝 步骤 1: 更新主网配置 (Chain ID: 560000)${NC}"
echo "  RPC: https://rpc.v1.hetu.org"
echo "  区块浏览器: https://explorer.hetu.org"
echo ""

# 配置已通过文件更新完成

# ===================================================================
# 2. 创建测试网配置 (565000)
# ===================================================================
echo -e "${YELLOW}📝 步骤 2: 创建测试网配置 (Chain ID: 565000)${NC}"
echo "  RPC: http://161.97.161.133:18545"
echo "  区块浏览器: http://161.97.161.133:18545"
echo ""

# 配置已通过文件更新完成

# ===================================================================
# 3. 添加链到 Config Service
# ===================================================================
echo -e "${YELLOW}📝 步骤 3: 添加链到 Config Service${NC}"
echo ""

# 等待 Config Service 就绪
echo "  等待 Config Service 启动..."
sleep 5

# 检查 Config Service 是否运行
if ! docker ps | grep -q safe-config-service; then
    echo -e "${YELLOW}  ⚠️  Config Service 未运行，启动中...${NC}"
    cd /home/ubuntu/safe-space/safe-deploy-guide
    docker-compose -f config/docker-compose-hetu-safe.yml up -d safe-config-service
    sleep 10
fi

echo ""
echo -e "${GREEN}✅ 配置文件已更新${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📊 链配置总结${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}🌐 Hetu 主网 (Chain ID: 560000)${NC}"
echo "  📍 RPC: https://rpc.v1.hetu.org"
echo "  🔍 区块浏览器: https://explorer.hetu.org"
echo "  📁 配置文件: ${CONFIG_DIR}/560000.json"
echo ""
echo -e "${YELLOW}🧪 Hetu 测试网 (Chain ID: 565000)${NC}"
echo "  📍 RPC: http://161.97.161.133:18545"
echo "  🔍 区块浏览器: http://161.97.161.133:18545"
echo "  📁 配置文件: ${CONFIG_DIR}/565000.json"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}📝 下一步操作：${NC}"
echo ""
echo "  1. 重启 Config Service:"
echo "     docker restart safe-config-service"
echo ""
echo "  2. 重启 Gateway:"
echo "     docker restart safe-client-gateway"
echo ""
echo "  3. 验证链配置:"
echo "     curl http://localhost:8001/api/v1/chains/560000 | jq"
echo "     curl http://localhost:8001/api/v1/chains/565000 | jq"
echo ""
echo "  4. 前端测试:"
echo "     访问 http://13.250.19.178:3002/"
echo "     在 MetaMask 中添加网络"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
