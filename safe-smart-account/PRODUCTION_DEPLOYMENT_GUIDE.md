# Safe Wallet 生产环境部署指南

本指南适用于在测试网和主网上部署 Safe Wallet 智能合约。

## 📋 目录

1. [准备工作](#准备工作)
2. [部署流程](#部署流程)
3. [验证部署](#验证部署)
4. [后续配置](#后续配置)
5. [常见问题](#常见问题)

---

## 🛠️ 准备工作

### 1. 环境要求

- Node.js >= 16.x
- npm >= 8.x
- 足够的 gas 费用（主网部署）

### 2. 配置环境变量

```bash
# 复制模板文件
cp .env.example .env

# 编辑 .env 文件
vim .env
```

**必填配置**:
```env
# RPC 节点 URL
NODE_URL=http://your-rpc-url

# 部署者私钥（不要包含 0x 前缀）
PK=your_private_key_without_0x

# 部署者地址（用于余额检查）
DEPLOYER_ADDRESS=0xYourAddress
```

**可选配置**:
```env
# Chain ID（可自动检测）
CHAIN_ID=560000

# Infura Key（主网/测试网需要）
INFURA_KEY=your_infura_key

# Etherscan API Key（合约验证需要）
ETHERSCAN_API_KEY=your_etherscan_key
```

### 3. 检查部署者余额

确保部署者账户有足够的 gas 费用：

**测试网估算**:
- ~0.1-0.5 ETH (Goerli)
- ~1-5 MATIC (Mumbai)
- ~100-500 HETU (Hetu Testnet)

**主网估算**:
- ~1-2 ETH (Ethereum)
- ~10-50 MATIC (Polygon)

检查余额：
```bash
cast balance $DEPLOYER_ADDRESS --rpc-url $NODE_URL
```

---

## 🚀 部署流程

### 方式 1: 使用生产部署脚本（推荐）

```bash
# 给脚本添加执行权限
chmod +x deploy-production.sh

# 运行部署
./deploy-production.sh
```

**交互式选项**:
1. 选择目标网络（Hetu/Goerli/Mumbai/Mainnet 等）
2. 确认是否为 L2 链
3. 确认部署（主网需要输入 YES）

**优点**:
- ✅ 交互式网络选择
- ✅ 自动余额检查
- ✅ 主网部署二次确认
- ✅ 详细的部署日志
- ✅ 自动生成后续步骤说明

### 方式 2: 使用基础脚本

```bash
# 给脚本添加执行权限
chmod +x deploy-direct.sh

# 运行部署
./deploy-direct.sh
```

**适用场景**:
- 快速部署到自定义网络
- 已经熟悉部署流程
- 自动化脚本集成

---

## ✅ 验证部署

### 1. 自动验证

```bash
# 给验证脚本添加执行权限
chmod +x verify-deployment.sh

# 运行验证
./verify-deployment.sh
```

**验证内容**:
- ✅ 合约是否成功部署（code 存在）
- ✅ Safe/SafeL2 版本号检查
- ✅ SafeProxyFactory 功能检查
- ✅ 辅助合约可调用性检查

### 2. 手动验证

查看部署地址：
```bash
node get-addresses.js
```

验证 SafeL2 版本：
```bash
cast call $SAFEL2_ADDRESS "VERSION()(string)" --rpc-url $NODE_URL
# 应该返回: 1.4.1
```

验证 SafeProxyFactory：
```bash
cast call $PROXY_FACTORY "proxyCreationCode()(bytes)" --rpc-url $NODE_URL
# 应该返回: 0x608060...（一段 bytecode）
```

### 3. 查看部署记录

部署完成后会生成：
- `hetu-safe-addresses.json` - 合约地址
- `deployment-info-{network}-{timestamp}.txt` - 部署详细信息

---

## ⚙️ 后续配置

### ⚠️ 重要：完整部署流程（包含 Transaction Service）

如果你要部署完整的 Safe 生态（包括 Transaction Service 和 Safe Web），请按以下**严格顺序**执行：

```bash
# 步骤 1: 部署合约
./deploy-production.sh
# 选择网络，确认 L2，完成部署
# 记录所有合约地址

# 步骤 2: 启动后端服务
cd ../safe-deploy-guide/scripts
./start-safe-services.sh
# 等待所有服务启动完成

# 步骤 3: 添加链配置
./add-hetu-chain.sh
# 在 Config Service 数据库中添加链信息

# 步骤 4: 更新合约地址（自动注册 SafeL2）
# ⚠️ 重要：先编辑脚本，替换为步骤1部署的合约地址
vim update-contract-addresses.sh
# 修改 SAFE_L2、SAFE_PROXY_FACTORY 等地址

./update-contract-addresses.sh
# 这一步会：
# 1. 更新 chains_chain 表中的合约地址
# 2. 自动注册 SafeL2 到 history_safemastercopy 表（l2=true）
# 3. 验证配置

# 步骤 5: 验证 SafeL2 注册
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
SELECT encode(address, 'hex') as address, l2, initial_block_number 
FROM history_safemastercopy;
"
# 应该看到你的 SafeL2 地址，l2=true

# 步骤 6: 更新 Safe Web SDK 配置
cd ../../safe-wallet-web/apps/web/src/hooks/coreSDK
vim safeCoreSDK.ts
# 更新 contractNetworks 为步骤1部署的地址

# 步骤 7: 创建第一个 Safe
cd ../../../../../safe-deployment
npx hardhat run scripts/create-safe-proxy.js --network your_network

# 步骤 8: 测试交易
# 在 Safe Web 中执行一笔测试交易
# 验证 ethereum_tx_id 正确更新
```

### 为什么顺序很重要？

1. **合约必须先部署** → 才有地址可以配置
2. **服务必须先启动** → 才能添加链配置
3. **链配置必须先添加** → 才能更新合约地址
4. **SafeL2 必须先注册** → Transaction Service 才能正确索引事件
5. **SDK 必须先配置** → Safe Web 才能初始化

### 1. 注册 SafeL2 到 Transaction Service（自动完成）

**注意**：从现在开始，`update-contract-addresses.sh` 脚本会**自动注册 SafeL2**！

你只需要：
1. 编辑 `update-contract-addresses.sh`，替换合约地址
2. 运行脚本：`./update-contract-addresses.sh`

脚本会自动执行：
```sql
-- 1. 更新链配置中的合约地址
UPDATE chains_chain SET ...

-- 2. 注册 SafeL2（自动）
INSERT INTO history_safemastercopy (address, initial_block_number, tx_block_number, l2)
VALUES (decode('YOUR_SAFEL2_ADDRESS', 'hex'), 0, 0, true)
ON CONFLICT (address) DO UPDATE SET l2 = true;
```

### 2. 更新 Safe Web SDK 配置

编辑文件: `safe-wallet-web/apps/web/src/hooks/coreSDK/safeCoreSDK.ts`

```typescript
// 添加你的网络配置
if (chainId === 'YOUR_CHAIN_ID') {
  const contractNetworks = {
    [chainId]: {
      safeSingletonAddress: 'YOUR_SAFEL2_ADDRESS',
      safeProxyFactoryAddress: 'YOUR_PROXY_FACTORY_ADDRESS',
      multiSendAddress: 'YOUR_MULTISEND_ADDRESS',
      multiSendCallOnlyAddress: 'YOUR_MULTISEND_CALLONLY_ADDRESS',
      fallbackHandlerAddress: 'YOUR_FALLBACK_HANDLER_ADDRESS',
      signMessageLibAddress: 'YOUR_SIGN_MESSAGE_LIB_ADDRESS',
      createCallAddress: 'YOUR_CREATE_CALL_ADDRESS',
    }
  };
  
  // ... SDK 初始化
}
```

### 3. 创建第一个 Safe

```bash
# 使用 SafeL2（L2 链）
npx hardhat run scripts/create-safe-proxy.js --network your_network
```

验证 Safe 创建：
```bash
# Safe 地址会在创建脚本输出中显示
SAFE_ADDRESS=0xYourNewSafeAddress

# 检查 owner
cast call $SAFE_ADDRESS "getOwners()(address[])" --rpc-url $NODE_URL

# 检查 threshold
cast call $SAFE_ADDRESS "getThreshold()(uint256)" --rpc-url $NODE_URL
```

---

## 🔧 常见问题

### Q1: 部署失败，提示 "insufficient funds"

**原因**: 部署者账户余额不足

**解决**:
```bash
# 查看当前余额
cast balance $DEPLOYER_ADDRESS --rpc-url $NODE_URL

# 向部署者地址转账足够的 gas 费
```

### Q2: 合约部署成功但验证失败

**原因**: RPC 节点可能还没有索引最新区块

**解决**:
```bash
# 等待几个区块后重新验证
sleep 30
./verify-deployment.sh
```

### Q3: 应该部署 Safe 还是 SafeL2？

**规则**:
- **L1 链** (Ethereum Mainnet/Goerli): 使用 **Safe**
- **L2 链** (Polygon, Arbitrum, Optimism, Hetu): 使用 **SafeL2**

**判断方法**:
- Transaction Service 启用 `ETH_L2_NETWORK=True` → 必须用 SafeL2
- 链支持 trace_block → 可以用 Safe
- 链不支持 trace_block → 必须用 SafeL2

### Q4: 部署到主网前需要注意什么？

**检查清单**:
- ✅ 在测试网上完整测试过
- ✅ 验证所有合约功能正常
- ✅ 确认部署者私钥安全存储
- ✅ 准备足够的 gas 费用（1.5-2 倍估算值）
- ✅ 备份 .env 文件（不要提交到 git）
- ✅ 记录所有部署地址
- ✅ 进行合约审计（生产环境强烈推荐）

### Q5: 如何在 Etherscan 上验证合约？

```bash
# 设置 Etherscan API Key
export ETHERSCAN_API_KEY=your_api_key

# 验证 SafeL2
npx hardhat verify --network your_network $SAFEL2_ADDRESS

# 验证 SafeProxyFactory
npx hardhat verify --network your_network $PROXY_FACTORY
```

### Q6: 部署后如何更新合约地址？

**不建议更新已部署的合约**。Safe 合约是不可升级的。

如果需要更新：
1. 部署新的合约版本
2. 更新所有配置文件中的地址
3. 迁移现有 Safe 到新合约（需要用户操作）

---

## 📊 网络配置参考

### Hetu Testnet
```env
NODE_URL=http://161.97.161.133:18545
CHAIN_ID=560000
```

### Ethereum Goerli
```env
NODE_URL=https://goerli.infura.io/v3/YOUR_INFURA_KEY
CHAIN_ID=5
INFURA_KEY=your_infura_key
```

### Polygon Mumbai
```env
NODE_URL=https://polygon-mumbai.infura.io/v3/YOUR_INFURA_KEY
CHAIN_ID=80001
INFURA_KEY=your_infura_key
```

### Ethereum Mainnet
```env
NODE_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
CHAIN_ID=1
INFURA_KEY=your_infura_key
```

### Polygon Mainnet
```env
NODE_URL=https://polygon-mainnet.infura.io/v3/YOUR_INFURA_KEY
CHAIN_ID=137
INFURA_KEY=your_infura_key
```

---

## 🎯 最佳实践

### 1. 测试网先行
- ✅ 先在测试网部署和测试
- ✅ 验证所有功能正常
- ✅ 创建测试 Safe 并执行交易
- ✅ 确认 Transaction Service 正常索引

### 2. 安全性
- ✅ 永远不要提交 .env 到 git
- ✅ 使用硬件钱包部署主网合约
- ✅ 多重签名控制部署者账户
- ✅ 定期审计智能合约代码

### 3. 文档记录
- ✅ 保存所有部署地址
- ✅ 记录部署时间和区块号
- ✅ 保存部署配置快照
- ✅ 文档化所有后续配置步骤

### 4. 监控
- ✅ 监控合约调用频率
- ✅ 设置 gas 价格告警
- ✅ 跟踪 Safe 创建数量
- ✅ 监控 Transaction Service 索引状态

---

## 📞 支持

遇到问题？

1. 查看 `DEPLOYMENT_STATUS.md` 和 `USE_CORRECT_SAFE.md`
2. 运行 `verify-deployment.sh` 检查部署状态
3. 检查 Transaction Service 日志
4. 参考 Safe 官方文档: https://docs.safe.global/

---

## ✅ 部署检查清单

**部署前**:
- [ ] .env 文件配置正确
- [ ] 部署者账户有足够余额
- [ ] 确认目标网络和 Chain ID
- [ ] 确认是 L1 还是 L2 链

**部署中**:
- [ ] 所有合约成功部署
- [ ] 保存部署地址到 JSON
- [ ] 记录部署交易哈希

**部署后**:
- [ ] 运行 verify-deployment.sh
- [ ] 注册 SafeL2（如果是 L2）
- [ ] 更新 Safe Web SDK 配置
- [ ] 创建测试 Safe
- [ ] 执行测试交易
- [ ] 验证 ethereum_tx_id 更新

---

**祝部署顺利！** 🚀
