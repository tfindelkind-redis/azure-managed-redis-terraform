#!/bin/bash

# Local test script for With-Modules Redis example
# This script mimics the GitHub Actions workflow for local debugging

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "With-Modules Redis Local Test Script"
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

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed"
    exit 1
fi
print_success "Azure CLI is installed"

# Check Azure CLI login status
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure CLI"
    echo "Please run: az login"
    exit 1
fi
print_success "Logged in to Azure CLI"

echo ""
print_info "Current working directory: $SCRIPT_DIR"
echo ""

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init

echo ""
print_info "Planning Terraform deployment..."
terraform plan -out=tfplan

echo ""
print_info "Ready to deploy. This will create Azure resources and may incur costs."
read -p "Do you want to proceed with terraform apply? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    print_info "Deployment cancelled by user"
    exit 0
fi

echo ""
print_info "Applying Terraform configuration..."
terraform apply tfplan

echo ""
print_info "Terraform deployment completed!"

# Extract connection details using explicit parameters approach
echo ""
print_info "Extracting connection details..."

HOSTNAME=$(terraform output -raw hostname)
PRIMARY_KEY=$(terraform state show 'module.redis_enterprise.data.azapi_resource_action.database_keys[0]' | grep 'primaryKey' | sed -n 's/.*primaryKey[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p')
PORT=10000

if [ -z "$HOSTNAME" ]; then
    print_error "Failed to extract hostname"
    exit 1
fi

if [ -z "$PRIMARY_KEY" ]; then
    print_error "Failed to extract primary key"
    exit 1
fi

print_success "Connection details extracted"
echo "  Hostname: $HOSTNAME"
echo "  Port: $PORT"
echo "  Key length: ${#PRIMARY_KEY} characters"

# Test basic connectivity
echo ""
print_info "Testing basic connectivity..."
PING_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning ping)
echo "PING result: $PING_RESULT"

if [ "$PING_RESULT" != "PONG" ]; then
    print_error "PING test failed"
    exit 1
fi
print_success "PING test successful"

# Test SET command
echo ""
print_info "Testing SET command..."
SET_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning SET test "with-modules-test")
echo "SET result: $SET_RESULT"

if [ "$SET_RESULT" != "OK" ]; then
    print_error "SET command failed"
    exit 1
fi
print_success "SET command successful"

# Test JSON.SET command (RedisJSON module)
echo ""
print_info "Testing JSON.SET command (RedisJSON module)..."
JSON_SET_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.SET user:1 $ '{"name":"John","age":30}')
echo "JSON.SET result: $JSON_SET_RESULT"

if [ "$JSON_SET_RESULT" != "OK" ]; then
    print_error "JSON.SET command failed"
    exit 1
fi
print_success "JSON.SET command successful"

# Test JSON.GET command
echo ""
print_info "Testing JSON.GET command..."
JSON_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning JSON.GET user:1 $.name)
echo "JSON.GET result: $JSON_RESULT"

if [[ "$JSON_RESULT" == *"John"* ]]; then
    print_success "JSON.GET command successful - retrieved name: John"
else
    print_error "JSON.GET command failed - expected 'John', got: $JSON_RESULT"
    exit 1
fi

# Test RediSearch module - Create index
echo ""
print_info "Testing FT.CREATE command (RediSearch module)..."
FT_CREATE_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning FT.CREATE products ON HASH PREFIX 1 product: SCHEMA name TEXT price NUMERIC)
echo "FT.CREATE result: $FT_CREATE_RESULT"

if [ "$FT_CREATE_RESULT" != "OK" ]; then
    print_error "FT.CREATE command failed"
    exit 1
fi
print_success "FT.CREATE command successful"

# Add a document for search
echo ""
print_info "Adding document for search test..."
redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning HSET product:1 name "Redis" price 0 > /dev/null
print_success "Document added"

# Test search
echo ""
print_info "Testing FT.SEARCH command..."
FT_SEARCH_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning FT.SEARCH products "Redis")
echo "FT.SEARCH result: $FT_SEARCH_RESULT"

if [[ "$FT_SEARCH_RESULT" == *"product:1"* ]]; then
    print_success "FT.SEARCH command successful - found product:1"
else
    print_error "FT.SEARCH command failed"
    exit 1
fi

# Test RedisBloom module
echo ""
print_info "Testing BF.ADD command (RedisBloom module)..."
BF_ADD_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning BF.ADD users_bloom "user:1")
echo "BF.ADD result: $BF_ADD_RESULT"
print_success "BF.ADD command successful"

# Test bloom filter existence check
echo ""
print_info "Testing BF.EXISTS command..."
BLOOM_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning BF.EXISTS users_bloom "user:1")
echo "BF.EXISTS result: $BLOOM_RESULT"

if [ "$BLOOM_RESULT" = "1" ]; then
    print_success "BF.EXISTS command successful - item found in bloom filter"
else
    print_error "BF.EXISTS command failed - expected 1, got: $BLOOM_RESULT"
    exit 1
fi

# Test RedisTimeSeries module
echo ""
print_info "Testing TS.CREATE command (RedisTimeSeries module)..."
TS_CREATE_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning TS.CREATE temperature RETENTION 86400000 LABELS sensor_id 1 type temp)
echo "TS.CREATE result: $TS_CREATE_RESULT"

if [ "$TS_CREATE_RESULT" != "OK" ]; then
    print_error "TS.CREATE command failed"
    exit 1
fi
print_success "TS.CREATE command successful"

# Add a time series sample
echo ""
print_info "Testing TS.ADD command..."
TS_ADD_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning TS.ADD temperature "*" 23.5)
echo "TS.ADD result: $TS_ADD_RESULT"

if [[ "$TS_ADD_RESULT" =~ ^[0-9]+$ ]]; then
    print_success "TS.ADD command successful - timestamp: $TS_ADD_RESULT"
else
    print_error "TS.ADD command failed"
    exit 1
fi

echo ""
echo "============================================"
print_success "ALL TESTS PASSED!"
echo "============================================"
echo ""
print_info "Redis modules tested:"
echo "  ✅ RedisJSON - JSON document storage"
echo "  ✅ RediSearch - Full-text search capabilities"
echo "  ✅ RedisBloom - Probabilistic data structures"
echo "  ✅ RedisTimeSeries - Time series data management"
echo ""
print_info "To clean up resources, run:"
echo "  terraform destroy"
