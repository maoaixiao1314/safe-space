# ✅ 服务持续运行配置完成

## 🎯 问题解决

已成功配置所有服务持续运行，不会因为服务器重启、终端断开或进程崩溃而停止。

## ✅ 已完成的配置

### 1. Docker 容器自动重启 ✅

所有 Safe 相关的 Docker 容器已配置为 `restart: unless-stopped`：

```bash
✅ safe-client-gateway
✅ safe-transaction-service  
✅ safe-transaction-worker
✅ safe-transaction-scheduler
✅ safe-config-service
✅ safe-postgres
✅ safe-postgres-gateway
✅ safe-redis
✅ safe-rabbitmq
```

**特性：**
- 容器崩溃时自动重启
- 服务器重启后自动启动
- Docker daemon 重启后自动启动

### 2. Next.js 使用 PM2 管理 ✅

Next.js 服务现在由 PM2 进程管理器管理：

```bash
✅ 进程名称: safe-web
✅ 端口: 3002
✅ 自动重启: 启用
✅ 开机自启: 已配置
✅ 日志记录: /home/ubuntu/safe-space/logs/
```

**特性：**
- 进程崩溃自动重启
- 内存超限自动重启（限制：2GB）
- 终端断开继续运行
- 服务器重启自动启动
- 完整的日志记录

**PM2 配置文件：** `/home/ubuntu/safe-space/safe-wallet-web/ecosystem.config.js`

### 3. 自动监控服务 ✅

定时任务每 5 分钟检查一次所有服务：

```bash
✅ 监控脚本: /home/ubuntu/safe-space/monitor-services.sh
✅ 定时任务: */5 * * * * (每5分钟)
✅ 监控日志: /home/ubuntu/safe-space/logs/monitor.log
✅ 定时日志: /home/ubuntu/safe-space/logs/cron.log
```

**监控内容：**
- 检查所有 Docker 容器状态
- 检查 Next.js PM2 进程状态
- 检查 Redis 是否为 master 模式
- 自动重启失败的服务

### 4. 开机自启动 ✅

```bash
✅ Docker 容器: 自动启动
✅ PM2 服务: systemd 服务已配置
✅ 监控任务: crontab 自动运行
```

## 📊 服务架构

```
EC2 服务器重启/断电
        ↓
系统启动 systemd
        ↓
    ┌───────────────────────────────────┐
    │                                   │
Docker 自动启动              PM2 systemd 服务启动
    │                                   │
    ↓                                   ↓
所有容器自动运行              Next.js 自动运行
    │                                   │
    ├─ safe-client-gateway         safe-web (端口 3002)
    ├─ safe-transaction-service         │
    ├─ safe-transaction-worker          │
    ├─ safe-transaction-scheduler       │
    ├─ safe-config-service              │
    ├─ safe-postgres                    │
    ├─ safe-postgres-gateway            │
    ├─ safe-redis                       │
    └─ safe-rabbitmq                    │
                                        ↓
                            crontab 定时任务启动
                                        │
                                        ↓
                        每5分钟检查所有服务
                                        │
                                        ↓
                        发现故障 → 自动重启
```

## 📝 常用命令

### PM2 管理

```bash
# 查看所有进程
pm2 list

# 查看 Next.js 日志
pm2 logs safe-web

# 实时查看日志
pm2 logs safe-web --lines 100

# 重启 Next.js
pm2 restart safe-web

# 停止 Next.js
pm2 stop safe-web

# 启动 Next.js
pm2 start safe-web

# 查看进程详情
pm2 show safe-web

# 查看监控面板
pm2 monit
```

### Docker 管理

```bash
# 查看所有容器
docker ps

# 查看容器日志
docker logs safe-client-gateway
docker logs safe-client-gateway --tail 50 -f

# 重启容器
docker restart safe-client-gateway

# 重启所有 Safe 容器
docker restart safe-client-gateway safe-transaction-service safe-transaction-worker safe-transaction-scheduler safe-config-service

# 查看容器资源使用
docker stats

# 检查容器重启策略
docker inspect safe-client-gateway | grep -A 3 RestartPolicy
```

### 监控服务

```bash
# 手动运行监控检查
/home/ubuntu/safe-space/monitor-services.sh

# 查看监控日志
tail -f /home/ubuntu/safe-space/logs/monitor.log

# 查看定时任务日志
tail -f /home/ubuntu/safe-space/logs/cron.log

# 查看定时任务配置
crontab -l

# 测试定时任务
/home/ubuntu/safe-space/monitor-services.sh
```

### 服务状态检查

```bash
# 检查所有服务状态
/home/ubuntu/safe-space/safe-wallet-web/check-ec2-status.sh

# 检查 PM2 状态
pm2 status

# 检查 Docker 状态
docker ps --format "table {{.Names}}\t{{.Status}}"

# 检查 Redis 模式
docker exec safe-redis redis-cli INFO replication | grep role

# 测试 API
curl http://localhost:3002/api/gateway/v1/chains | jq '.results[0].chainId'
```

## 🔍 故障排查

### 问题 1：Next.js 没有自动重启

```bash
# 检查 PM2 进程
pm2 list

# 如果进程不在列表中
cd /home/ubuntu/safe-space/safe-wallet-web
pm2 start ecosystem.config.js

# 保存配置
pm2 save
```

