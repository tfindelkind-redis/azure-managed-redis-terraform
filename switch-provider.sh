#!/bin/bash
set -e

# =============================================================================
# Provider Switching Script for Azure Managed Redis
# =============================================================================
# This script switches between AzAPI and AzureRM providers for the Redis
# cluster and database resources.
#
# IMPORTANT NOTE:
# - Access policy assignments ALWAYS require AzAPI (azurerm doesn't support them)
# - This script only switches the provider for Redis cluster/database resources
# - The azapi provider must remain in versions.tf for access policy assignments
# - For Bicep/ARM deployments, all resources are natively supported
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to detect current provider
detect_current_provider() {
    if [ -f "terraform.tfstate" ]; then
        # Check if we have azapi resources in state (module-based)
        if terraform state list 2>/dev/null | grep -q "module.redis_enterprise.azapi_resource.cluster"; then
            echo "azapi"
        # Check if we have azurerm resources in state (module-based)
        elif terraform state list 2>/dev/null | grep -q "module.redis_enterprise.azurerm_managed_redis.cluster"; then
            echo "azurerm"
        # Check for old direct resources (not using module)
        elif terraform state list 2>/dev/null | grep -q "^azurerm_managed_redis.main"; then
            echo "azurerm-direct"
        else
            echo "unknown"
        fi
    else
        # No state file, check main.tf and terraform.tfvars for use_azapi setting
        if grep -q "use_azapi = false" main.tf 2>/dev/null || grep -q "use_azapi = false" terraform.tfvars 2>/dev/null; then
            echo "azurerm"
        elif grep -q "use_azapi = true" main.tf 2>/dev/null || grep -q "use_azapi = true" terraform.tfvars 2>/dev/null; then
            echo "azapi"
        else
            echo "unknown"
        fi
    fi
}

# Function to update main.tf and terraform.tfvars
update_main_tf() {
    local target_provider=$1
    local use_azapi_value
    
    if [ "$target_provider" = "azapi" ]; then
        use_azapi_value="true"
    else
        use_azapi_value="false"
    fi
    
    # Update the use_azapi value in main.tf if it exists there
    if grep -q "use_azapi" main.tf 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/use_azapi = .*/use_azapi = $use_azapi_value/" main.tf
        else
            # Linux
            sed -i "s/use_azapi = .*/use_azapi = $use_azapi_value/" main.tf
        fi
    fi
    
    # Also update terraform.tfvars if it exists and contains use_azapi
    if [ -f "terraform.tfvars" ] && grep -q "use_azapi" terraform.tfvars; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/use_azapi = .*/use_azapi = $use_azapi_value/" terraform.tfvars
        else
            # Linux
            sed -i "s/use_azapi = .*/use_azapi = $use_azapi_value/" terraform.tfvars
        fi
    fi
    
    print_success "Updated configuration to use_azapi = $use_azapi_value"
}

# Function to switch configuration only (no state migration)
switch_config_only() {
    local target_provider=$1
    local provider_name
    
    if [ "$target_provider" = "azapi" ]; then
        provider_name="AzAPI"
    else
        provider_name="AzureRM"
    fi
    
    print_header "Switching Configuration to $provider_name"
    
    print_info "Updating main.tf to use $provider_name provider..."
    update_main_tf "$target_provider"
    
    print_success "Configuration updated successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Run: terraform init -upgrade"
    echo "  2. Run: terraform plan"
    echo ""
}

