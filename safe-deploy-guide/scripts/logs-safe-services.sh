#!/bin/bash

# 查看 Safe 服务日志脚本

# 使用正确的 docker compose 命令
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  Safe 服务日志"
echo "=========================================="
echo ""
echo "按 Ctrl+C 退出日志查看"
echo ""

# 如果提供了服务名参数，只显示该服务的日志
if [ -n "$1" ]; then
    echo "查看服务: $1"
    echo ""
    $DOCKER_COMPOSE -f "$PROJECT_DIR/config/docker-compose-hetu-safe.yml" logs -f "$1"
else
    echo "查看所有服务日志"
    echo ""
    echo "可用服务："
    echo "  - postgres"
    echo "  - redis"
    echo "  - transaction-service"
    echo "  - transaction-worker"
    echo "  - transaction-scheduler"
    echo "  - config-service"
    echo "  - client-gateway"
    echo ""
    echo "查看特定服务: ./logs-safe-services.sh <service-name>"
    echo ""
    $DOCKER_COMPOSE -f "$PROJECT_DIR/config/docker-compose-hetu-safe.yml" logs -f
fi
