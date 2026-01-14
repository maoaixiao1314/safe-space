# Safe Wallet 部署流程总结

## 🎯 关键发现

你说得**完全正确**！之前我理解错了部署流程。

### ❌ 错误理解
之前认为：
1. 部署合约
2. 手动注册 SafeL2 到数据库  ← **错误！**
3. 更新 Safe Web SDK

### ✅ 正确流程
实际应该是：
1. **部署合约** (`deploy-production.sh`)
2. **启动后端服务** (`start-safe-services.sh`)
3. **添加链配置** (`add-hetu-chain.sh`)
4. **更新合约地址** (`update-contract-addresses.sh`) ← **这一步包含 SafeL2 注册！**
5. 更新 Safe Web SDK
6. 创建 Safe 并测试

---

## 📋 完整部署流程

### 方式 1: 手动逐步执行（推荐学习）

```bash
# ============================================
# 步骤 1: 部署 Safe 合约
# ============================================
cd safe-deployment
./deploy-production.sh

# 交互式选择：
# - 选择目标网络（Hetu/Goerli/Mumbai/Mainnet 等）
# - 确认是否为 L2 链（选择 y）
# - 确认部署

# 输出示例：
# SafeL2: 0xA9a2Fd746af6Db05B659Df146235D2E60413D166
# SafeProxyFactory: 0x0db4Db2f66Be999DB9756589A54c4625fF6E7128
# ... 其他合约地址

# ⚠️ 重要：记录所有合约地址！


# ============================================
# 步骤 2: 启动后端服务
# ============================================
cd ../safe-deploy-guide/scripts
./start-safe-services.sh

# 等待服务启动（约30秒）
sleep 30

# 验证服务
curl http://localhost:8000/api/v1/about/  # Transaction Service
curl http://localhost:8001/api/            # Config Service
curl http://localhost:3001/api             # Client Gateway


# ============================================
# 步骤 3: 添加链配置
# ============================================
./add-hetu-chain.sh

# 这一步会在 Config Service 数据库中添加 Hetu 链信息
# 包括：Chain ID, RPC URL, 原生货币等

# 验证
curl http://localhost:8001/api/v1/chains/560000/


# ============================================
# 步骤 4: 更新合约地址（关键！）
# ============================================

# 4.1 编辑脚本，替换为步骤1部署的地址
vim update-contract-addresses.sh

# 修改以下变量：
# SAFE_SINGLETON="F5628304..."  ← 替换为步骤1的 Safe 地址
# SAFE_L2="A9a2Fd746a..."       ← 替换为步骤1的 SafeL2 地址
# SAFE_PROXY_FACTORY="0db4Db..." ← 替换为步骤1的 ProxyFactory 地址
# ... 其他合约地址

# 4.2 运行更新脚本
./update-contract-addresses.sh

# 这个脚本会自动执行：
# ✅ 更新 chains_chain 表中的合约地址
# ✅ 注册 SafeL2 到 history_safemastercopy 表（l2=true）
# ✅ 验证配置


# ============================================
# 步骤 5: 验证 SafeL2 注册
# ============================================
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
SELECT 
  encode(address, 'hex') as address, 
  l2,
  initial_block_number,
  tx_block_number
FROM history_safemastercopy;
"

# 期望输出：
#         address          | l2 | initial_block_number | tx_block_number
# -------------------------+----+----------------------+-----------------
#  a9a2fd746af6db05b659... | t  |                    0 |               0


# ============================================
# 步骤 6: 更新 Safe Web SDK 配置
# ============================================
cd ../../safe-wallet-web/apps/web/src/hooks/coreSDK
vim safeCoreSDK.ts

# 更新 contractNetworks：
if (chainId === '560000') {
  const contractNetworks = {
    '560000': {
      safeSingletonAddress: '0xA9a2Fd746af6Db05B659Df146235D2E60413D166',
      safeProxyFactoryAddress: '0x0db4Db2f66Be999DB9756589A54c4625fF6E7128',
      multiSendAddress: '0x...',
      multiSendCallOnlyAddress: '0x...',
      fallbackHandlerAddress: '0x...',
      signMessageLibAddress: '0x...',
      createCallAddress: '0x...',
    }
  };
  // ...
}


# ============================================
# 步骤 7: 创建第一个 Safe
# ============================================
cd ../../../../../safe-deployment
npx hardhat run scripts/create-safe-proxy.js --network your_network

# 输出示例：
# Safe deployed to: 0xe4369A70ac0e5d1d95CD4d6738F6228F53D6231A
# Owners: [0x13d21d00Bb3b805B4e3e93bd2Bd56be0616C17Ce]
# Threshold: 1

# ⚠️ 记录 Safe 地址！


# ============================================
# 步骤 8: 在 Safe Web 中测试
# ============================================
# 1. 访问 http://localhost:3000
# 2. 添加步骤7创建的 Safe 地址
# 3. 创建测试交易（发送 1 HETU）
# 4. 执行交易
# 5. 验证 UI 显示 "Success" 而不是 "Indexing"


# ============================================
# 步骤 9: 验证 ethereum_tx_id
# ============================================
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c "
SELECT 
  encode(safe_tx_hash, 'hex') as safe_tx_hash,
  encode(ethereum_tx_id, 'hex') as ethereum_tx_id,
  nonce
FROM history_multisigtransaction
WHERE safe = '\xe4369A70ac0e5d1d95CD4d6738F6228F53D6231A'
ORDER BY nonce DESC
LIMIT 5;
"

# 期望输出：ethereum_tx_id 应该有值（不是 NULL）✅
```

