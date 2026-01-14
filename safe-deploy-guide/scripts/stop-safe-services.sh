#!/bin/bash

# 停止 Safe 服务脚本

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

echo -e "${YELLOW}正在停止 Safe 服务...${NC}"
echo ""
echo "ℹ️  提示："
echo "  - 这个命令会停止并删除所有容器"
echo "  - ✅ 数据不会被删除（volumes 会保留）"
echo "  - ✅ 重启后所有数据会自动恢复"
echo ""

cd ../config
$DOCKER_COMPOSE -f docker-compose-hetu-safe.yml down

echo ""
echo -e "${GREEN}✅ 所有服务已停止${NC}"
echo ""

# 验证 volumes 仍然存在
VOLUMES_COUNT=$(docker volume ls | grep -c "safe-deploy-guide" || true)
if [ "$VOLUMES_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ 数据 volumes 已保留（数量: $VOLUMES_COUNT）${NC}"
    echo ""
    echo "保留的 volumes:"
    docker volume ls | grep "safe-deploy-guide"
else
    echo -e "${YELLOW}⚠️  未找到 safe-deploy-guide volumes${NC}"
fi

echo ""
echo "=========================================="
echo "  后续操作"
echo "=========================================="
echo ""
echo "✅ 重新启动服务（数据会自动恢复）:"
echo "   ./start-safe-services.sh"
echo ""
echo "⚠️  完全清理（删除所有数据）:"
echo "   cd ../config"
echo "   $DOCKER_COMPOSE -f docker-compose-hetu-safe.yml down -v"
echo ""
echo "💾 备份数据:"
echo "   docker exec safe-postgres pg_dump -U postgres safe_transaction_db > backup.sql"
echo ""
echo "📊 查看 volumes:"
echo "   docker volume ls | grep safe-deploy-guide"
echo ""