# Function to migrate state from AzAPI to AzureRM
migrate_azapi_to_azurerm() {
    print_header "Migrating from AzAPI to AzureRM"
    
    # Check if state file exists and has resources
    if [ ! -f "terraform.tfstate" ] || ! terraform state list 2>/dev/null | grep -q "module.redis_enterprise"; then
        print_warning "No deployed resources found in state."
        print_info "Switching configuration only..."
        switch_config_only "azurerm"
        return
    fi
    
    print_info "Step 1: Backing up current state..."
    cp terraform.tfstate terraform.tfstate.backup-azapi-$(date +%Y%m%d-%H%M%S)
    print_success "State backed up"
    
    print_info "Step 2: Updating main.tf to use AzureRM..."
    update_main_tf "azurerm"
    
    print_info "Step 3: Removing AzAPI resources from state..."
    terraform state rm 'module.redis_enterprise.azapi_resource.cluster[0]' || true
    terraform state rm 'module.redis_enterprise.azapi_resource.database[0]' || true
    terraform state rm 'module.redis_enterprise.data.azapi_resource.cluster_data[0]' || true
    terraform state rm 'module.redis_enterprise.data.azapi_resource_action.database_keys[0]' || true
    print_success "AzAPI resources removed from state"
    
    print_info "Step 4: Importing existing resources into AzureRM provider..."
    
    # Get the cluster ID from the backup state or outputs
    CLUSTER_ID=$(terraform output -raw cluster_id 2>/dev/null || echo "")
    
    if [ -z "$CLUSTER_ID" ]; then
        print_warning "Could not determine cluster ID from outputs."
        print_info "Please provide the Redis cluster resource ID:"
        read -r CLUSTER_ID
    fi
    
    print_info "Importing cluster: $CLUSTER_ID"
    terraform import 'module.redis_enterprise.azurerm_managed_redis.cluster[0]' "$CLUSTER_ID" || {
        print_error "Failed to import cluster"
        exit 1
    }
    
    print_success "Successfully imported AzureRM resources"
    
    print_info "Step 5: Running terraform plan to verify..."
    terraform plan -detailed-exitcode || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 2 ]; then
            print_warning "Plan shows changes. Review carefully before applying."
        elif [ $EXIT_CODE -eq 1 ]; then
            print_error "Plan failed. Please review errors above."
            exit 1
        fi
    }
    
    print_success "Migration from AzAPI to AzureRM completed!"
}

# Function to migrate state from AzureRM to AzAPI
migrate_azurerm_to_azapi() {
    print_header "Migrating from AzureRM to AzAPI"
    
    # Check if state file exists and has resources
    if [ ! -f "terraform.tfstate" ] || ! terraform state list 2>/dev/null | grep -q "module.redis_enterprise"; then
        print_warning "No deployed resources found in state."
        print_info "Switching configuration only..."
        switch_config_only "azapi"
        return
    fi
    
    print_info "Step 1: Backing up current state..."
    cp terraform.tfstate terraform.tfstate.backup-azurerm-$(date +%Y%m%d-%H%M%S)
    print_success "State backed up"
    
    print_info "Step 2: Updating main.tf to use AzAPI..."
    update_main_tf "azapi"
    
    print_info "Step 3: Removing AzureRM resources from state..."
    terraform state rm 'module.redis_enterprise.azurerm_managed_redis.cluster[0]' || true
    print_success "AzureRM resources removed from state"
    
    print_info "Step 4: Importing existing resources into AzAPI provider..."
    
    # Get the cluster ID
    CLUSTER_ID=$(terraform output -raw cluster_id 2>/dev/null || echo "")
    
    if [ -z "$CLUSTER_ID" ]; then
        print_warning "Could not determine cluster ID from outputs."
        print_info "Please provide the Redis cluster resource ID:"
        read -r CLUSTER_ID
    fi
    
    # Extract resource information from cluster ID
    # Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Cache/redisEnterprise/{name}
    DATABASE_ID="${CLUSTER_ID}/databases/default"
    
    print_info "Importing cluster: $CLUSTER_ID"
    terraform import 'module.redis_enterprise.azapi_resource.cluster[0]' "$CLUSTER_ID" || {
        print_error "Failed to import cluster"
        exit 1
    }
    
    print_info "Importing database: $DATABASE_ID"
    terraform import 'module.redis_enterprise.azapi_resource.database[0]' "$DATABASE_ID" || {
        print_error "Failed to import database"
        exit 1
    }
    
    print_success "Successfully imported AzAPI resources"
    
    print_info "Step 5: Running terraform plan to verify..."
    terraform plan -detailed-exitcode || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 2 ]; then
            print_warning "Plan shows changes. Review carefully before applying."
        elif [ $EXIT_CODE -eq 1 ]; then
            print_error "Plan failed. Please review errors above."
            exit 1
        fi
    }
    
    print_success "Migration from AzureRM to AzAPI completed!"
}