---

### 方式 2: 一键部署（推荐生产）

```bash
cd safe-deployment
chmod +x deploy-full-stack.sh
./deploy-full-stack.sh
```

这个脚本会自动执行所有步骤，并在每个关键点暂停等待确认。

---

## 🔑 关键要点

### 1. 为什么顺序很重要？

```
部署合约
  ↓ (生成合约地址)
启动服务
  ↓ (数据库就绪)
添加链配置
  ↓ (chains_chain 表就绪)
更新合约地址 + 注册 SafeL2  ← 关键步骤！
  ↓ (SafeL2 注册完成)
创建 Safe
  ↓ (Safe 使用 SafeL2 singleton)
执行交易
  ↓ (SafeMultiSigTransaction 事件)
Transaction Service 索引
  ↓ (ethereum_tx_id 更新)
UI 显示 "Success" ✅
```

### 2. `update-contract-addresses.sh` 的作用

**之前**: 只更新 `chains_chain` 表
**现在**: 
1. 更新 `chains_chain` 表中的合约地址
2. **自动注册 SafeL2 到 `history_safemastercopy` 表**（l2=true）
3. 验证 SafeL2 注册状态
4. 验证配置

**关键代码**:
```bash
# 更新链配置
UPDATE chains_chain SET ... WHERE id = 560000;

# ⚠️ 新增：注册 SafeL2（关键！）
INSERT INTO history_safemastercopy (address, initial_block_number, tx_block_number, l2)
VALUES (decode('$SAFE_L2', 'hex'), 0, 0, true)
ON CONFLICT (address) DO UPDATE SET l2 = true;

# 验证注册
SELECT COUNT(*) FROM history_safemastercopy 
WHERE address = decode('$SAFE_L2', 'hex') AND l2 = true;
```

### 3. 为什么需要注册 SafeL2？

**Transaction Service 的事件处理逻辑**:

```python
# safe_events_indexer.py

def process_transaction_event(event):
    master_copy = get_master_copy(safe_address)
    
    if master_copy.l2 == True:
        # SafeL2: 处理 SafeMultiSigTransaction 事件 ✅
        process_l2_event(event)
    else:
        # Safe L1: 处理 ExecutionSuccess 事件
        # 但在 L2 模式下会被忽略 ❌
        if ETH_L2_NETWORK == True:
            return  # 忽略！
```

