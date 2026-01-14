#!/bin/bash

# 重启 Safe 服务脚本

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 使用正确的 docker compose 命令
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${YELLOW}正在重启 Safe 服务...${NC}"
echo ""

# 切换到配置目录
cd ../config

# 如果提供了服务名参数，只重启该服务
if [ -n "$1" ]; then
    echo "重启服务: $1"
    $DOCKER_COMPOSE -f docker-compose-hetu-safe.yml restart "$1"
else
    echo "重启所有服务"
    $DOCKER_COMPOSE -f docker-compose-hetu-safe.yml restart
fi

echo ""
echo -e "${GREEN}✅ 服务重启完成${NC}"
echo ""
echo "提示："
echo "  - 查看状态: $DOCKER_COMPOSE -f docker-compose-hetu-safe.yml ps"
echo "  - 查看日志: ./logs-safe-services.sh"
echo "  - 验证服务: ./verify-safe-services.sh"
echo ""
