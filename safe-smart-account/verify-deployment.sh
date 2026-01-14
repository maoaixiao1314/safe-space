#!/bin/bash

# Safe Wallet Deployment Verification Script
# Verifies all deployed contracts are working correctly

set -e

echo "=========================================="
echo "Safe Wallet Deployment Verification"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if addresses file exists
ADDRESSES_FILE="hetu-safe-addresses.json"
if [ ! -f "$ADDRESSES_FILE" ]; then
    print_error "Deployment addresses file not found: $ADDRESSES_FILE"
    echo "Please run deployment first."
    exit 1
fi

# Load environment
if [ ! -f .env ]; then
    print_error ".env file not found"
    exit 1
fi

source .env

echo "Using RPC: $NODE_URL"
echo ""

# Extract addresses
SAFE_ADDRESS=$(node -p "try { require('./$ADDRESSES_FILE').Safe } catch(e) { '' }")
SAFEL2_ADDRESS=$(node -p "try { require('./$ADDRESSES_FILE').SafeL2 } catch(e) { '' }")
PROXY_FACTORY=$(node -p "try { require('./$ADDRESSES_FILE').SafeProxyFactory } catch(e) { '' }")
FALLBACK_HANDLER=$(node -p "try { require('./$ADDRESSES_FILE').CompatibilityFallbackHandler } catch(e) { '' }")
MULTISEND=$(node -p "try { require('./$ADDRESSES_FILE').MultiSend } catch(e) { '' }")
MULTISEND_CALLONLY=$(node -p "try { require('./$ADDRESSES_FILE').MultiSendCallOnly } catch(e) { '' }")
SIGN_MESSAGE_LIB=$(node -p "try { require('./$ADDRESSES_FILE').SignMessageLib } catch(e) { '' }")
CREATE_CALL=$(node -p "try { require('./$ADDRESSES_FILE').CreateCall } catch(e) { '' }")
SIMULATE_TX=$(node -p "try { require('./$ADDRESSES_FILE').SimulateTxAccessor } catch(e) { '' }")

# Verification counter
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to verify contract
verify_contract() {
    local name=$1
    local address=$2
    local function_sig=$3
    local expected_result=$4
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -z "$address" ] || [ "$address" = "undefined" ]; then
        print_warning "$name: Not deployed (skipping)"
        return
    fi
    
    echo "Verifying $name ($address)..."
    
    # Check if contract exists (has code)
    local code=$(cast code $address --rpc-url $NODE_URL 2>&1)
    if [ -z "$code" ] || [ "$code" = "0x" ]; then
        print_error "$name: No code at address (not deployed)"
        return
    fi
    
    # If function signature provided, test it
    if [ -n "$function_sig" ]; then
        local result=$(cast call $address "$function_sig" --rpc-url $NODE_URL 2>&1)
        if [ $? -eq 0 ]; then
            if [ -n "$expected_result" ]; then
                if [[ "$result" == *"$expected_result"* ]]; then
                    print_success "$name: Verified (version/function check passed)"
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                else
                    print_warning "$name: Deployed but unexpected result"
                    echo "  Expected: $expected_result"
                    echo "  Got: $result"
                fi
            else
                print_success "$name: Verified (function callable)"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            fi
        else
            print_error "$name: Function call failed"
            echo "  Error: $result"
        fi
    else
        print_success "$name: Verified (contract deployed)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
}

echo "=========================================="
echo "1. Core Singleton Contracts"
echo "=========================================="
echo ""

verify_contract "Safe (L1)" "$SAFE_ADDRESS" "VERSION()(string)" "1.4.1"
verify_contract "SafeL2" "$SAFEL2_ADDRESS" "VERSION()(string)" "1.4.1"

echo ""
echo "=========================================="
echo "2. Proxy Factory"
echo "=========================================="
echo ""

verify_contract "SafeProxyFactory" "$PROXY_FACTORY" "proxyCreationCode()(bytes)"

echo ""
echo "=========================================="
echo "3. Handler & Libraries"
echo "=========================================="
echo ""

verify_contract "CompatibilityFallbackHandler" "$FALLBACK_HANDLER"
verify_contract "MultiSend" "$MULTISEND"
verify_contract "MultiSendCallOnly" "$MULTISEND_CALLONLY"
verify_contract "SignMessageLib" "$SIGN_MESSAGE_LIB"
verify_contract "CreateCall" "$CREATE_CALL"
verify_contract "SimulateTxAccessor" "$SIMULATE_TX"

echo ""
echo "=========================================="
echo "4. Additional Checks"
echo "=========================================="
echo ""

# Check if SafeProxyFactory can create proxies
if [ -n "$PROXY_FACTORY" ] && [ "$PROXY_FACTORY" != "undefined" ]; then
    echo "Testing SafeProxyFactory.proxyRuntimeCode()..."
    RUNTIME_CODE=$(cast call $PROXY_FACTORY "proxyRuntimeCode()(bytes)" --rpc-url $NODE_URL 2>&1)
    if [ $? -eq 0 ] && [ -n "$RUNTIME_CODE" ] && [ "$RUNTIME_CODE" != "0x" ]; then
        print_success "SafeProxyFactory: Runtime code verified"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_error "SafeProxyFactory: Could not get runtime code"
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
fi

echo ""
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo ""
echo "Total checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))"
echo ""

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    print_success "All verifications passed! 🎉"
    echo ""
    echo "Your Safe deployment is ready to use."
    echo ""
    echo "Next steps:"
    echo "1. Create a Safe using create-safe-proxy.js"
    echo "2. Update Safe Web SDK configuration"
    echo "3. Register SafeL2 in Transaction Service (if using L2)"
    exit 0
else
    print_warning "Some verifications failed or were skipped."
    echo ""
    echo "Please review the errors above and redeploy if necessary."
    exit 1
fi
