#!/bin/bash

# Hetu Safe 完整服务启动脚本
# 用于启动所有 Safe 后端服务

set -e

echo "=========================================="
echo "  Hetu Safe 完整服务部署"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
    exit 1
fi

# 使用正确的 docker compose 命令
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${GREEN}✅ Docker 环境检查通过${NC}"
echo ""

# 切换到配置目录
cd ../config

# 检查配置文件
if [ ! -f "docker-compose-hetu-safe.yml" ]; then
    echo -e "${RED}❌ 找不到 docker-compose-hetu-safe.yml 文件${NC}"
    exit 1
fi

if [ ! -f "safe-config/chains/560000.json" ]; then
    echo -e "${RED}❌ 找不到 Hetu 链配置文件${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 配置文件检查通过${NC}"
echo ""

# 显示将要部署的服务
echo "将要启动以下服务："
echo "  1. PostgreSQL (端口 5432) - 数据库"
echo "  2. Redis (端口 6379) - 缓存"
echo "  3. Transaction Service (端口 8000) - 核心服务"
echo "  4. Transaction Worker - 异步任务处理"
echo "  5. Transaction Scheduler - 定时任务"
echo "  6. Config Service (端口 8001) - 配置服务"
echo "  7. Client Gateway (端口 3001) - API 网关"
echo ""

# 显示 Hetu 链信息
echo "Hetu 链信息："
echo "  Chain ID: 560000"
echo "  RPC URL: http://161.97.161.133:18545"
echo ""

# 显示已部署的合约地址
echo "Safe 合约地址："
echo "  Safe Singleton: 0xF5628304ac05de2D7B641B16B89f1aeaBB0D0DA6"
echo "  SafeProxyFactory: 0x85d989D30C98Ee86C6Ac63132Fda598926C29d43"
echo "  MultiSend: 0x3c9887027266178802D3537DBa8D1D1890a5D938"
echo "  MultiSendCallOnly: 0x12ed4A8694a884be22594697369c05954252182C"
echo "  FallbackHandler: 0x1D10B40369bDd36943EC786651071139Fc6cCb9F"
echo ""

# 询问是否继续
read -p "是否继续启动服务？(y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消启动"
    exit 0
fi

echo ""
echo -e "${YELLOW}正在拉取 Docker 镜像...${NC}"
$DOCKER_COMPOSE -f docker-compose-hetu-safe.yml pull

echo ""
echo -e "${YELLOW}正在启动服务...${NC}"
$DOCKER_COMPOSE -f docker-compose-hetu-safe.yml up -d

echo ""
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 10

echo ""
echo -e "${GREEN}=========================================="
echo "  服务启动完成！"
echo "==========================================${NC}"
echo ""

# 检查服务状态
echo "服务状态："
$DOCKER_COMPOSE -f docker-compose-hetu-safe.yml ps

echo ""
echo -e "${GREEN}访问地址：${NC}"
echo "  Transaction Service: http://localhost:8000"
echo "  Config Service: http://localhost:8001"
echo "  Client Gateway: http://localhost:3001"
echo ""

echo -e "${YELLOW}提示：${NC}"
echo "  - 查看日志: ./logs-safe-services.sh"
echo "  - 停止服务: ./stop-safe-services.sh"
echo "  - 重启服务: ./restart-safe-services.sh"
echo "  - 验证服务: ./verify-safe-services.sh"
echo ""

echo -e "${GREEN}✅ 部署完成！${NC}"
echo ""
echo "下一步："
echo "  1. 运行 ./verify-safe-services.sh 验证服务"
echo "  2. 等待 Transaction Service 索引区块链数据（可能需要几分钟）"
echo "  3. 使用 Safe SDK 或 Web UI 连接到服务"
echo ""
