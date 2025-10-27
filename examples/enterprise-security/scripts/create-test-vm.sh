#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🖥️  Creating Test VM for Private Link Validation${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Get values from Terraform outputs
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
VNET_NAME=$(terraform output -json vnet_id | jq -r 'split("/") | .[-1]')
SUBNET_NAME="snet-redis-pe"
HOSTNAME=$(terraform output -raw hostname)
LOCATION=$(terraform output -json cluster_id | jq -r 'split("/") | .[-5]')

echo -e "${GREEN}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  VNet: $VNET_NAME"
echo "  Subnet: $SUBNET_NAME"
echo "  Location: $LOCATION"
echo ""

# Check if VM already exists
if az vm show --resource-group "$RESOURCE_GROUP" --name redis-test-vm &>/dev/null; then
    echo -e "${YELLOW}⚠️  VM 'redis-test-vm' already exists${NC}"
    read -p "Do you want to delete and recreate it? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}Deleting existing VM...${NC}"
        az vm delete --resource-group "$RESOURCE_GROUP" --name redis-test-vm --yes
        az network public-ip delete --resource-group "$RESOURCE_GROUP" --name redis-test-vm-ip --yes 2>/dev/null || true
        az network nic delete --resource-group "$RESOURCE_GROUP" --name redis-test-vmVMNic --yes 2>/dev/null || true
    else
        echo -e "${YELLOW}Skipping VM creation${NC}"
        exit 0
    fi
fi

echo -e "${BLUE}Creating Ubuntu VM in the VNet...${NC}"
echo -e "${YELLOW}⏱️  This will take 2-3 minutes...${NC}"
echo ""

# Create VM
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name redis-test-vm \
  --image Ubuntu2204 \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-address redis-test-vm-ip \
  --public-ip-sku Standard \
  --size Standard_B2s \
  --output table

echo ""
echo -e "${GREEN}✅ VM Created Successfully!${NC}"
echo ""

# Get VM IP
VM_IP=$(az vm show -d --resource-group "$RESOURCE_GROUP" --name redis-test-vm --query publicIps -o tsv)

echo -e "${BLUE}📋 Connection Information:${NC}"
echo -e "${GREEN}Public IP:${NC} $VM_IP"
echo -e "${GREEN}SSH Command:${NC} ssh azureuser@$VM_IP"
echo ""

# Create test script to run on VM
cat > redis-test-commands.sh << 'EOF'
#!/bin/bash

# Install redis-cli
echo "Installing redis-cli..."
sudo apt-get update -qq
sudo apt-get install -y redis-tools curl dnsutils

# Get the Redis hostname and key from parameters
HOSTNAME=$1
ACCESS_KEY=$2

echo ""
echo "Testing Redis connectivity..."
echo "Hostname: $HOSTNAME"
echo ""

# Test 1: DNS Resolution
echo "1. Testing DNS resolution..."
RESOLVED_IP=$(dig +short $HOSTNAME | head -1)
echo "   Resolved IP: $RESOLVED_IP"
if [[ $RESOLVED_IP == 10.* ]]; then
    echo "   ✅ Resolves to private IP (Private Link is working!)"
else
    echo "   ⚠️  Resolves to public IP"
fi
echo ""

# Test 2: PING
echo "2. Testing Redis PING..."
if redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning PING 2>/dev/null | grep -q "PONG"; then
    echo "   ✅ PING successful!"
else
    echo "   ❌ PING failed"
    exit 1
fi
echo ""

# Test 3: SET/GET
echo "3. Testing SET/GET..."
redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning SET test:private-link "Connected via Private Link!" > /dev/null
RESULT=$(redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning GET test:private-link)
echo "   Result: $RESULT"
if [ "$RESULT" == "Connected via Private Link!" ]; then
    echo "   ✅ SET/GET successful!"
else
    echo "   ❌ SET/GET failed"
    exit 1
fi
echo ""

# Test 4: RedisJSON
echo "4. Testing RedisJSON module..."
if redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning JSON.SET user:1 . '{"name":"Test User","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' 2>/dev/null | grep -q "OK"; then
    echo "   ✅ RedisJSON working!"
    JSONRESULT=$(redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning JSON.GET user:1)
    echo "   Data: $JSONRESULT"
else
    echo "   ⚠️  RedisJSON test failed (may not be enabled)"
fi
echo ""

# Test 5: RediSearch
echo "5. Testing RediSearch module..."
if redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning FT.CREATE idx:test ON JSON PREFIX 1 user: SCHEMA '$.name' AS name TEXT 2>/dev/null | grep -q "OK"; then
    echo "   ✅ RediSearch index created!"
    redis-cli -h $HOSTNAME -p 10000 --tls -a "$ACCESS_KEY" --no-auth-warning FT.SEARCH idx:test "Test" 2>/dev/null
else
    echo "   ⚠️  RediSearch test failed (index may already exist)"
fi
echo ""

echo "========================================="
echo "✅ All Private Link tests completed!"
echo "========================================="
EOF

chmod +x redis-test-commands.sh

# Copy test script to VM
echo -e "${BLUE}Copying test script to VM...${NC}"
scp -o StrictHostKeyChecking=no redis-test-commands.sh azureuser@$VM_IP:~/

echo ""
echo -e "${BLUE}🧪 How to Run Tests:${NC}"
echo ""
echo -e "${GREEN}Step 1:${NC} Get the Redis access key from Azure:"
echo "   az redisenterprise database list-keys \\"
echo "     --cluster-name $(terraform output -raw cluster_name) \\"
echo "     --resource-group $RESOURCE_GROUP \\"
echo "     --query primaryKey -o tsv"
echo ""
echo -e "${GREEN}Step 2:${NC} SSH to the VM:"
echo "   ssh azureuser@$VM_IP"
echo ""
echo -e "${GREEN}Step 3:${NC} Run the test script on the VM:"
echo "   ./redis-test-commands.sh $HOSTNAME '<paste-access-key-here>'"
echo ""
echo -e "${YELLOW}Or run all at once:${NC}"
echo "   ACCESS_KEY=\$(az redisenterprise database list-keys --cluster-name $(terraform output -raw cluster_name) --resource-group $RESOURCE_GROUP --query primaryKey -o tsv)"
echo "   ssh azureuser@$VM_IP \"./redis-test-commands.sh $HOSTNAME \$ACCESS_KEY\""
echo ""

echo -e "${BLUE}🧹 Cleanup VM when done:${NC}"
echo "   az vm delete --resource-group $RESOURCE_GROUP --name redis-test-vm --yes"
echo "   az network public-ip delete --resource-group $RESOURCE_GROUP --name redis-test-vm-ip --yes"
echo ""