**如果不注册 SafeL2**:
- Safe 的 `master_copy.l2` = false
- Transaction Service 忽略 ExecutionSuccess 事件（L2 模式）
- `ethereum_tx_id` 保持 NULL
- UI 永远显示 "Indexing" ❌

**注册 SafeL2 后**:
- Safe 的 `master_copy.l2` = true
- Transaction Service 处理 SafeMultiSigTransaction 事件 ✅
- `ethereum_tx_id` 正确更新
- UI 显示 "Success" ✅

---

## 📊 流程对比

### ❌ 之前的理解（错误）

```
部署合约
  ↓
手动注册 SafeL2  ← 认为这是独立步骤
  ↓
启动服务
  ↓
添加链配置
  ↓
更新合约地址  ← 认为只更新地址
```

### ✅ 正确的流程

```
部署合约
  ↓
启动服务  ← 数据库必须先启动
  ↓
添加链配置  ← chains_chain 表必须先存在
  ↓
更新合约地址  ← 同时注册 SafeL2！
  ↓
创建 Safe
  ↓
测试交易
```

---

## 🛠️ 改进的文件

1. **`update-contract-addresses.sh`**
   - ✅ 新增：自动注册 SafeL2
   - ✅ 新增：验证 SafeL2 注册状态

2. **`deploy-production.sh`**
   - ✅ 更新：后续步骤说明
   - ✅ 移除：手动注册 SafeL2 的说明（已集成到步骤4）

3. **`PRODUCTION_DEPLOYMENT_GUIDE.md`**
   - ✅ 新增：完整部署流程章节
   - ✅ 新增：流程顺序重要性说明
   - ✅ 更新：SafeL2 注册说明

4. **`deploy-full-stack.sh`** (新文件)
   - ✅ 一键执行所有步骤
   - ✅ 自动验证每个步骤
   - ✅ 详细的进度提示

5. **`DEPLOYMENT_STATUS.md`**
   - ✅ 新增：完整部署流程章节
   - ✅ 更新：update-contract-addresses.sh 说明

---

## ✅ 验证清单

完成部署后，按以下清单验证：

- [ ] 所有合约成功部署
  ```bash
  node get-addresses.js
  ```

- [ ] 后端服务运行正常
  ```bash
  curl http://localhost:8000/api/v1/about/
  curl http://localhost:8001/api/v1/chains/560000/
  ```

- [ ] SafeL2 已注册（l2=true）
  ```bash
  docker exec safe-postgres psql -U postgres -d safe_transaction_db -c \
    "SELECT encode(address, 'hex'), l2 FROM history_safemastercopy;"
  ```

- [ ] 合约地址已更新
  ```bash
  curl http://localhost:8001/api/v1/chains/560000/ | jq '.contractAddresses'
  ```

- [ ] Safe 创建成功
  ```bash
  cast call $SAFE_ADDRESS "getOwners()(address[])" --rpc-url $NODE_URL
  ```

- [ ] 测试交易 ethereum_tx_id 有值
  ```bash
  # 执行一笔测试交易后查询
  docker exec safe-postgres psql -U postgres -d safe_transaction_db -c \
    "SELECT encode(ethereum_tx_id, 'hex') FROM history_multisigtransaction \
     WHERE safe = '\xYourSafeAddress' ORDER BY nonce DESC LIMIT 1;"
  ```

- [ ] UI 显示 "Success" 而不是 "Indexing"

---

## 🎯 总结

**你的理解是完全正确的！** 💯

正确的部署流程应该是：

1. **部署合约** - 生成合约地址
2. **启动服务** - 准备数据库
3. **添加链配置** - 创建链记录
4. **更新合约地址** - **同时注册 SafeL2**（关键！）
5. 创建 Safe 并测试

`update-contract-addresses.sh` 脚本现在会**自动注册 SafeL2**，不需要额外的手动步骤。

这样的流程更加：
- ✅ **自动化** - 减少手动操作
- ✅ **一致性** - 避免遗漏步骤
- ✅ **可维护** - 集中管理配置
- ✅ **可靠性** - 自动验证每个步骤

感谢你的纠正！🙏
