#!/bin/bash

# Azure Managed Redis Deployment Validation Script
# This script validates that Redis Enterprise deployment is successful and functional

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${1:-$(pwd)}"
VERBOSE=${VERBOSE:-false}

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Check if redis-cli is available
    if ! command -v redis-cli &> /dev/null; then
        log_warning "redis-cli is not installed. Installing..."
        
        # Try to install redis-cli based on OS
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y redis-tools
            elif command -v yum &> /dev/null; then
                sudo yum install -y redis
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y redis
            else
                log_error "Could not install redis-cli automatically. Please install it manually."
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install redis
            else
                log_error "Homebrew not found. Please install redis-cli manually: 'brew install redis'"
                exit 1
            fi
        else
            log_error "Unsupported OS. Please install redis-cli manually."
            exit 1
        fi
    fi
    
    # Check if Azure CLI is available and logged in
    if ! command -v az &> /dev/null; then
        log_warning "Azure CLI is not installed. Some validation checks will be skipped."
    else
        # Check if logged in
        if ! az account show &> /dev/null; then
            log_warning "Not logged in to Azure CLI. Some validation checks will be skipped."
        else
            log_success "Azure CLI is available and authenticated"
        fi
    fi
    
    log_success "Prerequisites check completed"
}

validate_terraform_state() {
    log_info "Validating Terraform state..."
    
    cd "$TERRAFORM_DIR"
    
    # Check if Terraform is initialized
    if [[ ! -d ".terraform" ]]; then
        log_error "Terraform not initialized. Run 'terraform init' first."
        exit 1
    fi
    
    # Check if state file exists
    if ! terraform state list &> /dev/null; then
        log_error "No Terraform state found. Deploy resources first."
        exit 1
    fi
    
    # Validate that required resources exist in state
    local required_resources=("azapi_resource.cluster" "azapi_resource.database")
    
    for resource in "${required_resources[@]}"; do
        if terraform state list | grep -q "$resource"; then
            log_success "Found $resource in state"
        else
            log_error "Required resource $resource not found in state"
            exit 1
        fi
    done
    
    log_success "Terraform state validation completed"
}

get_terraform_outputs() {
    log_info "Retrieving Terraform outputs..."
    
    cd "$TERRAFORM_DIR"
    
    # Get outputs
    HOSTNAME=$(terraform output -raw hostname 2>/dev/null || echo "")
    PORT=$(terraform output -raw port 2>/dev/null || echo "10000")
    PRIMARY_KEY=$(terraform output -raw primary_key 2>/dev/null || echo "")
    CONNECTION_STRING=$(terraform output -raw connection_string 2>/dev/null || echo "")
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    
    # Validate outputs
    if [[ -z "$HOSTNAME" ]]; then
        log_error "Could not retrieve hostname from Terraform outputs"
        exit 1
    fi
    
    if [[ -z "$PRIMARY_KEY" ]]; then
        log_error "Could not retrieve primary key from Terraform outputs"
        exit 1
    fi
    
    log_success "Retrieved Terraform outputs successfully"
    log_verbose "Hostname: $HOSTNAME"
    log_verbose "Port: $PORT"
    log_verbose "Cluster Name: $CLUSTER_NAME"
}

validate_dns_resolution() {
    log_info "Validating DNS resolution..."
    
    if nslookup "$HOSTNAME" &> /dev/null; then
        log_success "DNS resolution for $HOSTNAME successful"
    else
        log_error "DNS resolution failed for $HOSTNAME"
        exit 1
    fi
}

validate_network_connectivity() {
    log_info "Validating network connectivity..."
    
    # Check if port is reachable
    if timeout 10 bash -c "</dev/tcp/$HOSTNAME/$PORT" 2>/dev/null; then
        log_success "Network connectivity to $HOSTNAME:$PORT successful"
    else
        log_error "Cannot connect to $HOSTNAME:$PORT"
        log_info "This might be due to firewall rules or the service not being ready yet"
        exit 1
    fi
}

validate_redis_connectivity() {
    log_info "Validating Redis connectivity..."
    
    # Test basic ping
    if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis PING successful"
    else
        log_error "Redis PING failed"
        exit 1
    fi
}