### 问题 2：服务器重启后服务没有启动

```bash
# 检查 PM2 systemd 服务
sudo systemctl status pm2-ubuntu

# 如果未启用
sudo systemctl enable pm2-ubuntu
sudo systemctl start pm2-ubuntu

# 检查 Docker 容器
docker ps -a | grep safe

# 手动启动容器
docker start safe-client-gateway
```

### 问题 3：定时任务没有运行

```bash
# 检查 cron 服务
sudo systemctl status cron

# 查看 crontab
crontab -l

# 重新添加定时任务
(crontab -l 2>/dev/null | grep -v "monitor-services.sh"; echo "*/5 * * * * /home/ubuntu/safe-space/monitor-services.sh >> /home/ubuntu/safe-space/logs/cron.log 2>&1") | crontab -
```

### 问题 4：Redis 又变成 slave 模式

监控脚本会自动修复，但如果需要手动修复：

```bash
docker exec safe-redis redis-cli SLAVEOF NO ONE
docker restart safe-client-gateway
```

### 问题 5：内存不足导致进程被杀

```bash
# 查看系统内存
free -h

# 查看 Docker 容器内存使用
docker stats

# 查看 PM2 进程内存
pm2 list

# 如果内存不足，可以调整 PM2 配置
# 编辑: /home/ubuntu/safe-space/safe-wallet-web/ecosystem.config.js
# 修改: max_memory_restart: '1G'  # 改小一点
```

## 📊 日志位置

```
/home/ubuntu/safe-space/logs/
├── safe-web-error.log      # Next.js 错误日志
├── safe-web-out.log        # Next.js 输出日志
├── monitor.log             # 监控脚本日志
└── cron.log                # 定时任务日志

Docker 容器日志：
docker logs <container-name>

PM2 日志：
~/.pm2/logs/
```

## 🎉 验证配置

### 1. 测试服务当前状态

```bash
# 所有服务应该都在运行
pm2 list
docker ps

# 应该看到
✅ PM2: safe-web (online)
✅ Docker: 9个容器都在运行
```

### 2. 测试自动重启

```bash
# 测试 PM2 自动重启
pm2 stop safe-web
sleep 5
pm2 list  # 应该自动重启

# 测试 Docker 自动重启
docker stop safe-client-gateway
sleep 10
docker ps | grep safe-client-gateway  # 应该自动重启
```

### 3. 测试监控脚本

```bash
# 停止一个服务
pm2 stop safe-web

# 运行监控脚本
/home/ubuntu/safe-space/monitor-services.sh

# 检查是否自动重启
pm2 list  # 应该是 online 状态
```

### 4. 模拟服务器重启

```bash
# 不用真的重启，检查配置即可
sudo systemctl is-enabled pm2-ubuntu  # 应该返回 enabled
docker inspect safe-client-gateway | grep RestartPolicy  # 应该是 unless-stopped
crontab -l | grep monitor-services  # 应该有定时任务
```

## 🔒 安全建议

1. **定期备份数据库**
   ```bash
   # 添加数据库备份定时任务
   # 每天凌晨2点备份
   0 2 * * * docker exec safe-postgres pg_dump -U postgres safe_transaction_db > /home/ubuntu/backups/db-$(date +\%Y\%m\%d).sql
   ```

2. **日志轮转**
   ```bash
   # PM2 日志会自动轮转，但建议定期清理旧日志
   pm2 flush  # 清空所有日志
   ```

3. **监控资源使用**
   ```bash
   # 建议安装 htop 监控资源
   sudo apt install htop
   htop
   ```

## 📞 紧急情况处理

### 如果所有服务都挂了：

```bash
# 1. 重启所有 Docker 容器
cd /home/ubuntu/safe-space/safe-deploy-guide
docker-compose -f config/docker-compose-hetu-safe.yml restart

# 2. 确保 Redis 是 master 模式
docker exec safe-redis redis-cli SLAVEOF NO ONE

# 3. 重启 Next.js
pm2 restart safe-web

# 4. 检查状态
docker ps
pm2 list
curl http://localhost:3002/api/gateway/v1/chains
```

### 如果需要完全重新启动：

```bash
# 停止所有服务
docker stop $(docker ps -q --filter "name=safe-")
pm2 delete all

# 重新启动
cd /home/ubuntu/safe-space/safe-deploy-guide
docker-compose -f config/docker-compose-hetu-safe.yml up -d

# 等待服务启动
sleep 30

# 确保 Redis 是 master
docker exec safe-redis redis-cli SLAVEOF NO ONE
docker restart safe-client-gateway

# 启动 Next.js
cd /home/ubuntu/safe-space/safe-wallet-web
pm2 start ecosystem.config.js
pm2 save
```

## 🎯 总结

✅ **Docker 容器**: 9个容器，全部配置自动重启  
✅ **Next.js 服务**: PM2 管理，自动重启 + 开机自启  
✅ **监控服务**: 每5分钟自动检查，发现问题自动修复  
✅ **开机自启**: 服务器重启后所有服务自动启动  
✅ **日志记录**: 完整的日志系统，便于排查问题  

**现在您可以放心了！所有服务将持续运行，不会因为任何原因停止。** 🚀
