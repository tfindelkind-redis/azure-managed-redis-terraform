#!/bin/bash
# Generate BYOK (Bring Your Own Key) encryption key for Redis Enterprise

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 BYOK Key Generator for Redis Enterprise${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Configuration
KEY_FILE="${1:-redis-encryption-key.pem}"
KEY_SIZE="${2:-2048}"

# Validate key size
if [[ ! "$KEY_SIZE" =~ ^(2048|4096)$ ]]; then
    echo -e "${RED}❌ Error: Invalid key size. Must be 2048 or 4096${NC}"
    echo "Usage: $0 [key_file] [key_size]"
    echo "Example: $0 redis-encryption-key.pem 2048"
    exit 1
fi

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}❌ Error: OpenSSL is not installed${NC}"
    echo "Install with: brew install openssl"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Key file: ${YELLOW}${KEY_FILE}${NC}"
echo -e "  Key size: ${YELLOW}RSA-${KEY_SIZE}${NC}"
echo ""

# Check if key already exists
if [ -f "$KEY_FILE" ]; then
    echo -e "${YELLOW}⚠️  Warning: Key file already exists!${NC}"
    echo -e "${RED}   This will OVERWRITE the existing key${NC}"
    echo -e "${RED}   Make sure you have a backup if needed${NC}"
    echo ""
    read -p "Continue and overwrite? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
    
    # Backup existing key
    BACKUP_FILE="${KEY_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
    mv "$KEY_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✅ Old key backed up to: ${BACKUP_FILE}${NC}"
    echo ""
fi

# Generate the key
echo -e "${BLUE}Generating RSA-${KEY_SIZE} key...${NC}"
openssl genrsa -out "$KEY_FILE" "$KEY_SIZE"

# Set proper permissions (read/write for owner only)
chmod 600 "$KEY_FILE"

echo ""
echo -e "${GREEN}✅ Encryption key generated successfully!${NC}"
echo ""
echo -e "${BLUE}Key Information:${NC}"

# Get key details
KEY_MODULUS=$(openssl rsa -in "$KEY_FILE" -noout -modulus 2>/dev/null | openssl md5)
FILE_SIZE=$(ls -lh "$KEY_FILE" | awk '{print $5}')
echo -e "  File: ${YELLOW}${KEY_FILE}${NC}"
echo -e "  Size: ${YELLOW}${FILE_SIZE}${NC}"
echo -e "  Type: ${YELLOW}RSA-${KEY_SIZE}${NC}"
echo -e "  MD5:  ${YELLOW}${KEY_MODULUS}${NC}"

echo ""
echo -e "${RED}⚠️  CRITICAL SECURITY WARNINGS:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}1. NEVER commit this file to Git${NC}"
echo -e "   ✅ Already added to .gitignore"
echo ""
echo -e "${RED}2. Keep this file SECURE${NC}"
echo -e "   • Store in encrypted storage"
echo -e "   • Restrict file permissions (chmod 600)"
echo -e "   • Don't email or share via insecure channels"
echo ""
echo -e "${RED}3. Create secure backups${NC}"
echo -e "   • Store in multiple secure locations"
echo -e "   • Consider offline/cold storage"
echo -e "   • Use encryption for backups"
echo ""
echo -e "${RED}4. After deployment (OPTIONAL):${NC}"
echo -e "   • You can delete the local copy"
echo -e "   • Key will be in Azure Key Vault"
echo -e "   • Keep offline backup for disaster recovery"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo "1. Verify BYOK is enabled in terraform.tfvars:"
echo -e "   ${BLUE}use_byok = true${NC}"
echo ""
echo "2. Run the deployment:"
echo -e "   ${BLUE}./scripts/deploy-modular.sh${NC}"
echo ""
echo "3. The key will be automatically imported to Azure Key Vault"
echo ""
echo -e "${GREEN}✅ Key generation complete!${NC}"