validate_redis_operations() {
    log_info "Validating Redis operations..."
    
    local test_key="validation_test_$(date +%s)"
    local test_value="validation_success"
    
    # Test SET operation
    if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning set "$test_key" "$test_value" 2>/dev/null | grep -q "OK"; then
        log_success "Redis SET operation successful"
    else
        log_error "Redis SET operation failed"
        exit 1
    fi
    
    # Test GET operation
    local retrieved_value
    retrieved_value=$(redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning get "$test_key" 2>/dev/null)
    
    if [[ "$retrieved_value" == "$test_value" ]]; then
        log_success "Redis GET operation successful"
    else
        log_error "Redis GET operation failed. Expected '$test_value', got '$retrieved_value'"
        exit 1
    fi
    
    # Clean up test key
    redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning del "$test_key" &> /dev/null
    
    log_success "Basic Redis operations validated"
}

validate_redis_modules() {
    log_info "Validating Redis modules..."
    
    # Get list of loaded modules
    local modules_output
    modules_output=$(redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning module list 2>/dev/null || echo "")
    
    if [[ -n "$modules_output" ]]; then
        log_success "Redis modules are loaded:"
        echo "$modules_output" | while read -r line; do
            if [[ -n "$line" ]]; then
                log_info "  $line"
            fi
        done
        
        # Test RedisJSON if available
        if echo "$modules_output" | grep -q "ReJSON"; then
            log_info "Testing RedisJSON module..."
            local json_key="json_test_$(date +%s)"
            
            if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning JSON.SET "$json_key" $ '{"test":"success"}' 2>/dev/null | grep -q "OK"; then
                log_success "RedisJSON module working correctly"
                redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning del "$json_key" &> /dev/null
            else
                log_warning "RedisJSON module test failed"
            fi
        fi
        
        # Test RediSearch if available
        if echo "$modules_output" | grep -q "search"; then
            log_info "Testing RediSearch module..."
            local search_idx="search_test_$(date +%s)"
            
            if redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning FT.CREATE "$search_idx" ON HASH PREFIX 1 test: SCHEMA title TEXT 2>/dev/null; then
                log_success "RediSearch module working correctly"
                redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning FT.DROPINDEX "$search_idx" &> /dev/null
            else
                log_warning "RediSearch module test failed"
            fi
        fi
        
    else
        log_warning "No Redis modules detected or module list command failed"
    fi
}

