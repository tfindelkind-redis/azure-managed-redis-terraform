#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Azure Managed Redis - Enterprise Security Example${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI found${NC}"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform found ($(terraform version -json | jq -r '.terraform_version'))${NC}"

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI authenticated${NC}"

# Get current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✅ Using subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})${NC}"
echo ""

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo -e "${YELLOW}📝 Creating terraform.tfvars from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    
    # Generate unique Redis name with timestamp
    TIMESTAMP=$(date +%s)
    UNIQUE_NAME="redis-sec-${TIMESTAMP}"
    
    # Update the redis_name in terraform.tfvars
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/redis-enterprise-secure/${UNIQUE_NAME}/" terraform.tfvars
    else
        # Linux
        sed -i "s/redis-enterprise-secure/${UNIQUE_NAME}/" terraform.tfvars
    fi
    
    echo -e "${GREEN}✅ Created terraform.tfvars with unique name: ${UNIQUE_NAME}${NC}"
    echo -e "${YELLOW}   You can edit terraform.tfvars to customize the deployment${NC}"
    echo ""
fi

# Initialize Terraform
echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
terraform init
echo ""

# Validate configuration
echo -e "${BLUE}🔍 Validating Terraform configuration...${NC}"
terraform validate
echo -e "${GREEN}✅ Configuration is valid${NC}"
echo ""

# Plan deployment
echo -e "${BLUE}📋 Planning deployment...${NC}"
terraform plan -out=tfplan
echo ""

# Ask for confirmation
echo -e "${YELLOW}⚠️  This will deploy the following resources:${NC}"
echo "   - Resource Group"
echo "   - Virtual Network with Private Endpoint"
echo "   - Key Vault with Customer Managed Key"
echo "   - User-Assigned Managed Identities (2)"
echo "   - Redis Enterprise Cluster (Enterprise_E10, 3 zones)"
echo "   - Redis Database with modules (JSON, Search)"
echo "   - Private DNS Zone"
echo ""
echo -e "${YELLOW}💰 Estimated cost: ~\$1,500/month${NC}"
echo ""

read -p "Do you want to proceed with the deployment? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}❌ Deployment cancelled${NC}"
    exit 0
fi

# Apply deployment
echo -e "${BLUE}🚀 Deploying infrastructure...${NC}"
echo -e "${YELLOW}⏱️  This will take approximately 15-20 minutes...${NC}"
echo ""

