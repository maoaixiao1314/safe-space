# ✅ Connect Wallet 修复 - 最终解决方案

## 🎯 问题确认

- ✅ API 代理工作正常：http://13.250.19.178:3002/api/gateway/v1/chains
- ✅ 链配置返回正确：Hetu (Chain ID: 560000)
- ✅ .env 配置正确：使用 `/api/gateway` 路径

**问题原因：** `.env` 文件修改后需要重启 Next.js 服务器才能生效。

## 🔧 立即修复（3 步）

### 步骤 1：重启 Next.js 服务器

找到当前运行的服务器终端窗口，按 `Ctrl+C` 停止，然后重启：

```bash
cd /home/ubuntu/safe-space/safe-wallet-web
PORT=3002 yarn dev
```

**如果想在后台运行（推荐）：**

```bash
# 使用 screen
screen -S safe-web
cd /home/ubuntu/safe-space/safe-wallet-web
PORT=3002 yarn dev
# 按 Ctrl+A 然后按 D 分离会话
# 重新连接: screen -r safe-web
```

或者使用 PM2：

```bash
npm install -g pm2
cd /home/ubuntu/safe-space/safe-wallet-web
pm2 start "yarn dev" --name safe-web -- --port 3002
pm2 save
pm2 startup  # 设置开机自启
```

### 步骤 2：清除浏览器缓存

在您的浏览器中（访问 http://13.250.19.178:3002）：

1. 打开开发者工具 (F12)
2. 右键点击刷新按钮
3. 选择 **"清空缓存并硬性重新加载"**

或者直接：
- Chrome/Edge: `Ctrl+Shift+Delete` → 清除缓存
- Firefox: `Ctrl+Shift+Delete` → 清除缓存

### 步骤 3：测试连接

1. 访问：http://13.250.19.178:3002
2. 打开开发者工具 (F12)
3. 点击 "Connect wallet" 按钮

**预期结果：**
- ✅ 控制台显示：`🔧 useLoadChains: { dataLength: 1, isLoading: false }`
- ✅ 控制台显示：`🔧 useInitOnboard: Chain configs loaded: 1 chains`
- ✅ 出现钱包选择界面
- ✅ Network 标签显示：`/api/gateway/v1/chains` → 200 OK

## 🔍 验证检查清单

### 服务器端检查（在 EC2 上执行）

```bash
# 1. 检查 .env 配置
grep "GATEWAY_URL" /home/ubuntu/safe-space/safe-wallet-web/apps/web/.env
# 应该显示: NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway

# 2. 测试 API 代理
curl "http://localhost:3002/api/gateway/v1/chains?cursor=limit=1" | jq '.results[0].chainId'
# 应该显示: "560000"

# 3. 检查服务器是否运行
lsof -i:3002
# 应该显示 node 进程
```

### 浏览器端检查（在本地电脑）

```bash
# 从本地电脑测试
curl "http://13.250.19.178:3002/api/gateway/v1/chains?cursor=limit=1" | jq '.results[0]'
```

打开浏览器访问 http://13.250.19.178:3002

**开发者工具 Console 标签应该显示：**
```
🔧 useLoadChains: {
  dataLength: 1,
  isLoading: false,
  chains: [{chainId: "560000", chainName: "Hetu"}]
}
🔧 useInitOnboard: Chain configs loaded: 1 chains
🔧 useInitOnboard: Current chain: 560000 Hetu
```

**开发者工具 Network 标签应该显示：**
```
/api/gateway/v1/chains?cursor=limit%3D40
Status: 200
Type: fetch
```

## 🐛 故障排查

### 问题 1：仍然显示 "hasConfigs: false"

**原因：** 浏览器缓存了旧的 JavaScript 代码

**解决：**
1. 硬性刷新：`Ctrl+Shift+R` (Windows/Linux) 或 `Cmd+Shift+R` (Mac)
2. 或者清空缓存：`Ctrl+Shift+Delete`
3. 或者使用隐身/无痕模式测试

### 问题 2：Network 标签显示 404

**检查：**
```bash
# 在 EC2 上测试
curl "http://localhost:3002/api/gateway/v1/chains"
```

如果返回 404，检查：
1. API 代理文件是否存在：
   ```bash
   ls -la /home/ubuntu/safe-space/safe-wallet-web/apps/web/src/pages/api/gateway/\[...path\].ts
   ```
2. Next.js 是否正确启动

### 问题 3：CORS 错误

API 代理已配置 CORS，不应该出现此错误。如果出现：

1. 检查浏览器控制台的完整错误信息
2. 确认访问的是 http://13.250.19.178:3002 而不是其他域名

### 问题 4：服务器重启后仍然不工作

**完整重启流程：**
```bash
# 1. 停止所有相关服务
pkill -f "yarn dev"
pkill -f "next-server"

# 2. 清理构建缓存
cd /home/ubuntu/safe-space/safe-wallet-web
rm -rf apps/web/.next
rm -rf node_modules/.cache

# 3. 重新启动
PORT=3002 yarn dev
```

## 📊 成功案例日志

**修复后的正常日志流程：**

```
浏览器访问: http://13.250.19.178:3002
    ↓
前端加载，读取环境变量: NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=/api/gateway
    ↓
前端发起请求: /api/gateway/v1/chains?cursor=limit=40
    ↓
Next.js API 代理接收请求
    ↓
代理转发到: http://localhost:3001/v1/chains?cursor=limit=40
    ↓
Gateway 服务返回链配置
    ↓
代理返回给浏览器
    ↓
🔧 useLoadChains: { dataLength: 1 } ✅
🔧 useInitOnboard: Chain configs loaded ✅
    ↓
用户点击 "Connect wallet"
    ↓
初始化 Onboard
    ↓
显示钱包选择界面 ✅
```

## 🎉 验证成功标志

当您看到以下内容时，说明修复成功：

1. ✅ 浏览器控制台无错误
2. ✅ Network 标签显示 `/api/gateway/v1/chains` 返回 200
3. ✅ Console 显示 `dataLength: 1`
4. ✅ 点击 "Connect wallet" 出现钱包选择界面
5. ✅ 能够选择 MetaMask 等钱包

## 📞 需要帮助？

如果按照以上步骤仍然无法解决：

1. **检查服务器日志：**
   ```bash
   # 查看 Next.js 日志（如果使用 PM2）
   pm2 logs safe-web
   
   # 或者直接查看终端输出
   ```

2. **提供以下信息：**
   - 浏览器控制台完整错误信息
   - Network 标签中的请求详情
   - 服务器端测试结果

3. **运行诊断脚本：**
   ```bash
   /home/ubuntu/safe-space/safe-wallet-web/check-ec2-status.sh
   ```

---

## 🚀 快速命令参考

```bash
# 重启服务器
cd /home/ubuntu/safe-space/safe-wallet-web
# Ctrl+C 停止当前服务
PORT=3002 yarn dev

# 测试 API
curl "http://13.250.19.178:3002/api/gateway/v1/chains?cursor=limit=1" | jq

# 检查进程
lsof -i:3002

# 查看配置
cat apps/web/.env | grep GATEWAY_URL
```

---

**重要提示：** 
- ✅ **修改 .env 后必须重启服务器**
- ✅ **重启后建议清除浏览器缓存**
- ✅ **使用硬性刷新 (Ctrl+Shift+R)**

**当前配置：**
- 🌐 公网访问：http://13.250.19.178:3002
- 🔗 API 代理：/api/gateway
- ⛓️ 链 ID：560000 (Hetu)