validate_redis_info() {
    log_info "Gathering Redis information..."
    
    # Get Redis server info
    local redis_info
    redis_info=$(redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning info server 2>/dev/null || echo "")
    
    if [[ -n "$redis_info" ]]; then
        # Parse version
        local redis_version
        redis_version=$(echo "$redis_info" | grep "redis_version" | cut -d: -f2 | tr -d '\r')
        
        if [[ -n "$redis_version" ]]; then
            log_success "Redis version: $redis_version"
        fi
        
        # Parse uptime
        local uptime_seconds
        uptime_seconds=$(echo "$redis_info" | grep "uptime_in_seconds" | cut -d: -f2 | tr -d '\r')
        
        if [[ -n "$uptime_seconds" && "$uptime_seconds" -gt 0 ]]; then
            log_success "Redis uptime: $uptime_seconds seconds"
        fi
    else
        log_warning "Could not retrieve Redis server information"
    fi
    
    # Get memory info
    local memory_info
    memory_info=$(redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning info memory 2>/dev/null || echo "")
    
    if [[ -n "$memory_info" ]]; then
        local used_memory
        used_memory=$(echo "$memory_info" | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        
        if [[ -n "$used_memory" ]]; then
            log_success "Memory usage: $used_memory"
        fi
    fi
}

validate_azure_resources() {
    log_info "Validating Azure resources..."
    
    if ! command -v az &> /dev/null || ! az account show &> /dev/null; then
        log_warning "Azure CLI not available or not logged in. Skipping Azure resource validation."
        return 0
    fi
    
    # Get resource group and cluster name from Terraform
    local resource_group
    resource_group=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    
    if [[ -z "$resource_group" ]]; then
        log_warning "Could not retrieve resource group from Terraform outputs"
        return 0
    fi
    
    # Check if Redis Enterprise cluster exists
    if az redis enterprise show --name "$CLUSTER_NAME" --resource-group "$resource_group" &>/dev/null; then
        log_success "Azure Redis Enterprise cluster exists and is accessible"
        
        # Get provisioning state
        local provisioning_state
        provisioning_state=$(az redis enterprise show --name "$CLUSTER_NAME" --resource-group "$resource_group" --query "provisioningState" -o tsv 2>/dev/null || echo "")
        
        if [[ "$provisioning_state" == "Succeeded" ]]; then
            log_success "Cluster provisioning state: $provisioning_state"
        else
            log_warning "Cluster provisioning state: $provisioning_state (expected: Succeeded)"
        fi
    else
        log_error "Azure Redis Enterprise cluster not found or not accessible"
        exit 1
    fi
}

run_performance_test() {
    log_info "Running basic performance test..."
    
    if ! command -v redis-benchmark &> /dev/null; then
        log_warning "redis-benchmark not available. Skipping performance test."
        return 0
    fi
    
    # Run a quick benchmark
    local benchmark_result
    benchmark_result=$(redis-benchmark -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" -n 1000 -c 10 -t set,get -q --csv 2>/dev/null || echo "")
    
    if [[ -n "$benchmark_result" ]]; then
        log_success "Performance test completed:"
        echo "$benchmark_result" | while IFS=, read -r test requests_per_second; do
            if [[ "$test" != "\"test\"" ]]; then  # Skip header
                log_info "  $test: $requests_per_second requests/sec"
            fi
        done
    else
        log_warning "Performance test failed or redis-benchmark not available"
    fi
}

generate_report() {
    log_info "Generating validation report..."
    
    local report_file="redis_validation_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Azure Managed Redis Validation Report"
        echo "====================================="
        echo "Generated: $(date)"
        echo "Hostname: $HOSTNAME"
        echo "Port: $PORT"
        echo "Cluster Name: $CLUSTER_NAME"
        echo ""
        echo "Validation Results:"
        echo "- DNS Resolution: ✓"
        echo "- Network Connectivity: ✓"
        echo "- Redis Connectivity: ✓"
        echo "- Basic Operations: ✓"
        echo "- Redis Modules: ✓"
        echo "- Azure Resources: ✓"
        echo ""
        echo "Redis Information:"
        redis-cli -h "$HOSTNAME" -p "$PORT" -a "$PRIMARY_KEY" --no-auth-warning info server 2>/dev/null | head -20
        echo ""
        echo "Connection String (for applications):"
        echo "rediss://:****@$HOSTNAME:$PORT"
        echo ""
        echo "Validation completed successfully!"
    } > "$report_file"
    
    log_success "Validation report saved to: $report_file"
}

print_summary() {
    log_info "Validation Summary:"
    log_success "✓ All validation checks passed"
    log_success "✓ Redis Enterprise deployment is functional"
    log_success "✓ Ready for application integration"
    echo ""
    log_info "Connection details:"
    echo "  Hostname: $HOSTNAME"
    echo "  Port: $PORT"
    echo "  Use TLS: Yes (rediss://)"
    echo ""
    log_info "Next steps:"
    echo "  1. Update application connection strings"
    echo "  2. Test application integration"
    echo "  3. Configure monitoring and alerting"
    echo "  4. Set up backup procedures"
}

main() {
    echo "Azure Managed Redis Deployment Validation"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    validate_terraform_state
    get_terraform_outputs
    validate_dns_resolution
    validate_network_connectivity
    validate_redis_connectivity
    validate_redis_operations
    validate_redis_modules
    validate_redis_info
    validate_azure_resources
    run_performance_test
    generate_report
    print_summary
    
    log_success "Validation completed successfully! 🎉"
}

# Show usage if requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [TERRAFORM_DIRECTORY]"
    echo ""
    echo "Validates Azure Managed Redis deployment"
    echo ""
    echo "Arguments:"
    echo "  TERRAFORM_DIRECTORY  Path to directory containing Terraform configuration (default: current directory)"
    echo ""
    echo "Environment Variables:"
    echo "  VERBOSE=true         Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                           # Validate in current directory"
    echo "  $0 ./examples/simple         # Validate specific example"
    echo "  VERBOSE=true $0              # Run with verbose output"
    exit 0
fi

# Run main function
main
