# 🚀 Safe Wallet 部署快速参考

## ⚡ 一键部署（推荐）

```bash
cd safe-deployment
chmod +x deploy-full-stack.sh
./deploy-full-stack.sh
```

按提示完成所有步骤 → 自动验证 → 完成！✅

---

## 📝 手动部署（逐步执行）

### 步骤 1: 部署合约
```bash
cd safe-deployment
./deploy-production.sh
```
选择网络 → 确认 L2 → 记录地址

### 步骤 2: 启动服务
```bash
cd ../safe-deploy-guide/scripts
./start-safe-services.sh
```
等待 30 秒 → 验证服务

### 步骤 3: 添加链配置
```bash
./add-hetu-chain.sh
```
添加 Hetu 链到数据库

### 步骤 4: 更新合约地址
```bash
vim update-contract-addresses.sh  # 替换地址
./update-contract-addresses.sh
```
✅ 自动注册 SafeL2
✅ 自动验证配置

### 步骤 5: 创建 Safe
```bash
cd ../../safe-deployment
npx hardhat run scripts/create-safe-proxy.js --network hetu
```
记录 Safe 地址

### 步骤 6: 测试
在 Safe Web 中:
1. 添加 Safe 地址
2. 执行测试交易
3. 验证显示 "Success" ✅

---

## 🔍 快速验证

### 验证服务
```bash
curl http://localhost:8000/api/v1/about/  # Transaction Service
curl http://localhost:8001/api/v1/chains/560000/  # Config Service
```

### 验证 SafeL2 注册
```bash
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c \
  "SELECT encode(address, 'hex'), l2 FROM history_safemastercopy;"
```
应该看到: `address | l2: true` ✅

### 验证交易索引
```bash
docker exec safe-postgres psql -U postgres -d safe_transaction_db -c \
  "SELECT encode(ethereum_tx_id, 'hex') FROM history_multisigtransaction \
   WHERE safe = '\xYourSafeAddress' ORDER BY nonce DESC LIMIT 1;"
```
应该有值（不是 NULL）✅

---

## ⚠️ 常见错误

### ❌ 交易显示 "Indexing"
**原因**: 使用了旧的 Safe L1 地址
**解决**: 使用新的 SafeL2 地址（查看 `USE_CORRECT_SAFE.md`）

### ❌ ethereum_tx_id 是 NULL
**原因**: SafeL2 未注册或 l2=false
**解决**: 运行 `./update-contract-addresses.sh`

### ❌ 服务无法启动
**原因**: 数据库端口冲突
**解决**: 检查端口 5433/5434 是否被占用

---

## 📚 详细文档

- **完整指南**: `PRODUCTION_DEPLOYMENT_GUIDE.md`
- **流程总结**: `DEPLOYMENT_FLOW_SUMMARY.md`
- **改进说明**: `IMPROVEMENTS_SUMMARY.md`
- **使用正确 Safe**: `USE_CORRECT_SAFE.md`
- **部署状态**: `../DEPLOYMENT_STATUS.md`

---

## 🎯 关键点

1. **顺序很重要**: 合约 → 服务 → 链配置 → 合约地址
2. **SafeL2 必须注册**: `update-contract-addresses.sh` 自动完成
3. **使用正确的 Safe**: 只用 SafeL2 创建的 Safe
4. **验证每一步**: 避免后续问题

---

**快速帮助**: 查看 `DEPLOYMENT_FLOW_SUMMARY.md` 了解详细流程
