# ✅ 服务持续运行 - 配置完成总结

## 🎉 配置成功！

所有服务现在已经配置为持续运行，不会因为任何原因停止。

## ✅ 当前服务状态

### Docker 容器（9个全部运行中）

```
✅ safe-client-gateway          (端口 3001)
✅ safe-transaction-service     (端口 8000)
✅ safe-transaction-worker      
✅ safe-transaction-scheduler   
✅ safe-config-service          (端口 8001)
✅ safe-postgres                (端口 5433)
✅ safe-postgres-gateway        (端口 5434)
✅ safe-redis                   (端口 6379 - Master 模式)
✅ safe-rabbitmq                (端口 5672)
```

**重启策略**: `unless-stopped` （自动重启）

### Next.js 服务（PM2 管理）

```
✅ safe-web (PM2)               (端口 3002)
   - 状态: online
   - 自动重启: 启用
   - 开机自启: 已配置
   - 日志: /home/ubuntu/safe-space/logs/
```

### 自动监控服务

```
✅ 定时任务: 每5分钟检查一次
✅ 监控脚本: /home/ubuntu/safe-space/monitor-services.sh
✅ 监控日志: /home/ubuntu/safe-space/logs/monitor.log
```

## 🔍 功能验证

```bash
# API 代理正常工作
$ curl "http://localhost:3002/api/gateway/v1/chains?cursor=limit=1" | jq '.results[0].chainId'
"560000" ✅

# Next.js 服务运行中
$ pm2 list
safe-web  │ online ✅

# Docker 容器运行中
$ docker ps | grep safe
9 containers running ✅

# Redis 是 Master 模式
$ docker exec safe-redis redis-cli INFO replication | grep role
role:master ✅
```

## 📋 服务持续运行机制

### 1. Docker 容器自动重启

- **触发条件**: 容器崩溃、Docker daemon 重启、服务器重启
- **重启策略**: `unless-stopped`
- **重启延迟**: 立即重启
- **最大重启**: 无限制

### 2. PM2 进程管理

Next.js 服务由 PM2 管理，具有以下保障：

- **自动重启**: 进程崩溃立即重启
- **内存保护**: 超过 2GB 自动重启
- **开机自启**: systemd 服务已配置
- **日志记录**: 完整的错误和输出日志
- **最大重启**: 10次（10秒内）

**PM2 配置文件**: `/home/ubuntu/safe-space/safe-wallet-web/ecosystem.config.js`

### 3. 定时监控任务

每5分钟自动检查所有服务状态：

- **检查内容**:
  - 所有 Docker 容器是否运行
  - PM2 进程是否 online
  - Redis 是否为 master 模式

- **自动修复**:
  - 容器停止 → 自动启动
  - PM2 进程停止 → 自动重启
  - Redis 变成 slave → 改为 master 并重启 Gateway

**监控脚本**: `/home/ubuntu/safe-space/monitor-services.sh`
**执行频率**: `*/5 * * * *` (每5分钟)

## 📝 常用命令速查

### PM2 管理命令

```bash
# 查看所有进程
pm2 list

# 查看实时日志
pm2 logs safe-web

# 查看最近日志
pm2 logs safe-web --lines 100 --nostream

# 重启服务
pm2 restart safe-web

# 停止服务
pm2 stop safe-web

# 启动服务
pm2 start safe-web

# 查看详细信息
pm2 show safe-web

# 监控面板
pm2 monit
```

### Docker 管理命令

```bash
# 查看所有容器
docker ps

# 查看容器日志
docker logs safe-client-gateway --tail 50 -f

# 重启容器
docker restart safe-client-gateway

# 重启所有 Safe 容器
docker restart $(docker ps --format '{{.Names}}' | grep safe)

# 查看资源使用
docker stats
```

### 监控和诊断

```bash
# 手动运行监控检查
/home/ubuntu/safe-space/monitor-services.sh

# 查看监控日志
tail -f /home/ubuntu/safe-space/logs/monitor.log

# 查看定时任务日志
tail -f /home/ubuntu/safe-space/logs/cron.log

# 查看定时任务配置
crontab -l

# 测试 API
curl "http://localhost:3002/api/gateway/v1/chains" | jq

# 检查 Redis 模式
docker exec safe-redis redis-cli INFO replication | grep role
```

## 🔄 服务重启流程

### 优雅重启（推荐）

```bash
# 重启 Next.js
pm2 restart safe-web

# 重启 Gateway（如果需要）
docker restart safe-client-gateway

# 重启所有 Docker 容器
docker restart $(docker ps --format '{{.Names}}' | grep safe)
```

### 完全重启

```bash
# 1. 停止所有服务
pm2 stop safe-web
docker stop $(docker ps --format '{{.Names}}' | grep safe)

# 2. 启动 Docker 容器
cd /home/ubuntu/safe-space/safe-deploy-guide
docker-compose -f config/docker-compose-hetu-safe.yml up -d

# 3. 等待服务就绪
sleep 30

# 4. 确保 Redis 是 Master
docker exec safe-redis redis-cli SLAVEOF NO ONE
docker restart safe-client-gateway

# 5. 启动 Next.js
pm2 start safe-web
```

## 🚨 常见问题处理

### 问题 1: Next.js 没有运行

```bash
# 检查状态
pm2 list

# 如果显示 stopped 或 errored
pm2 restart safe-web

# 查看错误日志
pm2 logs safe-web --err --lines 50
```

### 问题 2: Gateway 返回 503

