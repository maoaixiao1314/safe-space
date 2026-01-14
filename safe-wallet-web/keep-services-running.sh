#!/bin/bash

# ===================================================================
# 保持所有服务持续运行的脚本
# ===================================================================

set -e

echo "🚀 配置服务持续运行..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ===================================================================
# 1. 确保 Docker 容器自动重启
# ===================================================================
echo -e "${BLUE}📦 步骤 1: 配置 Docker 容器自动重启${NC}"
echo ""

# 检查并更新所有 Safe 相关容器的重启策略
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
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "  设置 ${container} 自动重启..."
        docker update --restart=unless-stopped "$container"
        echo -e "  ${GREEN}✅${NC} $container"
    else
        echo -e "  ${YELLOW}⚠️${NC}  $container 未找到"
    fi
done

echo ""
echo -e "${GREEN}✅ Docker 容器已配置为自动重启${NC}"
echo ""

# ===================================================================
# 2. 使用 PM2 管理 Next.js 服务
# ===================================================================
echo -e "${BLUE}📦 步骤 2: 使用 PM2 管理 Next.js 服务${NC}"
echo ""

# 检查是否安装了 PM2
if ! command -v pm2 &> /dev/null; then
    echo "  正在安装 PM2..."
    npm install -g pm2
    echo -e "  ${GREEN}✅${NC} PM2 已安装"
else
    echo -e "  ${GREEN}✅${NC} PM2 已安装"
fi

echo ""

# 停止旧的 Next.js 进程
echo "  停止旧的 Next.js 进程..."
pkill -f "yarn dev" || true
pkill -f "next-server" || true
sleep 2

# 使用 PM2 启动 Next.js
echo "  使用 PM2 启动 Next.js..."
cd /home/ubuntu/safe-space/safe-wallet-web

# 创建 PM2 配置文件
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'safe-web',
    script: 'yarn',
    args: 'dev',
    cwd: '/home/ubuntu/safe-space/safe-wallet-web',
    env: {
      PORT: 3002,
      NODE_ENV: 'production'
    },
    error_file: '/home/ubuntu/safe-space/logs/safe-web-error.log',
    out_file: '/home/ubuntu/safe-space/logs/safe-web-out.log',
    time: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 4000,
    watch: false,
    max_memory_restart: '2G'
  }]
};
EOF

echo -e "  ${GREEN}✅${NC} PM2 配置文件已创建"

# 创建日志目录
mkdir -p /home/ubuntu/safe-space/logs

# 启动应用
pm2 delete safe-web 2>/dev/null || true
pm2 start ecosystem.config.js

echo -e "  ${GREEN}✅${NC} Next.js 服务已使用 PM2 启动"
echo ""

# ===================================================================
# 3. 配置 PM2 开机自启
# ===================================================================
echo -e "${BLUE}📦 步骤 3: 配置 PM2 开机自启${NC}"
echo ""

pm2 save
pm2 startup systemd -u ubuntu --hp /home/ubuntu

echo -e "${GREEN}✅ PM2 开机自启已配置${NC}"
echo ""

# ===================================================================
# 4. 创建系统服务监控脚本
# ===================================================================
echo -e "${BLUE}📦 步骤 4: 创建服务监控脚本${NC}"
echo ""

cat > /home/ubuntu/safe-space/monitor-services.sh << 'MONITOR_EOF'
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
MONITOR_EOF

chmod +x /home/ubuntu/safe-space/monitor-services.sh

echo -e "${GREEN}✅ 监控脚本已创建: /home/ubuntu/safe-space/monitor-services.sh${NC}"
echo ""

# ===================================================================
# 5. 配置定时任务
# ===================================================================
echo -e "${BLUE}📦 步骤 5: 配置定时监控任务${NC}"
echo ""

# 添加 crontab 任务（每5分钟检查一次）
(crontab -l 2>/dev/null | grep -v "monitor-services.sh"; echo "*/5 * * * * /home/ubuntu/safe-space/monitor-services.sh >> /home/ubuntu/safe-space/logs/cron.log 2>&1") | crontab -

echo -e "${GREEN}✅ 定时任务已配置（每5分钟检查一次）${NC}"
echo ""

# ===================================================================
# 6. 显示服务状态
# ===================================================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 服务持续运行配置完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📊 当前服务状态：${NC}"
echo ""

echo "Docker 容器状态："
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}" | grep safe

echo ""
echo "PM2 进程状态："
pm2 list

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ 配置详情：${NC}"
echo ""
echo "1. Docker 容器已设置为 'unless-stopped' 重启策略"
echo "   - 服务器重启后自动启动"
echo "   - 容器崩溃后自动重启"
echo ""
echo "2. Next.js 服务使用 PM2 管理"
echo "   - 自动重启（崩溃、内存超限）"
echo "   - 开机自动启动"
echo "   - 日志记录到: /home/ubuntu/safe-space/logs/"
echo ""
echo "3. 定时监控任务（每5分钟）"
echo "   - 自动检测并重启失败的服务"
echo "   - 日志记录到: /home/ubuntu/safe-space/logs/monitor.log"
echo ""
echo -e "${YELLOW}📝 常用命令：${NC}"
echo ""
echo "  # 查看 PM2 进程"
echo "  pm2 list"
echo ""
echo "  # 查看 Next.js 日志"
echo "  pm2 logs safe-web"
echo ""
echo "  # 重启 Next.js"
echo "  pm2 restart safe-web"
echo ""
echo "  # 查看 Docker 容器"
echo "  docker ps"
echo ""
echo "  # 查看监控日志"
echo "  tail -f /home/ubuntu/safe-space/logs/monitor.log"
echo ""
echo "  # 手动运行监控检查"
echo "  /home/ubuntu/safe-space/monitor-services.sh"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ 所有服务现在将持续运行！${NC}"
echo ""
