# ✅ Connect Wallet 问题完整修复方案

## 📋 问题总结

**主要问题：** 首页点击 "Connect Wallet" 按钮无法打开 MetaMask

**根本原因：**
1. ❌ **Onboard 未初始化** - 点击按钮时钱包连接库还未准备好
2. ❌ **链配置加载失败** - Gateway API 代理配置错误，无法获取链数据
3. ❌ **变量命名冲突** - `WalletLogin.tsx` 中 `buttonText` 变量重复声明

## 🔧 已修复的文件

### 1. 核心逻辑修复

#### `apps/web/src/components/common/ConnectWallet/useConnectWallet.ts`
- ✅ 添加自动初始化 Onboard 逻辑
- ✅ 智能检测并等待链配置加载
- ✅ 完整的错误处理和日志

#### `apps/web/src/components/common/ConnectWallet/ConnectWalletButton.tsx`
- ✅ 添加 `isInitializing` 状态管理
- ✅ 防止重复点击
- ✅ 显示初始化状态

#### `apps/web/src/components/welcome/WelcomeLogin/WalletLogin.tsx`
- ✅ 修复 `buttonText` 变量命名冲突（改为 `buttonLabel`）
- ✅ 添加链配置加载等待逻辑
- ✅ 显示加载状态

### 2. 配置修复

#### `apps/web/.env`
- ✅ 修改 Gateway URL 为直接连接：`http://localhost:3001`
- ✅ 移除有问题的 API 代理路径

#### `apps/web/config/chains/hetu.json`
- ✅ 创建 Hetu 链本地配置文件（作为fallback）

#### `apps/web/src/hooks/wallets/useOnboard.ts`
- ✅ 导出 `getStore` 函数供外部访问
- ✅ 添加详细的调试日志

## 🚀 修复后的工作流程

```
用户点击 "Connect Wallet"
        ↓
检查 Onboard 是否就绪
        ↓
    [否] → 检查链配置是否加载
              ↓
          [否] → 等待链配置加载
                    ↓
          [是] → 初始化 Onboard
                    ↓
    [是] → 调用 connectWallet()
              ↓
    显示钱包选择界面 (MetaMask, WalletConnect, 等)
```

## 📝 使用说明

### 1. 启动开发服务器

```bash
cd /home/ubuntu/safe-space/safe-wallet-web

# 如果服务器正在运行，先停止 (Ctrl+C)
yarn dev
```

### 2. 访问应用

打开浏览器访问: http://localhost:3000

### 3. 测试连接

1. 打开浏览器开发者工具 (F12)
2. 点击首页的 "Connect wallet" 按钮
3. 查看控制台日志和钱包选择界面

## ✅ 验证清单

运行验证脚本:
```bash
/home/ubuntu/safe-space/safe-wallet-web/test-gateway-fix.sh
```

手动验证:
- [ ] Gateway 服务正常 (http://localhost:3001/v1/chains)
- [ ] 环境变量配置正确
- [ ] 开发服务器已重启
- [ ] 点击 "Connect wallet" 能打开钱包选择界面
- [ ] 控制台显示正确的初始化日志
- [ ] 能够成功连接 MetaMask

## 📊 预期的控制台日志

```
🔧 useLoadChains: { dataLength: 1, isLoading: false }
🔧 useInitOnboard: Chain configs loaded: 1 chains
🔧 useInitOnboard: Current chain: 560000 Hetu
🔧 WalletLogin: Connect wallet button clicked
🔧 useConnectWallet: Attempting to connect wallet
🔧 useConnectWallet: Onboard not ready, initializing...
🔧 initOnboard: Starting initialization...
🔧 initOnboard: Creating new Onboard instance
🔧 Onboard: Configuring chains
🔧 useConnectWallet: Onboard initialized successfully
🔧 useConnectWallet: Connecting with new Onboard instance
```

## 🐛 故障排查

### 问题：链配置仍然无法加载

**解决方案：**
1. 检查 Gateway 服务是否运行：
   ```bash
   curl http://localhost:3001/v1/chains?cursor=limit=1
   ```

2. 重启 Gateway 服务（如果需要）

### 问题：点击按钮没有反应

**检查：**
1. 浏览器控制台是否有 JavaScript 错误
2. 是否重启了开发服务器
3. 链配置是否正确加载（查看控制台日志）

### 问题：钱包选择界面不出现

**检查：**
1. 是否安装了 MetaMask 或其他钱包扩展
2. 浏览器是否阻止了弹窗
3. 控制台是否显示 "Connecting with new Onboard instance"

## 📦 相关文档

- [CONNECT_WALLET_FIX.md](./CONNECT_WALLET_FIX.md) - Onboard 初始化问题修复
- [GATEWAY_FIX.md](./GATEWAY_FIX.md) - Gateway API 配置问题修复
- [test-connect-wallet.md](./test-connect-wallet.md) - 详细测试指南
- [test-gateway-fix.sh](./test-gateway-fix.sh) - 自动验证脚本

## 🎯 技术要点

### 1. 异步初始化处理

```typescript
// 等待链配置加载完成
if (!onboard && !chainsLoading && configs.length > 0 && chain) {
  await initOnboard(configs, chain, customRpc)
  // 等待状态更新后连接
  const newOnboard = getStore()
  return connectWallet(newOnboard)
}
```

### 2. 防重复初始化

```typescript
let isInitializing = false

if (!isInitializing && !onboard) {
  isInitializing = true
  // 初始化逻辑
  isInitializing = false
}
```

### 3. Gateway API 直连

```env
# 直接连接，避免代理问题
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL_STAGING=http://localhost:3001
```

## 🎉 预期结果

修复后，用户应该能够：

1. ✅ 在首页直接点击 "Connect wallet"
2. ✅ 看到钱包选择界面（包括 MetaMask、WalletConnect 等）
3. ✅ 成功连接 MetaMask 或其他钱包
4. ✅ 在整个应用中正常使用钱包功能

## 📞 支持

如果遇到问题：
1. 查看浏览器控制台日志
2. 运行验证脚本: `./test-gateway-fix.sh`
3. 检查 Gateway 服务状态
4. 确认已重启开发服务器

---

**修复日期：** 2025-10-16  
**版本：** 1.0.0  
**状态：** ✅ 完成

**重要提示：** 修改 `.env` 文件后，必须重启开发服务器才能生效！
