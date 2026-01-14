#!/bin/bash

# Safe Wallet Production Deployment Script
# Supports testnet and mainnet deployments with proper validation

set -e

echo "=========================================="
echo "Safe Wallet Production Deployment"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo "ℹ️  $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please create a .env file with your configuration."
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$PK" ] && [ -z "$MNEMONIC" ]; then
    print_error "Either PK or MNEMONIC must be set in .env file"
    exit 1
fi

# Network selection
echo "Select deployment network:"
echo "  1) Hetu Mainnet (Chain ID: 560000)"
echo "  2) Hetu Testnet (Chain ID: 565000)"
echo "  3) Custom (using NODE_URL from .env)"
echo "  4) Ethereum Goerli Testnet"
echo "  5) Polygon Mumbai Testnet"
echo "  6) Ethereum Mainnet (⚠️  Production)"
echo "  7) Polygon Mainnet (⚠️  Production)"
echo ""
read -p "Enter your choice (1-7): " network_choice

case $network_choice in
    1)
        NETWORK="hetu-mainnet"
        CHAIN_ID=560000
        IS_MAINNET=true
        NODE_URL="$MAINNET_NODE_URL"
        if [ -z "$NODE_URL" ]; then
            print_error "MAINNET_NODE_URL is not set in .env file"
            exit 1
        fi
        ;;
    2)
        NETWORK="hetu-testnet"
        CHAIN_ID=565000
        IS_MAINNET=false
        NODE_URL="$TESTNET_NODE_URL"
        if [ -z "$NODE_URL" ]; then
            print_error "TESTNET_NODE_URL is not set in .env file"
            exit 1
        fi
        ;;
    3)
        NETWORK="custom"
        CHAIN_ID=${CHAIN_ID:-auto-detect}
        IS_MAINNET=false
        if [ -z "$NODE_URL" ]; then
            print_error "NODE_URL is not set in .env file for custom network"
            exit 1
        fi
        ;;
    4)
        NETWORK="goerli"
        CHAIN_ID=5
        IS_MAINNET=false
        if [ -z "$INFURA_KEY" ]; then
            print_error "INFURA_KEY is required for Goerli deployment"
            exit 1
        fi
        NODE_URL="https://goerli.infura.io/v3/$INFURA_KEY"
        ;;
    5)
        NETWORK="mumbai"
        CHAIN_ID=80001
        IS_MAINNET=false
        if [ -z "$INFURA_KEY" ]; then
            print_error "INFURA_KEY is required for Mumbai deployment"
            exit 1
        fi
        NODE_URL="https://polygon-mumbai.infura.io/v3/$INFURA_KEY"
        ;;
    6)
        NETWORK="mainnet"
        CHAIN_ID=1
        IS_MAINNET=true
        if [ -z "$INFURA_KEY" ]; then
            print_error "INFURA_KEY is required for Mainnet deployment"
            exit 1
        fi
        NODE_URL="https://mainnet.infura.io/v3/$INFURA_KEY"
        print_warning "You are about to deploy to ETHEREUM MAINNET!"
        read -p "Are you ABSOLUTELY sure? (type 'YES' to confirm): " confirm
        if [ "$confirm" != "YES" ]; then
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    7)
        NETWORK="polygon"
        CHAIN_ID=137
        IS_MAINNET=true
        if [ -z "$INFURA_KEY" ]; then
            print_error "INFURA_KEY is required for Polygon deployment"
            exit 1
        fi
        NODE_URL="https://polygon-mainnet.infura.io/v3/$INFURA_KEY"
        print_warning "You are about to deploy to POLYGON MAINNET!"
        read -p "Are you ABSOLUTELY sure? (type 'YES' to confirm): " confirm
        if [ "$confirm" != "YES" ]; then
            echo "Deployment cancelled."
            exit 0
        fi
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_info "Deployment Configuration:"
echo "  Network: $NETWORK"
echo "  Chain ID: $CHAIN_ID"
echo "  RPC URL: $NODE_URL"
echo "  Is Mainnet: $IS_MAINNET"
echo ""

# Check if this is L2 deployment
read -p "Is this an L2 chain (Polygon, Arbitrum, Optimism, etc.)? (y/n): " is_l2
if [ "$is_l2" = "y" ] || [ "$is_l2" = "Y" ]; then
    IS_L2=true
    print_info "Will deploy SafeL2 as primary singleton"
else
    IS_L2=false
    print_info "Will deploy Safe (L1) as primary singleton"
fi

echo ""

