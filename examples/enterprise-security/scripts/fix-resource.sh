#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Redis Enterprise - Fix/Redeploy Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo -e "${RED}❌ Error: Terraform not initialized${NC}"
    echo "Run: terraform init"
    exit 1
fi

# Function to show current state
show_state() {
    echo -e "${BLUE}📊 Current Deployment State:${NC}"
    echo ""
    
    # Count resources
    TOTAL=$(terraform state list 2>/dev/null | wc -l | xargs)
    
    if [ "$TOTAL" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No resources deployed yet${NC}"
        echo ""
        echo "Use ./deploy-modular.sh to start deployment"
        exit 0
    fi
    
    echo -e "${GREEN}Total resources: $TOTAL${NC}"
    echo ""
    
    # Group by type
    echo -e "${BLUE}Resource Breakdown:${NC}"
    terraform state list | sed 's/\..*//' | sort | uniq -c | sort -rn
    echo ""
}

# Function to list deployable components
list_components() {
    echo -e "${BLUE}📦 Available Components:${NC}"
    echo ""
    echo "  ${GREEN}1)${NC} Network (VNet + Subnet)"
    echo "     └─ azurerm_virtual_network.main"
    echo "     └─ azurerm_subnet.redis_pe"
    echo ""
    echo "  ${GREEN}2)${NC} Managed Identities"
    echo "     └─ azurerm_user_assigned_identity.redis"
    echo "     └─ azurerm_user_assigned_identity.keyvault_access"
    echo ""
    echo "  ${GREEN}3)${NC} Key Vault"
    echo "     └─ azurerm_key_vault.main"
    echo "     └─ azurerm_key_vault_key.cmk"
    echo "     └─ azurerm_role_assignment.keyvault_crypto_user"
    echo ""
    echo "  ${GREEN}4)${NC} Redis Cache"
    echo "     └─ azurerm_managed_redis.main"
    echo ""
    echo "  ${GREEN}5)${NC} Private Link"
    echo "     └─ azurerm_private_dns_zone.redis"
    echo "     └─ azurerm_private_endpoint.redis"
    echo "     └─ azurerm_private_dns_zone_virtual_network_link.redis"
    echo ""
    echo "  ${GREEN}6)${NC} All Resources (Full Deployment)"
    echo ""
    echo "  ${GREEN}7)${NC} Custom Resource (Enter resource address)"
    echo ""
    echo "  ${GREEN}0)${NC} Exit"
    echo ""
}

# Function to deploy specific component
deploy_component() {
    local component=$1
    
    case $component in
        1)
            echo -e "${BLUE}🌐 Deploying Network...${NC}"
            terraform apply \
                -target="azurerm_virtual_network.main" \
                -target="azurerm_subnet.redis_pe"
            ;;
        2)
            echo -e "${BLUE}🔐 Deploying Managed Identities...${NC}"
            terraform apply \
                -target="azurerm_user_assigned_identity.redis" \
                -target="azurerm_user_assigned_identity.keyvault_access"
            ;;
        3)
            echo -e "${BLUE}🔑 Deploying Key Vault...${NC}"
            terraform apply \
                -target="azurerm_key_vault.main" \
                -target="azurerm_key_vault_key.cmk" \
                -target="azurerm_role_assignment.keyvault_crypto_user"
            ;;
        4)
            echo -e "${BLUE}🚀 Deploying Redis Cache...${NC}"
            echo -e "${YELLOW}⚠️  This may take 15-20 minutes...${NC}"
            terraform apply \
                -target="azurerm_managed_redis.main"
            ;;
        5)
            echo -e "${BLUE}🔗 Deploying Private Link...${NC}"
            terraform apply \
                -target="azurerm_private_dns_zone.redis" \
                -target="azurerm_private_endpoint.redis" \
                -target="azurerm_private_dns_zone_virtual_network_link.redis"
            ;;
        6)
            echo -e "${BLUE}🌟 Deploying All Resources...${NC}"
            terraform apply
            ;;
        7)
            echo ""
            read -p "Enter resource address (e.g., azurerm_managed_redis.main): " RESOURCE_ADDR
            echo ""
            echo -e "${BLUE}🔧 Deploying $RESOURCE_ADDR...${NC}"
            terraform apply -target="$RESOURCE_ADDR"
            ;;
        *)
            echo -e "${RED}Invalid selection${NC}"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✅ Deployment complete!${NC}"
    echo ""
}