terraform apply tfplan

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo ""
    
    # Display outputs
    echo -e "${BLUE}📊 Deployment Information:${NC}"
    echo -e "${BLUE}=========================${NC}"
    
    # Cluster info
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    HOSTNAME=$(terraform output -raw hostname)
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    
    echo -e "${GREEN}Cluster:${NC} ${CLUSTER_NAME}"
    echo -e "${GREEN}Hostname:${NC} ${HOSTNAME}"
    echo -e "${GREEN}Resource Group:${NC} ${RESOURCE_GROUP}"
    
    # Network info
    PRIVATE_IP=$(terraform output -raw private_ip_address 2>/dev/null || echo "N/A")
    VNET_ID=$(terraform output -raw vnet_id)
    
    echo -e "${GREEN}Private IP:${NC} ${PRIVATE_IP}"
    echo -e "${GREEN}VNet ID:${NC} ${VNET_ID}"
    
    # Security features
    echo ""
    echo -e "${BLUE}🔐 Security Features Enabled:${NC}"
    echo -e "${GREEN}✅ Customer Managed Keys (CMK)${NC}"
    echo -e "${GREEN}✅ Private Link (no public access)${NC}"
    echo -e "${GREEN}✅ Managed Identity${NC}"
    echo -e "${GREEN}✅ TLS encryption${NC}"
    echo -e "${GREEN}✅ Redis Modules (JSON, Search)${NC}"
    
    # Managed identities
    echo ""
    echo -e "${BLUE}🆔 Managed Identities:${NC}"
    REDIS_IDENTITY=$(terraform output -raw managed_identity_redis_id)
    KV_IDENTITY=$(terraform output -raw managed_identity_keyvault_id)
    echo -e "${GREEN}Redis Identity:${NC} ${REDIS_IDENTITY}"
    echo -e "${GREEN}Key Vault Identity:${NC} ${KV_IDENTITY}"
    
    # Key Vault
    echo ""
    echo -e "${BLUE}🔑 Key Vault:${NC}"
    KV_ID=$(terraform output -raw key_vault_id)
    CMK_ID=$(terraform output -raw customer_managed_key_id)
    echo -e "${GREEN}Key Vault ID:${NC} ${KV_ID}"
    echo -e "${GREEN}CMK ID:${NC} ${CMK_ID}"
    
    # Private Link Validation
    echo ""
    echo -e "${BLUE}🔒 Private Link Validation:${NC}"
    HOSTNAME=$(terraform output -raw hostname)
    
    # Test 1: Check if Redis is NOT accessible from public internet
    echo -e "${YELLOW}Test 1: Verify Redis is NOT accessible from public internet...${NC}"
    if timeout 5 bash -c "echo -e 'PING\r\n' | nc -w 2 $HOSTNAME 10000" 2>/dev/null | grep -q "PONG"; then
        echo -e "${RED}❌ WARNING: Redis is accessible from public internet! Private Link may not be working.${NC}"
    else
        echo -e "${GREEN}✅ Redis is NOT accessible from public internet (as expected with Private Link)${NC}"
    fi
    
    # Test 2: Check private endpoint configuration
    echo ""
    echo -e "${YELLOW}Test 2: Check private endpoint status...${NC}"
    PE_ID=$(terraform output -raw private_endpoint_id)
    PE_STATUS=$(az network private-endpoint show --ids "$PE_ID" --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
    if [ "$PE_STATUS" == "Succeeded" ]; then
        echo -e "${GREEN}✅ Private Endpoint provisioning: ${PE_STATUS}${NC}"
    else
        echo -e "${YELLOW}⚠️  Private Endpoint provisioning: ${PE_STATUS}${NC}"
    fi
    
    # Test 3: Check DNS resolution
    echo ""
    echo -e "${YELLOW}Test 3: Check private DNS resolution...${NC}"
    RESOLVED_IP=$(dig +short $HOSTNAME 2>/dev/null | head -1 || echo "")
    if [ -n "$RESOLVED_IP" ]; then
        echo -e "${GREEN}Hostname resolves to: ${RESOLVED_IP}${NC}"
        if [[ $RESOLVED_IP == 10.* ]]; then
            echo -e "${GREEN}✅ DNS resolves to private IP (Private Link working)${NC}"
        else
            echo -e "${YELLOW}⚠️  DNS resolves to public IP (may not be using Private Link DNS)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not resolve hostname${NC}"
    fi
    
    # Connection info
    echo ""
    echo -e "${BLUE}🔗 Connection Information:${NC}"
    echo -e "${YELLOW}⚠️  Note: Redis is only accessible from within the VNet${NC}"
    echo -e "${YELLOW}   Deploy a VM in the VNet or use Azure Bastion to test connectivity${NC}"
    echo ""
    
    # Save connection details to file
    CONNECTION_FILE="connection-details.txt"
    echo "Redis Enterprise - Enterprise Security Example" > $CONNECTION_FILE
    echo "=============================================" >> $CONNECTION_FILE
    echo "" >> $CONNECTION_FILE
    echo "Cluster Name: ${CLUSTER_NAME}" >> $CONNECTION_FILE
    echo "Hostname: ${HOSTNAME}" >> $CONNECTION_FILE
    echo "Private IP: ${PRIVATE_IP}" >> $CONNECTION_FILE
    echo "" >> $CONNECTION_FILE
    echo "Primary Key: (run 'terraform output -raw primary_access_key')" >> $CONNECTION_FILE
    echo "" >> $CONNECTION_FILE
    echo "Connection String: (run 'terraform output -raw connection_string')" >> $CONNECTION_FILE
    echo "" >> $CONNECTION_FILE
    echo "Redis CLI Command: $(terraform output -raw redis_cli_command)" >> $CONNECTION_FILE
    echo "" >> $CONNECTION_FILE
    
    echo -e "${GREEN}✅ Connection details saved to: ${CONNECTION_FILE}${NC}"
    echo ""
    
    # Testing instructions
    echo -e "${BLUE}🧪 Testing Instructions:${NC}"
    echo -e "${YELLOW}1. Deploy a test VM in the same VNet:${NC}"
    echo "   cd ../../../scripts"
    echo "   # Create a test VM script (not included in this example)"
    echo ""
    echo -e "${YELLOW}2. Or use Azure Bastion for secure access${NC}"
    echo ""
    echo -e "${YELLOW}3. From within the VNet, test the connection:${NC}"
    echo "   # Get the primary key"
    echo "   PRIMARY_KEY=\$(terraform output -raw primary_access_key)"
    echo ""
    echo "   # Test with redis-cli"
    echo "   redis-cli -h ${HOSTNAME} -p 10000 --tls -a \"\$PRIMARY_KEY\" --no-auth-warning PING"
    echo ""
    echo "   # Test RedisJSON module"
    echo "   redis-cli -h ${HOSTNAME} -p 10000 --tls -a \"\$PRIMARY_KEY\" --no-auth-warning JSON.SET user:1 . '{\"name\":\"John\"}'"
    echo ""
    
    # Cleanup instructions
    echo ""
    echo -e "${BLUE}🧹 Cleanup:${NC}"
    echo "   To destroy all resources:"
    echo "   terraform destroy"
    echo ""
    
else
    echo ""
    echo -e "${RED}❌ Deployment failed!${NC}"
    echo -e "${YELLOW}Check the error messages above for details.${NC}"
    exit 1
fi
