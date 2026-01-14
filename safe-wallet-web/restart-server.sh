#!/bin/bash

echo "=========================================="
echo "🔄 重启 Next.js 服务器"
echo "=========================================="
echo ""

cd /home/ubuntu/safe-space/safe-wallet-web

echo "正在查找 Next.js 进程..."
PID=$(lsof -ti:3002)

if [ -n "$PID" ]; then
    echo "找到进程 PID: $PID"
    echo "正在停止服务器..."
    kill $PID
    sleep 2
    echo "✅ 服务器已停止"
else
    echo "⚠️  未找到运行在端口 3002 的进程"
fi

echo ""
echo "正在启动 Next.js 服务器..."
echo "运行命令: PORT=3002 yarn dev"
echo ""
echo "=========================================="
echo "⚠️  注意事项"
echo "=========================================="
echo ""
echo "1. 服务器将在前台运行"
echo "2. 按 Ctrl+C 可以停止服务器"
echo "3. 建议使用 screen 或 PM2 在后台运行"
echo ""
echo "使用 screen (推荐):"
echo "  screen -S safe-web"
echo "  cd /home/ubuntu/safe-space/safe-wallet-web"
echo "  PORT=3002 yarn dev"
echo "  # 按 Ctrl+A 然后 D 来分离会话"
echo ""
echo "使用 PM2 (生产环境):"
echo "  pm2 start \"yarn dev\" --name safe-web -- --port 3002"
echo ""
echo "=========================================="
