# Connect Wallet 功能测试指南

## 快速测试步骤

### 1. 启动开发服务器

```bash
cd /home/ubuntu/safe-space/safe-wallet-web
yarn dev
```

### 2. 打开浏览器控制台

访问 `http://localhost:3000` 并打开浏览器开发者工具（F12）

### 3. 测试场景

#### 场景 1: 首页直接连接（主要问题场景）

1. 清空浏览器缓存和本地存储
2. 访问 `http://localhost:3000`
3. 应该看到欢迎页面和 "Connect wallet" 按钮
4. 点击 "Connect wallet" 按钮
5. **预期结果：**
   - 按钮文字变为 "Connecting..."
   - 控制台显示初始化日志
   - 弹出钱包选择界面
   - 能够选择 MetaMask 等钱包

#### 场景 2: 检查控制台日志

点击按钮后，应该看到以下日志序列：

```
🔧 WalletLogin: Connect wallet button clicked
🔧 useConnectWallet: Attempting to connect wallet
🔧 useConnectWallet: Onboard not ready, initializing...
🔧 initOnboard: Starting initialization...
🔧 initOnboard: Chain configs: X
🔧 initOnboard: Current chain: 560000
🔧 initOnboard: Creating new Onboard instance
🔧 Onboard: Configuring chains: [...]
🔧 Onboard: Available wallets: 5
🔧 initOnboard: Onboard instance created successfully
🔧 useConnectWallet: Onboard initialized successfully
🔧 useConnectWallet: Connecting with new Onboard instance
```

#### 场景 3: 重复点击测试

1. 快速连续点击 "Connect wallet" 按钮 3-5 次
2. **预期结果：**
   - 只有第一次点击生效
   - 按钮在处理时禁用
   - 不会出现多个钱包选择弹窗
   - 控制台没有重复初始化日志

#### 场景 4: MetaMask 连接测试

1. 确保已安装 MetaMask 浏览器扩展
2. 点击 "Connect wallet"
3. 在钱包选择界面选择 "MetaMask"
4. **预期结果：**
   - MetaMask 弹出连接请求
   - 批准后成功连接
   - 页面显示已连接的钱包地址

#### 场景 5: 刷新页面后重连

1. 连接钱包后刷新页面
2. **预期结果：**
   - 自动重新连接最后使用的钱包
   - 或者显示 "Connect wallet" 按钮可以再次连接

## 预期的浏览器控制台输出

### 成功场景

```
✅ 🔧 WalletLogin: Connect wallet button clicked
✅ 🔧 useConnectWallet: Attempting to connect wallet { onboard: false, configs: 1, chain: '560000', isInitializing: false }
✅ 🔧 useConnectWallet: Onboard not ready, initializing...
✅ 🔧 initOnboard: Starting initialization...
✅ 🔧 initOnboard: Chain configs: 1
✅ 🔧 initOnboard: Current chain: 560000
✅ 🔧 initOnboard: Creating new Onboard instance
✅ 🔧 Onboard: Configuring chains: [{ id: '0x88b80', label: 'Hetu', rpcUrl: 'http://161.97.161.133:18545' }]
✅ 🔧 Onboard: Available wallets: 5
✅ 🔧 initOnboard: Onboard instance created successfully
✅ 🔧 useConnectWallet: Onboard initialized successfully
✅ 🔧 useConnectWallet: Connecting with new Onboard instance
```

### 错误场景（如果有问题）

```
❌ 🔧 useConnectWallet: Cannot connect - missing requirements { isInitializing: false, hasConfigs: false, hasChain: false }
❌ 🔧 useConnectWallet: Initialization failed: [error details]
❌ 🔧 useConnectWallet: Connection failed after init: [error details]
```

## 常见问题排查

### 问题 1: 点击按钮没有反应

**检查：**
1. 浏览器控制台是否有错误
2. 是否看到 "🔧 WalletLogin: Connect wallet button clicked" 日志
3. 检查 chain configs 是否加载（应该 > 0）

**解决：**
- 确保 `.env` 配置正确
- 重启开发服务器
- 清空浏览器缓存

### 问题 2: 初始化失败

**检查控制台错误信息：**
- Network 错误：检查 RPC URL 配置
- Configuration 错误：检查 chain configs
- Module 错误：确保所有依赖已安装

### 问题 3: 钱包选择界面不出现

**检查：**
1. 是否看到 "Connecting with new Onboard instance" 日志
2. 浏览器是否阻止了弹窗
3. 是否安装了钱包扩展（如 MetaMask）

### 问题 4: WalletConnect 不工作

**原因：**
- `.env` 中 `NEXT_PUBLIC_WC_PROJECT_ID` 未配置

**解决：**
1. 访问 https://cloud.walletconnect.com
2. 注册账号并创建项目
3. 获取 Project ID
4. 在 `.env` 中添加：
   ```
   NEXT_PUBLIC_WC_PROJECT_ID=your_project_id_here
   ```
5. 重启开发服务器

## 验证清单

- [ ] 首页能打开钱包选择界面
- [ ] MetaMask 能正常连接
- [ ] 控制台日志正常
- [ ] 按钮状态正确（Loading 状态）
- [ ] 不会重复初始化
- [ ] 连接后显示钱包信息
- [ ] 刷新后能重连

## 性能检查

**初始化时间：**
- 应该在 200-500ms 内完成
- 如果超过 1 秒，检查网络或配置问题

**内存使用：**
- 正常情况下不应该有内存泄漏
- 多次连接/断开不应该导致内存持续增长

## 调试技巧

### 启用详细日志

所有 `console.log` 以 `🔧` 开头，可以在控制台过滤：

```
🔧
```

### 检查 Onboard 状态

在控制台运行：

```javascript
// 检查 Onboard 实例
window.__ONBOARD_STATE__

// 检查已连接的钱包
window.__ONBOARD_STATE__?.wallets
```

### 清除本地存储

```javascript
// 清除所有 Safe 相关存储
Object.keys(localStorage)
  .filter(key => key.startsWith('SAFE_v2__'))
  .forEach(key => localStorage.removeItem(key))

// 刷新页面
location.reload()
```

## 成功标志

当你看到以下情况，说明修复成功：

✅ 首页点击 "Connect wallet" 能打开钱包选择界面
✅ 控制台显示完整的初始化流程日志
✅ MetaMask 能够成功连接
✅ 按钮显示正确的加载状态
✅ 没有错误或警告信息

## 下一步

如果所有测试通过，可以：

1. 提交代码到 Git
2. 部署到测试环境
3. 进行更广泛的用户测试
4. 考虑添加 WalletConnect Project ID 支持更多钱包

## 联系支持

如果遇到问题：
1. 保存完整的控制台日志
2. 记录复现步骤
3. 提交 Issue 或联系开发团队
