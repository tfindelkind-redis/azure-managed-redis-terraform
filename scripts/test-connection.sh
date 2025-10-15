#!/bin/bash

# Quick Redis Connection Test
# Simple script to test Redis connectivity and basic operations

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get connection details from Terraform outputs
TERRAFORM_DIR="${1:-$(pwd)}"
cd "$TERRAFORM_DIR"

log_info "Getting connection details from Terraform..."

HOSTNAME=$(terraform output -raw hostname 2>/dev/null || echo "")
PORT=$(terraform output -raw port 2>/dev/null || echo "10000")
PRIMARY_KEY=$(terraform output -raw primary_key 2>/dev/null || echo "")

if [[ -z "$HOSTNAME" || -z "$PRIMARY_KEY" ]]; then
    log_error "Could not retrieve connection details from Terraform outputs"
    log_info "Make sure you're in a directory with deployed Terraform configuration"
    exit 1
fi

log_info "Testing connection to $HOSTNAME:$PORT"

# Test basic connectivity
log_info "Testing Redis PING..."
if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning ping 2>/dev/null | grep -q "PONG"; then
    log_success "PING successful"
else
    log_error "PING failed"
    exit 1
fi

# Test basic operations
log_info "Testing SET/GET operations..."
TEST_KEY="test_$(date +%s)"
TEST_VALUE="Hello Redis!"

if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning set "$TEST_KEY" "$TEST_VALUE" 2>/dev/null | grep -q "OK"; then
    log_success "SET operation successful"
else
    log_error "SET operation failed"
    exit 1
fi

RETRIEVED_VALUE=$(redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning get "$TEST_KEY" 2>/dev/null || echo "")
if [[ "$RETRIEVED_VALUE" == "$TEST_VALUE" ]]; then
    log_success "GET operation successful"
else
    log_error "GET operation failed"
    exit 1
fi

# Clean up
redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning del "$TEST_KEY" &>/dev/null

# Test RedisJSON if available
log_info "Testing RedisJSON module..."
JSON_KEY="json_test_$(date +%s)"
if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning JSON.SET "$JSON_KEY" $ '{"message":"success"}' 2>/dev/null | grep -q "OK"; then
    log_success "RedisJSON working"
    redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning del "$JSON_KEY" &>/dev/null
else
    log_info "RedisJSON not available or not working"
fi

log_success "All tests passed! Redis is working correctly."
log_info "Connection string: rediss://:****@$HOSTNAME:$PORT"
