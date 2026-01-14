#!/bin/bash

# 完全重启 Safe Web 并清除缓存的脚本

set -e

echo "=========================================="
echo "  重启 Safe Web（清除缓存）"
echo "=========================================="
echo ""

cd /Users/zhouxin/Workspace/safe-space/safe-wallet-web

# 1. 停止所有 yarn 进程
echo "1. 停止现有的 Safe Web 进程..."
pkill -f "yarn dev" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

# 2. 清除 Next.js 缓存
echo "2. 清除 Next.js 构建缓存..."
rm -rf apps/web/.next
rm -rf apps/web/node_modules/.cache

# 3. 验证配置更新
echo ""
echo "3. 验证配置..."
echo "   检查 safeCoreSDK.ts 中的 SafeL2 地址..."
SAFEL2_IN_SDK=$(grep -A1 "chainId === '560000'" apps/web/src/hooks/coreSDK/safeCoreSDK.ts -A15 | grep "safeSingletonAddress" | grep -o "0x[a-fA-F0-9]*")
echo "   SDK 中的 SafeL2 地址: $SAFEL2_IN_SDK"

if [ "$SAFEL2_IN_SDK" = "0x7d99a4206FbC06d58777B5882bdD653C2eFAa3ef" ]; then
    echo "   ✅ SDK 配置正确"
else
    echo "   ❌ SDK 配置错误！应该是 0x7d99a4206FbC06d58777B5882bdD653C2eFAa3ef"
    exit 1
fi

# 4. 验证数据库 l2 字段
echo ""
echo "4. 验证数据库 l2 字段..."
L2_IN_DB=$(docker exec safe-postgres psql -U postgres -d safe_transaction_db -t -c "SELECT l2 FROM chains_chain WHERE id = 560000" | xargs)
echo "   数据库 l2 字段: $L2_IN_DB"

if [ "$L2_IN_DB" = "t" ]; then
    echo "   ✅ 数据库配置正确"
else
    echo "   ❌ 数据库配置错误！需要设置 l2 = true"
    exit 1
fi

# 5. 验证 Config Service
echo ""
echo "5. 验证 Config Service..."
CONFIG_L2=$(curl -s http://localhost:8001/api/v1/chains/560000/ | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('l2', 'NOT_FOUND'))" 2>/dev/null)
echo "   Config Service l2 字段: $CONFIG_L2"

if [ "$CONFIG_L2" = "True" ]; then
    echo "   ✅ Config Service 配置正确"
else
    echo "   ❌ Config Service 配置错误！"
    exit 1
fi

# 6. 启动 Safe Web
echo ""
echo "6. 启动 Safe Web..."
echo "   运行命令: cd apps/web && yarn dev"
echo ""
echo "=========================================="
echo "  启动中..."
echo "=========================================="
echo ""
echo "⚠️  重要提示："
echo ""
echo "1. 等待 Safe Web 启动完成（看到 'Ready' 或能访问 http://localhost:3000）"
echo ""
echo "2. 在浏览器中执行以下操作："
echo "   - macOS: 按 Cmd + Shift + R（硬刷新）"
echo "   - Windows/Linux: 按 Ctrl + Shift + F5"
echo "   - 或者打开开发者工具，右键刷新按钮，选择 '清空缓存并硬性重新加载'"
echo ""
echo "3. 创建新的 Safe（旧 Safe 无法修复）"
echo ""
echo "4. 验证新 Safe 使用 SafeL2："
echo "   运行: ./verify-new-safe.sh <新Safe地址>"
echo ""
echo "=========================================="
echo ""

cd apps/web
exec yarn dev
