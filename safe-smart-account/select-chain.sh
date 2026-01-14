#!/bin/bash

# 链选择脚本
# 用于在部署前让用户选择部署到主网还是测试网

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  选择部署目标链"
echo "=========================================="
echo ""
echo -e "${BLUE}可用的链：${NC}"
echo ""
echo "  1) Hetu 主网 (Chain ID: 560000)"
echo "     RPC: https://rpc.v1.hetu.org"
echo "     浏览器: https://explorer.hetu.org"
echo ""
echo "  2) Hetu 测试网 (Chain ID: 565000)"
echo "     RPC: http://161.97.161.133:18545"
echo "     浏览器: http://161.97.161.133:18545"
echo ""
read -p "请选择 (1-2): " chain_choice

case $chain_choice in
    1)
        export DEPLOY_CHAIN_ID=560000
        export DEPLOY_CHAIN_NAME="hetu-mainnet"
        export DEPLOY_RPC_URL="https://rpc.v1.hetu.org"
        export IS_TESTNET=false
        echo ""
        echo -e "${YELLOW}⚠️  警告: 您将部署到 Hetu 主网！${NC}"
        read -p "确认继续? (y/n): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "部署已取消"
            exit 1
        fi
        ;;
    2)
        export DEPLOY_CHAIN_ID=565000
        export DEPLOY_CHAIN_NAME="hetu-testnet"
        export DEPLOY_RPC_URL="http://161.97.161.133:18545"
        export IS_TESTNET=true
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ 已选择: $DEPLOY_CHAIN_NAME (Chain ID: $DEPLOY_CHAIN_ID)${NC}"
echo ""

# 导出环境变量供其他脚本使用
export SELECTED_CHAIN_ID=$DEPLOY_CHAIN_ID
export SELECTED_CHAIN_NAME=$DEPLOY_CHAIN_NAME
export SELECTED_RPC_URL=$DEPLOY_RPC_URL