# Function to destroy specific component
destroy_component() {
    local component=$1
    
    echo -e "${RED}⚠️  WARNING: This will destroy resources!${NC}"
    read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Cancelled${NC}"
        return 0
    fi
    
    case $component in
        1)
            echo -e "${RED}🗑️  Destroying Network...${NC}"
            terraform destroy \
                -target="azurerm_subnet.redis_pe" \
                -target="azurerm_virtual_network.main"
            ;;
        2)
            echo -e "${RED}🗑️  Destroying Managed Identities...${NC}"
            terraform destroy \
                -target="azurerm_user_assigned_identity.keyvault_access" \
                -target="azurerm_user_assigned_identity.redis"
            ;;
        3)
            echo -e "${RED}🗑️  Destroying Key Vault...${NC}"
            terraform destroy \
                -target="azurerm_role_assignment.keyvault_crypto_user" \
                -target="azurerm_key_vault_key.cmk" \
                -target="azurerm_key_vault.main"
            ;;
        4)
            echo -e "${RED}🗑️  Destroying Redis Cache...${NC}"
            terraform destroy \
                -target="azurerm_managed_redis.main"
            ;;
        5)
            echo -e "${RED}🗑️  Destroying Private Link...${NC}"
            terraform destroy \
                -target="azurerm_private_dns_zone_virtual_network_link.redis" \
                -target="azurerm_private_endpoint.redis" \
                -target="azurerm_private_dns_zone.redis"
            ;;
        7)
            echo ""
            read -p "Enter resource address to destroy: " RESOURCE_ADDR
            echo ""
            echo -e "${RED}🗑️  Destroying $RESOURCE_ADDR...${NC}"
            terraform destroy -target="$RESOURCE_ADDR"
            ;;
        *)
            echo -e "${RED}Invalid selection${NC}"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✅ Destroy complete!${NC}"
    echo ""
}

# Function to taint and redeploy (force recreation)
taint_and_redeploy() {
    local component=$1
    
    case $component in
        1)
            echo -e "${YELLOW}🔄 Forcing recreation of Network...${NC}"
            terraform taint azurerm_virtual_network.main 2>/dev/null || true
            terraform taint azurerm_subnet.redis_pe 2>/dev/null || true
            deploy_component 1
            ;;
        2)
            echo -e "${YELLOW}🔄 Forcing recreation of Managed Identities...${NC}"
            terraform taint azurerm_user_assigned_identity.redis 2>/dev/null || true
            terraform taint azurerm_user_assigned_identity.keyvault_access 2>/dev/null || true
            deploy_component 2
            ;;
        3)
            echo -e "${YELLOW}🔄 Forcing recreation of Key Vault...${NC}"
            terraform taint azurerm_key_vault.main 2>/dev/null || true
            terraform taint azurerm_key_vault_key.cmk 2>/dev/null || true
            deploy_component 3
            ;;
        4)
            echo -e "${YELLOW}🔄 Forcing recreation of Redis Cache...${NC}"
            terraform taint azurerm_managed_redis.main 2>/dev/null || true
            deploy_component 4
            ;;
        5)
            echo -e "${YELLOW}🔄 Forcing recreation of Private Link...${NC}"
            terraform taint azurerm_private_endpoint.redis 2>/dev/null || true
            deploy_component 5
            ;;
        7)
            echo ""
            read -p "Enter resource address to recreate: " RESOURCE_ADDR
            echo ""
            echo -e "${YELLOW}🔄 Forcing recreation of $RESOURCE_ADDR...${NC}"
            terraform taint "$RESOURCE_ADDR" 2>/dev/null || true
            terraform apply -target="$RESOURCE_ADDR"
            ;;
        *)
            echo -e "${RED}Invalid selection${NC}"
            return 1
            ;;
    esac
}

# Main menu
main_menu() {
    while true; do
        show_state
        echo ""
        echo -e "${BLUE}🛠️  What would you like to do?${NC}"
        echo ""
        echo "  ${GREEN}1)${NC} Deploy/Update a component"
        echo "  ${GREEN}2)${NC} Destroy a component"
        echo "  ${GREEN}3)${NC} Force recreation (taint + redeploy)"
        echo "  ${GREEN}4)${NC} View component details"
        echo "  ${GREEN}5)${NC} Run full deployment plan"
        echo "  ${GREEN}6)${NC} Import existing resource"
        echo "  ${GREEN}0)${NC} Exit"
        echo ""
        read -p "Select an option: " ACTION
        echo ""
        
        case $ACTION in
            1)
                list_components
                read -p "Select component to deploy: " COMPONENT
                deploy_component "$COMPONENT"
                ;;
            2)
                list_components
                read -p "Select component to destroy: " COMPONENT
                destroy_component "$COMPONENT"
                ;;
            3)
                list_components
                read -p "Select component to recreate: " COMPONENT
                taint_and_redeploy "$COMPONENT"
                ;;
            4)
                list_components
                read -p "Select component to view: " COMPONENT
                case $COMPONENT in
                    1) terraform state show azurerm_virtual_network.main ;;
                    2) terraform state show azurerm_user_assigned_identity.redis ;;
                    3) terraform state show azurerm_key_vault.main ;;
                    4) terraform state show azurerm_managed_redis.main ;;
                    5) terraform state show azurerm_private_endpoint.redis ;;
                    7) read -p "Enter resource address: " ADDR; terraform state show "$ADDR" ;;
                esac
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                echo -e "${BLUE}📋 Running deployment plan...${NC}"
                terraform plan
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                read -p "Enter resource address (e.g., azurerm_managed_redis.main): " RESOURCE_ADDR
                read -p "Enter Azure resource ID: " AZURE_ID
                echo ""
                echo -e "${BLUE}📥 Importing $RESOURCE_ADDR...${NC}"
                terraform import "$RESOURCE_ADDR" "$AZURE_ID"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    done
}

# Run main menu
main_menu
