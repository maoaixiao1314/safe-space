# AWS EC2 部署问题修复

## 🎯 问题分析

### 为什么在本地正常，在 EC2 上失败？

**本地开发环境：**
```
浏览器 → http://localhost:3000 (前端)
        ↓ 直接访问
     http://localhost:3001 (Gateway API)
```
✅ 一切正常，因为浏览器和服务都在同一台机器上

**EC2 部署环境：**
```
用户浏览器（在用户电脑上）
    ↓
http://EC2_PUBLIC_IP:3000 (前端，运行在 EC2)
    ↓ 前端代码配置: localhost:3001
用户电脑的 localhost:3001 ❌ (不存在！)
```
❌ 失败！浏览器中的 `localhost` 指向用户的电脑，而不是 EC2 服务器

## ✅ 解决方案：使用 Next.js API 代理

### 正确的架构

```
用户浏览器（在用户电脑上）
    ↓
http://EC2_PUBLIC_IP:3000/api/gateway/v1/chains
    ↓ (相对路径请求)
EC2 服务器的 Next.js (端口 3000)
    ↓ (服务器端代理)
localhost:3001 (Gateway API，在 EC2 内部)
    ↓
返回链配置数据
```

## 🔧 已修复的配置

### `.env` 文件修改

**修改前（直连模式 - 仅适用于本地）：**
```env
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL_STAGING=http://localhost:3001
```

**修改后（代理模式 - 适用于 EC2 部署）：**
```env
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway
NEXT_PUBLIC_GATEWAY_URL_STAGING=/api/gateway
```

### API 代理工作原理

文件：`apps/web/src/pages/api/gateway/[...path].ts`

```typescript
// 浏览器请求: /api/gateway/v1/chains
// ↓
// Next.js 接收并代理到: http://localhost:3001/v1/chains
// ↓
// 返回数据给浏览器
```

## 📋 部署步骤

### 1. 确认配置已修改

```bash
cd /home/ubuntu/safe-space/safe-wallet-web/apps/web
grep "GATEWAY_URL" .env
```

应该看到：
```
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway
NEXT_PUBLIC_GATEWAY_URL_STAGING=/api/gateway
```

### 2. 重启开发服务器

```bash
cd /home/ubuntu/safe-space/safe-wallet-web

# 停止当前服务器 (Ctrl+C)
# 然后重启
yarn dev
```

### 3. 验证修复

#### 方法 1：使用浏览器（推荐）

1. 在**本地电脑**的浏览器打开：
   ```
   http://EC2_PUBLIC_IP:3000
   ```

2. 打开浏览器开发者工具 (F12)

3. 点击 "Connect wallet" 按钮

4. 检查 Console 标签，应该看到：
   ```
   🔧 useLoadChains: { dataLength: 1, isLoading: false }
   🔧 useInitOnboard: Chain configs loaded: 1 chains
   ```

5. 检查 Network 标签，应该看到：
   ```
   /api/gateway/v1/chains → 200 OK
   ```

#### 方法 2：使用 curl 测试

从**本地电脑**测试（替换 `EC2_PUBLIC_IP`）：
```bash
curl http://EC2_PUBLIC_IP:3000/api/gateway/v1/chains?cursor=limit=1
```

应该返回链配置 JSON 数据

## 🔍 故障排查

### 问题 1：仍然无法加载链配置

**检查 Gateway 服务：**
```bash
# 在 EC2 服务器上执行
curl http://localhost:3001/v1/chains?cursor=limit=1
```

如果失败，重启 Gateway 服务：
```bash
cd /home/ubuntu/safe-space/safe-deploy-guide
docker-compose restart safe-client-gateway
```

### 问题 2：API 代理返回 404

**检查 Next.js 服务：**
```bash
# 在 EC2 服务器上执行
curl http://localhost:3000/api/gateway/v1/chains?cursor=limit=1
```

如果失败：
1. 确认 Next.js 开发服务器正在运行
2. 检查 API 代理文件是否存在：
   ```bash
   ls -la apps/web/src/pages/api/gateway/\[...path\].ts
   ```

### 问题 3：CORS 错误

API 代理已配置 CORS 头：
```typescript
res.setHeader('Access-Control-Allow-Origin', '*')
res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
```

如果仍有 CORS 问题，检查浏览器控制台的详细错误信息。

### 问题 4：浏览器无法访问 EC2 服务器

**检查 EC2 安全组：**
1. 登录 AWS 控制台
2. 找到 EC2 实例的安全组
3. 确保入站规则允许：
   - 端口 3000 (Next.js 前端)
   - 端口 18545 (Hetu RPC，如果需要)

**添加规则示例：**
```
类型: 自定义 TCP
端口: 3000
源: 0.0.0.0/0 (所有 IP，生产环境建议限制)
```

## 🎯 测试清单

从**本地电脑的浏览器**测试：

- [ ] 能够访问 `http://EC2_IP:3000`
- [ ] 能够访问 `http://EC2_IP:3000/api/gateway/v1/chains`
- [ ] 点击 "Connect wallet" 能打开钱包选择界面
- [ ] 控制台显示链配置加载成功
- [ ] Network 标签显示 API 请求成功

## 📝 重要提示

### 本地开发 vs EC2 部署

| 环境 | Gateway URL 配置 | 说明 |
|------|-----------------|------|
| **本地开发** | `http://localhost:3001` | 直连，浏览器和服务在同一台机器 |
| **EC2 部署** | `/api/gateway` | 代理，浏览器在远程访问 |

### 环境变量的作用范围

```typescript
// NEXT_PUBLIC_ 前缀的变量会被打包到前端代码中
// 在浏览器中运行
const url = process.env.NEXT_PUBLIC_GATEWAY_URL_PRODUCTION

// 没有 NEXT_PUBLIC_ 前缀的变量只在服务器端可用
// 不会暴露给浏览器
const secret = process.env.SECRET_KEY
```

## 🚀 生产环境建议

### 1. 使用环境变量区分环境

创建 `.env.production`：
```env
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway
NEXT_PUBLIC_GATEWAY_URL_STAGING=/api/gateway
```

创建 `.env.local`（本地开发）：
```env
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL_STAGING=http://localhost:3001
```

### 2. 使用 PM2 或 systemd 管理服务

```bash
# 使用 PM2
pm2 start "yarn dev" --name safe-wallet-web
pm2 save
pm2 startup
```

### 3. 配置 Nginx 反向代理（可选）

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 📞 快速测试命令

在 EC2 服务器上运行：
```bash
# 测试 Gateway 服务
curl http://localhost:3001/v1/chains?cursor=limit=1

# 测试 Next.js API 代理
curl http://localhost:3000/api/gateway/v1/chains?cursor=limit=1
```

从本地电脑运行（替换 EC2_IP）：
```bash
# 测试前端可访问性
curl http://EC2_IP:3000

# 测试 API 代理
curl http://EC2_IP:3000/api/gateway/v1/chains?cursor=limit=1
```

## ✅ 成功标志

修复成功后，从本地浏览器访问应该看到：

1. ✅ 首页正常加载
2. ✅ 点击 "Connect wallet" 出现钱包选择界面
3. ✅ 控制台日志显示链配置加载成功
4. ✅ Network 标签显示 `/api/gateway/v1/chains` 返回 200

---

**最后一步：** 确保修改 `.env` 后重启了 Next.js 开发服务器！

```bash
# 在 EC2 上执行
cd /home/ubuntu/safe-space/safe-wallet-web
# Ctrl+C 停止
yarn dev
```
