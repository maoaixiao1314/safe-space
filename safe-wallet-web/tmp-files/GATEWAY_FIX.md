# Connect Wallet 问题修复总结

## 问题诊断

### 错误信息
```
useConnectWallet: Cannot connect - missing requirements 
{isInitializing: false, hasConfigs: false, hasChain: false, chainsLoading: false}
```

### 根本原因

**链配置加载失败** - Gateway API 无法获取链配置数据

## 问题分析

1. **配置缺失：** `configs = []`，`chain = undefined`
2. **Gateway API 错误：** `/api/gateway/v1/chains` 返回 Blockscout 404 页面
3. **服务正常：** `http://localhost:3001` Gateway 服务运行正常并返回正确数据
4. **代理问题：** Next.js API 代理 `/api/gateway/[...path].ts` 配置可能有问题

## 解决方案

### 方案 1: 修复 Gateway API 代理 (推荐)

检查 `apps/web/src/pages/api/gateway/[...path].ts` 的配置，确保正确代理到 Gateway 服务。

### 方案 2: 使用客户端直连 (临时)

修改 `.env` 文件：

```env
# 直接连接到 Gateway 服务
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL_STAGING=http://localhost:3001
```

### 方案 3: 配置本地链配置文件 (备用)

已创建：`apps/web/config/chains/hetu.json`

在 `apps/web/src/hooks/loadables/useLoadChains.ts` 中添加本地fallback 逻辑。

## 快速修复步骤

1. **修改环境变量：**

```bash
cd /home/ubuntu/safe-space/safe-wallet-web/apps/web
```

编辑 `.env` 文件，修改：

```env
# 修改为直接连接 Gateway
NEXT_PUBLIC_GATEWAY_URL_PRODUCTION=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL_STAGING=http://localhost:3001
```

2. **重启开发服务器：**

```bash
# 停止当前服务器 (Ctrl+C)
yarn dev
```

3. **验证修复：**

打开浏览器开发者工具，检查：
- Network 标签：`/v1/chains` 请求应该返回 200 状态
- Console 标签：应该看到链配置加载日志

## 验证清单

- [ ] Gateway API 返回 200 状态
- [ ] `useLoadChains` 日志显示链数据加载成功
- [ ] 控制台显示：`🔧 useLoadChains: { dataLength: 1, isLoading: false }`
- [ ] 点击 "Connect wallet" 能够打开钱包选择界面

## 技术细节

### Gateway 服务状态

✅ **服务正常运行：** http://localhost:3001
✅ **返回正确数据：** Hetu 链配置（Chain ID: 560000）

```json
{
  "chainId": "560000",
  "chainName": "Hetu",
  "shortName": "hetu",
  "rpcUri": { "value": "http://161.97.161.133:18545" }
}
```

### API 代理流程

**当前（有问题）：**
```
浏览器 → /api/gateway/v1/chains → Next.js 代理 → ??? → Blockscout 404
```

**预期（正确）：**
```
浏览器 → /api/gateway/v1/chains → Next.js 代理 → http://localhost:3001/v1/chains → 链配置数据
```

**修复后（直连）：**
```
浏览器 → http://localhost:3001/v1/chains → Gateway 服务 → 链配置数据
```

## 后续优化建议

1. **调试 API 代理**
   - 检查代理配置是否正确
   - 确保路径映射正确

2. **添加错误处理**
   - 在 `useLoadChains` 中添加本地配置 fallback
   - 提供更友好的错误提示

3. **性能优化**
   - 考虑缓存链配置
   - 减少重复请求

## 修复文件清单

- ✅ `apps/web/.env` - Gateway URL 配置
- ✅ `apps/web/config/chains/hetu.json` - Hetu 链本地配置
- ✅ `apps/web/src/components/common/ConnectWallet/useConnectWallet.ts` - 钱包连接逻辑
- ✅ `apps/web/src/components/common/ConnectWallet/ConnectWalletButton.tsx` - 连接按钮组件
- ✅ `apps/web/src/components/welcome/WelcomeLogin/WalletLogin.tsx` - 登录页面

## 相关日志

**成功加载示例：**
```
🔧 useLoadChains: { dataLength: 1, isLoading: false }
🔧 useInitOnboard: Chain configs loaded: 1 chains
🔧 useInitOnboard: Current chain: 560000 Hetu
🔧 initOnboard: Starting initialization...
```

**失败加载示例：**
```
🔧 useLoadChains: { dataLength: 0, isLoading: false, error: "..." }
🔧 useConnectWallet: Cannot connect - missing requirements
```

## 联系信息

**修复日期：** 2025-10-16
**问题类型：** Gateway API 配置问题
**优先级：** 高（阻塞核心功能）

---

**注意：** 修改 `.env` 文件后必须重启开发服务器才能生效！