```bash
# 检查 Redis 模式
docker exec safe-redis redis-cli INFO replication | grep role

# 如果不是 master，修复它
docker exec safe-redis redis-cli SLAVEOF NO ONE
docker restart safe-client-gateway

# 等待30秒后测试
sleep 30
curl "http://localhost:3001/v1/chains"
```

### 问题 3: 容器频繁重启

```bash
# 查看容器日志找原因
docker logs safe-client-gateway --tail 100

# 查看资源使用
docker stats

# 如果是内存问题，可能需要增加服务器内存
```

### 问题 4: 服务器重启后服务没启动

```bash
# 检查 PM2 systemd 服务
sudo systemctl status pm2-ubuntu

# 如果未启用
sudo systemctl enable pm2-ubuntu
sudo systemctl start pm2-ubuntu

# 检查 Docker 容器
docker ps -a | grep safe

# 手动启动容器
docker start $(docker ps -a --format '{{.Names}}' | grep safe)
```

### 问题 5: 定时任务没有执行

```bash
# 检查 cron 服务
sudo systemctl status cron

# 查看定时任务
crontab -l

# 手动测试脚本
/home/ubuntu/safe-space/monitor-services.sh

# 查看执行日志
tail -f /home/ubuntu/safe-space/logs/cron.log
```

## 📊 监控建议

### 1. 实时监控

```bash
# 使用 PM2 监控面板
pm2 monit

# 使用 Docker stats
docker stats

# 使用 htop (需要安装)
sudo apt install htop
htop
```

### 2. 日志检查

```bash
# PM2 日志
pm2 logs safe-web --lines 100

# Docker 日志
docker logs safe-client-gateway --tail 100 -f

# 监控日志
tail -f /home/ubuntu/safe-space/logs/monitor.log

# 系统日志
sudo journalctl -u pm2-ubuntu -f
```

### 3. 定期检查

建议每天检查一次：

```bash
# 运行这个命令检查所有服务
pm2 list && \
docker ps --format "table {{.Names}}\t{{.Status}}" | grep safe && \
curl -s "http://localhost:3002/api/gateway/v1/chains?cursor=limit=1" | jq '.count'
```

应该看到：
- PM2: safe-web (online) ✅
- Docker: 9 containers Up ✅
- API: count: 1 ✅

## 🔒 生产环境建议

### 1. 数据备份

```bash
# 添加数据库备份定时任务
# 每天凌晨2点备份
(crontab -l; echo "0 2 * * * docker exec safe-postgres pg_dump -U postgres safe_transaction_db | gzip > /home/ubuntu/backups/db-\$(date +\%Y\%m\%d).sql.gz") | crontab -

# 创建备份目录
mkdir -p /home/ubuntu/backups

# 删除30天前的备份
(crontab -l; echo "0 3 * * * find /home/ubuntu/backups -name 'db-*.sql.gz' -mtime +30 -delete") | crontab -
```

### 2. 日志轮转

```bash
# PM2 自动管理日志，但可以手动清理
pm2 flush  # 清空所有日志

# 或者设置日志大小限制
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 100M
pm2 set pm2-logrotate:retain 7
```

### 3. 安全更新

```bash
# 定期更新系统包
sudo apt update && sudo apt upgrade -y

# 更新 Docker 镜像
cd /home/ubuntu/safe-space/safe-deploy-guide
docker-compose -f config/docker-compose-hetu-safe.yml pull
docker-compose -f config/docker-compose-hetu-safe.yml up -d
```

### 4. 监控告警

考虑安装监控工具：

```bash
# 安装 netdata (可选)
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# 访问 http://YOUR_IP:19999 查看监控面板
```

## 📞 紧急联系和恢复

### 完全恢复流程

如果所有服务都失败，按以下顺序恢复：

```bash
# 1. 停止所有服务
pm2 delete all
docker stop $(docker ps -aq)

# 2. 启动 Docker 基础服务
cd /home/ubuntu/safe-space/safe-deploy-guide
docker-compose -f config/docker-compose-hetu-safe.yml up -d postgres postgres-gateway redis rabbitmq

# 3. 等待基础服务就绪
sleep 30

# 4. 确保 Redis 是 Master
docker exec safe-redis redis-cli SLAVEOF NO ONE

# 5. 启动应用服务
docker-compose -f config/docker-compose-hetu-safe.yml up -d

# 6. 等待应用服务就绪
sleep 30

# 7. 重启 Gateway（确保连接正确）
docker restart safe-client-gateway

# 8. 启动 Next.js
cd /home/ubuntu/safe-space/safe-wallet-web
pm2 start ecosystem.config.js
pm2 save

# 9. 验证所有服务
pm2 list
docker ps
curl "http://localhost:3002/api/gateway/v1/chains" | jq
```

## 🎯 总结

✅ **Docker 容器**: 9个全部配置自动重启  
✅ **Next.js 服务**: PM2 管理 + 开机自启  
✅ **自动监控**: 每5分钟检查 + 自动修复  
✅ **日志系统**: 完整的日志记录  
✅ **故障恢复**: 自动重启 + 手动流程  

**您的服务现在将持续稳定运行！** 🚀

---

**配置日期**: 2025-10-17  
**配置人**: GitHub Copilot  
**验证状态**: ✅ 全部通过  

**相关文档**:
- 详细指南: `/home/ubuntu/safe-space/SERVICE_PERSISTENCE_GUIDE.md`
- 监控脚本: `/home/ubuntu/safe-space/monitor-services.sh`
- PM2 配置: `/home/ubuntu/safe-space/safe-wallet-web/ecosystem.config.js`
