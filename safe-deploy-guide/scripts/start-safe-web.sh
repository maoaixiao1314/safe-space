#!/bin/bash

# 启动 Safe Web 前端应用

echo "🚀 启动 Safe Web 前端..."
echo ""

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 检查 safe-wallet-web 目录
if [ ! -d "safe-wallet-web" ]; then
    echo "❌ 错误：找不到 safe-wallet-web 目录"
    echo "当前目录: $(pwd)"
    exit 1
fi

# 检查环境配置文件
if [ ! -f "safe-wallet-web/apps/web/.env" ]; then
    echo "❌ 错误：找不到 .env 配置文件"
    echo "请先创建 safe-wallet-web/apps/web/.env 文件"
    exit 1
fi

echo "✅ 环境检查通过"
echo "📁 项目目录: $PROJECT_ROOT"
echo "📁 前端目录: $PROJECT_ROOT/safe-wallet-web/apps/web"
echo ""

# 检查后端服务状态
echo "🔍 检查后端服务状态..."
if ! curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo "⚠️  警告：Client Gateway (localhost:3001) 似乎未运行"
    echo "   请先启动后端服务: cd safe-deploy-guide/scripts && ./start-safe-services.sh"
    echo ""
    read -p "是否继续启动前端？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Client Gateway 运行正常"
fi

echo ""
echo "启动开发服务器..."
echo "前端将运行在: http://localhost:3000"
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

# 切换到 apps/web 目录并启动
cd safe-wallet-web/apps/web && yarn dev
