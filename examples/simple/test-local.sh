#!/bin/bash

# Local test script for Simple Redis example
# This script mimics the GitHub Actions workflow for local debugging

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "Simple Redis Local Test Script"
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
SET_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning SET test "simple-example-test")
echo "SET result: $SET_RESULT"

if [ "$SET_RESULT" != "OK" ]; then
    print_error "SET command failed"
    exit 1
fi
print_success "SET command successful"

# Test GET command
echo ""
print_info "Testing GET command..."
GET_RESULT=$(redis-cli -h "$HOSTNAME" -p "$PORT" --tls -a "$PRIMARY_KEY" --no-auth-warning GET test)
echo "GET result: $GET_RESULT"

if [ "$GET_RESULT" = "simple-example-test" ]; then
    print_success "GET command successful - retrieved value: $GET_RESULT"
else
    print_error "GET command failed - expected 'simple-example-test', got: $GET_RESULT"
    exit 1
fi

echo ""
echo "============================================"
print_success "ALL TESTS PASSED!"
echo "============================================"
echo ""
print_info "Basic Redis operations validated:"
echo "  ✅ PING - Connectivity confirmed"
echo "  ✅ SET - Data storage working"
echo "  ✅ GET - Data retrieval working"
echo ""
print_info "To clean up resources, run:"
echo "  terraform destroy"
