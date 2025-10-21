#!/bin/bash

# Local test script for High-Availability Redis example
# This script mimics the GitHub Actions workflow for local debugging

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "High-Availability Redis Local Test Script"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check if redis-cli is installed
if ! command -v redis-cli &> /dev/null; then
    print_error "redis-cli is not installed"
    echo "Install with: brew install redis"
    exit 1
fi
print_success "redis-cli is installed"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "terraform is not installed"
    exit 1
fi
print_success "terraform is installed"

# Check if Azure CLI is logged in
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure CLI"
    echo "Please run: az login"
    exit 1
fi
print_success "Azure CLI is authenticated"

echo ""
echo "============================================"
echo "Step 1: Terraform Init"
echo "============================================"
terraform init

echo ""
echo "============================================"
echo "Step 2: Terraform Plan"
echo "============================================"
terraform plan -out=tfplan

echo ""
print_info "Review the plan above. Press Enter to continue with apply, or Ctrl+C to cancel..."
read

echo ""
echo "============================================"
echo "Step 3: Terraform Apply"
echo "============================================"
terraform apply tfplan

echo ""
echo "============================================"
echo "Step 4: Get Connection Details"
echo "============================================"
HOSTNAME=$(terraform output -raw hostname)
PRIMARY_KEY=$(terraform state show 'module.redis_enterprise.data.azapi_resource_action.database_keys[0]' | grep 'primaryKey' | sed -n 's/.*primaryKey[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p')
PORT=10000

if [ -z "$HOSTNAME" ] || [ -z "$PRIMARY_KEY" ]; then
    print_error "Failed to get connection details from Terraform"
    exit 1
fi

print_success "Connection details retrieved"
echo "Hostname: $HOSTNAME"
echo "Port: $PORT"
echo "Key length: ${#PRIMARY_KEY}"

echo ""
echo "============================================"
echo "Step 5: Test Basic Connectivity"
echo "============================================"

echo "Testing with PING command..."
if redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping; then
    print_success "PING test successful"
else
    EXIT_CODE=$?
    print_error "PING test failed with exit code: $EXIT_CODE"
    echo ""
    echo "--- Debugging Information ---"
    echo "Hostname: $HOSTNAME"
    echo "Port: $PORT"
    echo "Key length: ${#PRIMARY_KEY}"
    echo "redis-cli version: $(redis-cli --version)"
    echo ""
    echo "Raw error output:"
    redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping 2>&1 || true
    exit 1
fi

echo ""
echo "============================================"
echo "Step 6: Test High-Availability Features"
echo "============================================"

echo "Setting test data..."
if redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning SET ha_test_key "high-availability-test-$(date +%s)"; then
    print_success "SET command successful"
else
    print_error "SET command failed"
    exit 1
fi

echo ""
echo "Testing RedisJSON with complex data..."
if redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.SET ha:config $ '{
  "cluster": {
    "high_availability": true,
    "zones": ["1", "2", "3"],
    "minimum_tls_version": "1.2"
  },
  "test_timestamp": "'$(date -Iseconds)'"
}'; then
    print_success "JSON.SET command successful"
else
    print_error "JSON.SET command failed"
    exit 1
fi

echo ""
echo "Verifying data persistence..."
HA_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning GET ha_test_key)
JSON_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.GET ha:config $.cluster.high_availability)

echo "HA result: $HA_RESULT"
echo "JSON result: $JSON_RESULT"

if [[ "$HA_RESULT" == *"high-availability-test"* ]] && [[ "$JSON_RESULT" == *"true"* ]]; then
    print_success "High-availability Redis test successful"
else
    print_error "High-availability Redis test failed"
    exit 1
fi

echo ""
echo "============================================"
echo "Step 7: Test Zone Redundancy"
echo "============================================"

echo "Creating multiple keys to test distribution..."
for i in {1..10}; do
    if redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning SET "zone_test_key_$i" "zone_data_$i"; then
        echo "  Created zone_test_key_$i"
    else
        print_error "Failed to create zone_test_key_$i"
        exit 1
    fi
done

echo ""
echo "Verifying all keys are accessible..."
KEYS_COUNT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning KEYS "zone_test_key_*" | wc -l | tr -d ' ')

echo "Keys found: $KEYS_COUNT"

if [ "$KEYS_COUNT" -eq 10 ]; then
    print_success "Zone redundancy test successful - all keys accessible"
else
    print_error "Zone redundancy test failed - only $KEYS_COUNT keys found"
    exit 1
fi

echo ""
echo "============================================"
echo "ALL TESTS PASSED!"
echo "============================================"
echo ""
echo "Connection Information:"
terraform output

echo ""
print_info "To clean up resources, run: terraform destroy"