# Estimate gas costs (if on mainnet)
if [ "$IS_MAINNET" = true ]; then
    print_warning "Mainnet deployment will incur real gas costs!"
    echo "Estimated gas needed: ~10,000,000 gas"
    echo ""
    read -p "Do you want to continue? (y/n): " continue_deploy
    if [ "$continue_deploy" != "y" ] && [ "$continue_deploy" != "Y" ]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Pre-deployment checks
echo ""
print_info "Running pre-deployment checks..."

# Check if deployer has sufficient balance
DEPLOYER_BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $NODE_URL 2>/dev/null || echo "0")
if [ "$DEPLOYER_BALANCE" = "0" ] || [ -z "$DEPLOYER_ADDRESS" ]; then
    print_warning "Could not check deployer balance. Make sure you have sufficient funds."
else
    print_success "Deployer balance checked"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    print_info "Installing dependencies..."
    npm install
fi

# Compile contracts
print_info "Compiling contracts..."
npx hardhat compile --network $NETWORK
print_success "Contracts compiled"

echo ""
echo "=========================================="
print_info "Starting deployment..."
echo "=========================================="
echo ""

# Run the deployment script
npx hardhat run scripts/deploy-safe.js --network $NETWORK

DEPLOY_EXIT_CODE=$?

if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    echo ""
    print_error "Deployment failed!"
    exit 1
fi

echo ""
echo "=========================================="
print_success "Deployment completed successfully!"
echo "=========================================="
echo ""

# Post-deployment actions
ADDRESSES_FILE="hetu-safe-addresses.json"
if [ -f "$ADDRESSES_FILE" ]; then
    print_success "Deployment addresses saved to: $ADDRESSES_FILE"
    echo ""
    print_info "Deployed contracts:"
    node get-addresses.js
    echo ""
    
    # Extract SafeL2 address if L2 deployment
    if [ "$IS_L2" = true ]; then
        SAFEL2_ADDRESS=$(node -p "require('./hetu-safe-addresses.json').SafeL2")
        print_info "SafeL2 Singleton: $SAFEL2_ADDRESS"
    else
        SAFE_ADDRESS=$(node -p "require('./hetu-safe-addresses.json').Safe")
        print_info "Safe Singleton: $SAFE_ADDRESS"
    fi
    
    PROXY_FACTORY=$(node -p "require('./hetu-safe-addresses.json').SafeProxyFactory")
    print_info "SafeProxyFactory: $PROXY_FACTORY"
fi

echo ""
echo "=========================================="
print_info "Next Steps:"
echo "=========================================="
echo ""

echo "⚠️  重要：如果使用 Safe Transaction Service，请按以下顺序操作："
echo ""
echo "1. 启动后端服务："
echo "   cd safe-deploy-guide/scripts"
echo "   ./start-safe-services.sh"
echo ""

echo "2. 添加链配置："
echo "   ./add-hetu-chain.sh"
echo ""

echo "3. 更新合约地址（会自动注册 SafeL2）："
echo "   ./update-contract-addresses.sh"
echo "   注意：请先修改脚本中的合约地址为本次部署的地址"
echo ""

echo "4. 更新 Safe Web SDK 配置："
echo "   编辑: safe-wallet-web/apps/web/src/hooks/coreSDK/safeCoreSDK.ts"
echo "   更新 contractNetworks 为本次部署的地址"
echo ""

echo "5. 创建测试 Safe："
echo "   npx hardhat run scripts/create-safe-proxy.js --network $NETWORK"
echo ""

echo "6. 验证部署："
if [ "$IS_L2" = true ]; then
    echo "   cast call $SAFEL2_ADDRESS \"VERSION()(string)\" --rpc-url $NODE_URL"
else
    echo "   cast call $SAFE_ADDRESS \"VERSION()(string)\" --rpc-url $NODE_URL"
fi
echo ""

# Save deployment info
DEPLOYMENT_INFO="deployment-info-${NETWORK}-$(date +%Y%m%d-%H%M%S).txt"
cat > "$DEPLOYMENT_INFO" <<EOF
Safe Wallet Deployment Information
===================================

Deployment Date: $(date)
Network: $NETWORK
Chain ID: $CHAIN_ID
Is L2: $IS_L2
Is Mainnet: $IS_MAINNET

Deployed Contracts:
$(cat $ADDRESSES_FILE)

RPC URL: $NODE_URL

Next Steps:
$(if [ "$IS_L2" = true ]; then echo "- Register SafeL2 in Transaction Service"; fi)
- Update Safe Web SDK configuration
- Create a new Safe using SafeProxyFactory
- Test Safe creation and transaction execution

Notes:
- Keep this file for your records
- Do not share private keys or mnemonics
- Verify all contract addresses before using in production
EOF

print_success "Deployment info saved to: $DEPLOYMENT_INFO"

echo ""
print_success "Deployment process completed! 🎉"
echo ""
