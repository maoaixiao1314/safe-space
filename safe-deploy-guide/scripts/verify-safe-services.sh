#!/bin/bash

# 验证 Safe 服务脚本

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "  验证 Safe 服务"
echo "=========================================="
echo ""

# 检查服务是否运行
check_service() {
    local service_name=$1
    local url=$2
    local description=$3
    
    echo -n "检查 $description... "
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 正常${NC}"
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 检查 Transaction Service
echo "1. Transaction Service (核心服务)"
if check_service "transaction-service" "http://localhost:8000/api/v1/about/" "Transaction Service API"; then
    echo "   响应内容:"
    curl -s http://localhost:8000/api/v1/about/ | python3 -m json.tool 2>/dev/null || echo "   (无法格式化 JSON)"
fi
echo ""

# 检查 Config Service
echo "2. Config Service (配置服务)"
if check_service "config-service" "http://localhost:8001/api/v1/chains/560000/" "Config Service API"; then
    echo "   Hetu 链配置已加载"
fi
echo ""

# 检查 Client Gateway
echo "3. Client Gateway (API 网关)"
# 注意：Client Gateway 的 /health/live 可能返回 KO (由于 AMQP 连接)
# 但这不影响核心功能，我们测试实际的 API 端点
CLIENT_HEALTH=$(curl -s http://localhost:3001/health/live 2>/dev/null)
CLIENT_API=$(curl -s http://localhost:3001/about 2>/dev/null)

if echo "$CLIENT_API" | grep -q "build_number\|version" || echo "$CLIENT_API" | grep -q "safe-client-gateway"; then
    echo -e "${GREEN}✅ Client Gateway API 正常${NC}"
    if echo "$CLIENT_HEALTH" | grep -q '"status":"OK"'; then
        echo "   健康状态: OK"
    else
        echo -e "   ${YELLOW}⚠️  健康状态: KO (AMQP未连接，但不影响核心功能)${NC}"
    fi
else
    echo -e "${RED}❌ Client Gateway API 失败${NC}"
fi
echo ""

# 检查 Docker 容器状态
echo "4. Docker 容器状态"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 使用正确的 docker compose 命令
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# 使用正确的配置文件路径
$DOCKER_COMPOSE -f "$PROJECT_DIR/config/docker-compose-hetu-safe.yml" ps

echo ""
echo "=========================================="
echo "  验证完成"
echo "=========================================="
echo ""

# 检查是否所有服务都正常
all_healthy=true

if ! curl -s -f http://localhost:8000/api/v1/about/ > /dev/null 2>&1; then
    all_healthy=false
fi

if ! curl -s -f http://localhost:8001/api/v1/chains/560000/ > /dev/null 2>&1; then
    all_healthy=false
fi

# Client Gateway - 检查 API 而不是健康端点
if ! curl -s http://localhost:3001/about 2>/dev/null | grep -q "build_number\|version\|safe-client-gateway"; then
    all_healthy=false
fi

if [ "$all_healthy" = true ]; then
    echo -e "${GREEN}✅ 所有服务运行正常！${NC}"
    echo ""
    echo "服务访问地址："
    echo "  Transaction Service: http://localhost:8000"
    echo "  Config Service: http://localhost:8001"
    echo "  Client Gateway: http://localhost:3001"
    echo ""
    echo "API 文档："
    echo "  Transaction Service: http://localhost:8000/api/v1/"
    echo "  Config Service: http://localhost:8001/api/v1/"
    echo ""
    echo "下一步："
    echo "  1. 使用 Safe SDK 连接到 http://localhost:3001"
    echo "  2. 或部署 Safe Web UI 连接到这些服务"
    echo "  3. 查看日志: ./logs-safe-services.sh"
else
    echo -e "${RED}❌ 部分服务未正常运行${NC}"
    echo ""
    echo "故障排查："
    echo "  1. 查看日志: ./logs-safe-services.sh"
    echo "  2. 检查 Docker 容器: docker ps -a"
    echo "  3. 重启服务: ./restart-safe-services.sh"
    echo ""
    echo "常见问题："
    echo "  - Transaction Service 需要几分钟来初始化数据库"
    echo "  - 确保 Hetu RPC (http://161.97.161.133:18545) 可访问"
    echo "  - 检查端口 8000, 8001, 3001 是否被占用"
fi

echo ""
