#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Track results
PASSED=0
FAILED=0
EXAMPLES=()

# Test function for each example
test_example() {
    local example_dir=$1
    local example_name=$(basename "$example_dir")
    
    print_header "Testing: $example_name"
    
    cd "$example_dir"
    
    # Test 1: Status command
    print_info "Test 1: Checking status command..."
    if ./switch-provider.sh status > /dev/null 2>&1; then
        print_success "Status command works"
    else
        print_error "Status command failed"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        return 1
    fi
    
    # Get current provider
    local current_provider="unknown"
    if grep -q "use_azapi = true" main.tf 2>/dev/null || grep -q "use_azapi = true" terraform.tfvars 2>/dev/null; then
        current_provider="azapi"
    elif grep -q "use_azapi = false" main.tf 2>/dev/null || grep -q "use_azapi = false" terraform.tfvars 2>/dev/null; then
        current_provider="azurerm"
    fi
    
    print_info "Current provider: $current_provider"
    
    # Test 2: Switch to opposite provider
    local target_provider
    if [ "$current_provider" = "azapi" ]; then
        target_provider="azurerm"
    else
        target_provider="azapi"
    fi
    
    print_info "Test 2: Switching to $target_provider..."
    if ./switch-provider.sh "to-$target_provider" > /dev/null 2>&1; then
        print_success "Switch to $target_provider succeeded"
    else
        print_error "Switch to $target_provider failed"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        return 1
    fi
    
    # Verify the switch
    local switched=false
    if [ "$target_provider" = "azapi" ]; then
        if grep -q "use_azapi = true" main.tf 2>/dev/null || grep -q "use_azapi = true" terraform.tfvars 2>/dev/null; then
            switched=true
        fi
    else
        if grep -q "use_azapi = false" main.tf 2>/dev/null || grep -q "use_azapi = false" terraform.tfvars 2>/dev/null; then
            switched=true
        fi
    fi
    
    if [ "$switched" = true ]; then
        print_success "Configuration correctly updated"
    else
        print_error "Configuration not updated correctly"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        return 1
    fi
    
    # Test 3: Switch back to original provider
    print_info "Test 3: Switching back to $current_provider..."
    if ./switch-provider.sh "to-$current_provider" > /dev/null 2>&1; then
        print_success "Switch back to $current_provider succeeded"
    else
        print_error "Switch back to $current_provider failed"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        return 1
    fi
    
    # Verify switch back
    switched=false
    if [ "$current_provider" = "azapi" ]; then
        if grep -q "use_azapi = true" main.tf 2>/dev/null || grep -q "use_azapi = true" terraform.tfvars 2>/dev/null; then
            switched=true
        fi
    else
        if grep -q "use_azapi = false" main.tf 2>/dev/null || grep -q "use_azapi = false" terraform.tfvars 2>/dev/null; then
            switched=true
        fi
    fi
    
    if [ "$switched" = true ]; then
        print_success "Configuration correctly restored"
    else
        print_error "Configuration not restored correctly"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        return 1
    fi
    
    # Test 4: Terraform validate
    print_info "Test 4: Running terraform validate..."
    if terraform validate > /dev/null 2>&1; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform validation failed"
        FAILED=$((FAILED + 1))
        cd - > /dev/null
        return 1
    fi
    
    PASSED=$((PASSED + 1))
    EXAMPLES+=("$example_name: PASSED")
    print_success "All tests passed for $example_name"
    
    cd - > /dev/null
}

# Main execution
print_header "Testing Switch Provider Script Across All Examples"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Find all example directories
for example_dir in examples/*/; do
    if [ -f "$example_dir/switch-provider.sh" ]; then
        if test_example "$example_dir"; then
            :
        else
            EXAMPLES+=("$(basename "$example_dir"): FAILED")
        fi
    fi
done

# Print summary
print_header "Test Summary"

echo "Results by example:"
for result in "${EXAMPLES[@]}"; do
    if [[ "$result" == *"PASSED"* ]]; then
        print_success "$result"
    else
        print_error "$result"
    fi
done

echo ""
echo "Total: $((PASSED + FAILED)) examples tested"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
