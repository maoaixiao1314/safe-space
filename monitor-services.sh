#!/bin/bash

# 服务监控脚本 - 检查并自动重启失败的服务

LOG_FILE="/home/ubuntu/safe-space/logs/monitor.log"
mkdir -p /home/ubuntu/safe-space/logs

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查 Docker 容器
check_docker_container() {
    local container=$1
    if ! docker ps | grep -q "$container"; then
        log "❌ $container 未运行，尝试重启..."
        docker start "$container"
        sleep 5
        if docker ps | grep -q "$container"; then
            log "✅ $container 已成功重启"
        else
            log "⚠️  $container 重启失败，请手动检查"
        fi
    fi
}

# 检查 PM2 进程
check_pm2_process() {
    if ! pm2 list | grep -q "safe-web.*online"; then
        log "❌ Next.js 服务未运行，尝试重启..."
        cd /home/ubuntu/safe-space/safe-wallet-web
        pm2 restart safe-web
        sleep 5
        if pm2 list | grep -q "safe-web.*online"; then
            log "✅ Next.js 服务已成功重启"
        else
            log "⚠️  Next.js 服务重启失败，请手动检查"
        fi
    fi
}

# 检查 Redis 是否为 Master 模式
check_redis_mode() {
    local role=$(docker exec safe-redis redis-cli INFO replication 2>/dev/null | grep "role:" | cut -d: -f2 | tr -d '\r')
    if [ "$role" != "master" ]; then
        log "❌ Redis 不是 master 模式 (当前: $role)，正在修复..."
        docker exec safe-redis redis-cli SLAVEOF NO ONE
        docker restart safe-client-gateway
        log "✅ Redis 已设置为 master 模式"
    fi
}

log "🔍 开始服务检查..."

# 检查所有 Docker 容器
CONTAINERS=(
    "safe-client-gateway"
    "safe-transaction-service"
    "safe-transaction-worker"
    "safe-transaction-scheduler"
    "safe-config-service"
    "safe-postgres"
    "safe-postgres-gateway"
    "safe-redis"
    "safe-rabbitmq"
)

for container in "${CONTAINERS[@]}"; do
    check_docker_container "$container"
done

# 检查 Redis 模式
check_redis_mode

# 检查 PM2 进程
check_pm2_process

log "✅ 服务检查完成"
