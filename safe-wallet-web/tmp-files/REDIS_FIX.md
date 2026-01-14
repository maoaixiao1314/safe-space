# ✅ Redis 问题修复完成

## 🎯 问题原因

Gateway 服务返回 **503 Service Unavailable**，日志显示：
```
ReplyError: READONLY You can't write against a read only replica
```

**根本原因：** Redis 容器被错误地配置为 **slave（从节点）** 模式，导致只读，Gateway 服务无法写入数据。

## 🔧 修复步骤

### 1. 检查 Redis 角色
```bash
docker exec safe-redis redis-cli INFO replication | grep role
# 结果: role:slave ❌
```

### 2. 将 Redis 改为 Master 模式
```bash
docker exec safe-redis redis-cli SLAVEOF NO ONE
# 结果: OK ✅
```

### 3. 确认修复
```bash
docker exec safe-redis redis-cli INFO replication | grep role
# 结果: role:master ✅
```

### 4. 重启 Gateway 服务
```bash
docker restart safe-client-gateway
```

### 5. 验证 API 正常
```bash
# 直接访问 Gateway
curl "http://localhost:3001/v1/chains?cursor=limit=1" | jq '.results[0].chainId'
# 结果: "560000" ✅

# 通过 Next.js API 代理访问
curl "http://localhost:3002/api/gateway/v1/chains?cursor=limit=1" | jq '.results[0].chainId'
# 结果: "560000" ✅
```

## ✅ 当前状态

- ✅ Redis 已改为 master 模式（可读写）
- ✅ Gateway API 正常返回链配置
- ✅ API 代理正常工作
- ✅ 前端应该能够加载链配置

## 🧪 测试 Connect Wallet

现在前端应该可以正常连接钱包了！

### 测试步骤：

1. **清除浏览器缓存**（重要！）
   - 打开 http://13.250.19.178:3002
   - 按 `Ctrl+Shift+R` 强制刷新
   - 或者使用无痕模式

2. **打开开发者工具** (F12)

3. **点击 "Connect wallet" 按钮**

4. **预期结果：**
   ```
   Console 应该显示:
   ✅ 🔧 useLoadChains: { dataLength: 1, isLoading: false }
   ✅ 🔧 useInitOnboard: Chain configs loaded: 1 chains
   ✅ 🔧 useConnectWallet: Ready to connect
   
   Network 标签应该显示:
   ✅ /api/gateway/v1/chains → 200 OK
   
   界面应该:
   ✅ 出现钱包选择对话框（MetaMask、WalletConnect 等）
   ```

## 📋 问题回顾

整个问题的解决链条：

1. ❌ **问题 1：** Connect Wallet 按钮不工作
   - **原因：** Onboard 初始化时机问题
   - **修复：** 添加自动初始化逻辑 ✅

2. ❌ **问题 2：** `hasConfigs: false`
   - **原因：** Gateway URL 使用 localhost:3001（EC2 环境错误）
   - **修复：** 改用 Next.js API 代理 `/api/gateway` ✅

3. ❌ **问题 3：** Gateway 返回 503
   - **原因：** Redis 配置为 slave 模式（只读）
   - **修复：** 改为 master 模式 ✅

## 🔒 永久修复（防止重启后问题复现）

Redis 的 `SLAVEOF NO ONE` 命令只是临时的，如果容器重启会丢失。

### 方法 1：修改 Docker Compose 配置

编辑 `/home/ubuntu/safe-space/safe-deploy-guide/config/docker-compose-hetu-safe.yml`：

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: safe-redis
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes  # 确保是主节点
    # 移除任何 --slaveof 参数
```

### 方法 2：创建 Redis 配置文件

创建 `/home/ubuntu/safe-space/safe-deploy-guide/config/redis.conf`：
```
# Redis 配置
bind 0.0.0.0
protected-mode no
appendonly yes
# 不要添加 slaveof 指令
```

然后在 docker-compose 中使用：
```yaml
services:
  redis:
    image: redis:7-alpine
    volumes:
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
```

### 方法 3：启动脚本检查

在 Gateway 启动脚本中添加检查：
```bash
#!/bin/bash
# 确保 Redis 是 master 模式
docker exec safe-redis redis-cli SLAVEOF NO ONE
docker restart safe-client-gateway
```

## 🎉 成功标志

当您看到以下内容时，说明完全修复成功：

1. ✅ `docker exec safe-redis redis-cli INFO replication | grep role` → `role:master`
2. ✅ `curl localhost:3001/v1/chains` → 返回 JSON，不是 503
3. ✅ `curl localhost:3002/api/gateway/v1/chains` → 返回 JSON
4. ✅ 浏览器控制台显示 `hasConfigs: true`
5. ✅ 点击 Connect Wallet 出现钱包选择界面

## 📞 故障排查

### 如果仍然不工作：

1. **检查 Redis 状态：**
   ```bash
   docker exec safe-redis redis-cli PING
   docker exec safe-redis redis-cli INFO replication
   ```

2. **检查 Gateway 日志：**
   ```bash
   docker logs safe-client-gateway --tail 50
   # 不应该再有 "READONLY" 错误
   ```

3. **重新应用修复：**
   ```bash
   docker exec safe-redis redis-cli SLAVEOF NO ONE
   docker restart safe-client-gateway
   sleep 5
   curl "http://localhost:3001/v1/chains"
   ```

---

**修复时间：** 2025-10-17  
**修复内容：** Redis slave → master，Gateway 503 → 200 OK