# Function to show current status
show_status() {
    print_header "Current Provider Status"
    
    local current_provider=$(detect_current_provider)
    
    echo "Configuration files:"
    if grep -q "use_azapi" main.tf 2>/dev/null; then
        echo "  main.tf: $(grep "use_azapi" main.tf)"
    fi
    if [ -f "terraform.tfvars" ] && grep -q "use_azapi" terraform.tfvars; then
        echo "  terraform.tfvars: $(grep "use_azapi" terraform.tfvars)"
    fi
    if ! grep -q "use_azapi" main.tf 2>/dev/null && ! grep -q "use_azapi" terraform.tfvars 2>/dev/null; then
        echo "  use_azapi setting not found"
    fi
    echo ""
    
    echo "Terraform state:"
    if [ "$current_provider" = "azapi" ]; then
        print_info "Currently using: ${BLUE}AzAPI${NC} provider (module-based)"
        echo ""
        echo "Resources in state:"
        terraform state list | grep "module.redis_enterprise" || echo "  No resources found"
    elif [ "$current_provider" = "azurerm" ]; then
        print_info "Currently using: ${GREEN}AzureRM${NC} provider (module-based)"
        echo ""
        echo "Resources in state:"
        terraform state list | grep "module.redis_enterprise" || echo "  No resources found"
    elif [ "$current_provider" = "azurerm-direct" ]; then
        print_warning "Currently using: ${YELLOW}AzureRM${NC} provider (direct resource, NOT module-based)"
        echo ""
        echo "Resources in state:"
        terraform state list | grep "azurerm_managed_redis" || echo "  No Redis resources found"
        echo ""
        print_warning "NOTE: This configuration uses direct azurerm_managed_redis resource."
        print_warning "      Consider migrating to module-based configuration."
    else
        print_warning "Could not determine current provider"
    fi
    
    echo ""
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [COMMAND]

Switch between AzAPI and AzureRM providers for Azure Managed Redis.

Commands:
    to-azurerm    Switch to AzureRM provider
    to-azapi      Switch to AzAPI provider
    status        Show current provider configuration
    help          Show this help message

Examples:
    $0 to-azurerm     # Switch to native AzureRM provider
    $0 to-azapi       # Switch to AzAPI provider
    $0 status         # Check current provider

Notes:
    - If no resources are deployed, only the configuration is updated
    - If resources exist in state, the script will migrate them between providers
    - State files are automatically backed up before migrations
    - Review the terraform plan output before applying changes
    - Backups are saved as terraform.tfstate.backup-{provider}-{timestamp}

EOF
}

# Main script logic
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    local command=$1
    
    case "$command" in
        to-azurerm)
            local current=$(detect_current_provider)
            if [ "$current" = "azurerm" ]; then
                print_info "Already using AzureRM provider"
                exit 0
            fi
            
            # Check if we have deployed resources
            if [ -f "terraform.tfstate" ] && terraform state list 2>/dev/null | grep -q "module.redis_enterprise"; then
                print_warning "This will migrate your deployed Redis resources from AzAPI to AzureRM provider."
                print_warning "Make sure you have reviewed the migration plan."
                echo ""
                read -p "Do you want to continue? (yes/no): " -r
                if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
                    print_info "Migration cancelled"
                    exit 0
                fi
            else
                print_info "No deployed resources found. Switching configuration only..."
            fi
            
            migrate_azapi_to_azurerm
            ;;
            
        to-azapi)
            local current=$(detect_current_provider)
            if [ "$current" = "azapi" ]; then
                print_info "Already using AzAPI provider"
                exit 0
            fi
            
            # Check if we have deployed resources
            if [ -f "terraform.tfstate" ] && terraform state list 2>/dev/null | grep -q "module.redis_enterprise"; then
                print_warning "This will migrate your deployed Redis resources from AzureRM to AzAPI provider."
                print_warning "Make sure you have reviewed the migration plan."
                echo ""
                read -p "Do you want to continue? (yes/no): " -r
                if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
                    print_info "Migration cancelled"
                    exit 0
                fi
            else
                print_info "No deployed resources found. Switching configuration only..."
            fi
            
            migrate_azurerm_to_azapi
            ;;
            
        status)
            show_status
            ;;
            
        help|--help|-h)
            show_usage
            ;;
            
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
