#!/bin/bash

##############################################################################
# Local Test Script for Redis Testing App
#
# This script tests the Flask application locally before deploying to Azure
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Local Flask App Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to app directory
cd redis-test-app

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed${NC}"
    echo "Please install Python 3.11 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✓ Python version: $PYTHON_VERSION${NC}"
echo ""

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip > /dev/null 2>&1

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install -r requirements.txt > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ .env file created${NC}"
    echo -e "${YELLOW}⚠️  Please edit .env with your Redis connection details${NC}"
    echo ""
fi

# Test import of modules
echo -e "${BLUE}Testing Python imports...${NC}"
python3 -c "
import sys
try:
    import flask
    print('✓ Flask imported successfully')
    import redis
    print('✓ Redis client imported successfully')
    import config
    print('✓ Config module imported successfully')
    from utils import redis_client
    print('✓ Utils modules imported successfully')
    from tests import redis_test_suite
    print('✓ Test modules imported successfully')
    print('\n✅ All imports successful!')
except ImportError as e:
    print(f'❌ Import error: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All Python imports successful${NC}"
else
    echo -e "${RED}❌ Import test failed${NC}"
    deactivate
    exit 1
fi
echo ""

# Test Flask app syntax
echo -e "${BLUE}Testing Flask app syntax...${NC}"
python3 -c "
import app
print('✓ Flask app loaded successfully')
print(f'✓ App name: {app.app.name}')
print(f'✓ Debug mode: {app.app.debug}')
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Flask app syntax is valid${NC}"
else
    echo -e "${RED}❌ Flask app has syntax errors${NC}"
    deactivate
    exit 1
fi
echo ""

# Ask if user wants to start the server
echo -e "${YELLOW}Would you like to start the development server?${NC}"
echo -e "${YELLOW}(Redis connection will fail if Redis is not available)${NC}"
read -p "Start server? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Starting Flask development server...${NC}"
    echo -e "${BLUE}Access the app at: http://localhost:5000${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
    
    # Start the Flask app
    python3 app.py
else
    echo -e "${YELLOW}Skipping server start${NC}"
fi

# Deactivate virtual environment
deactivate

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Testing Complete${NC}"
echo -e "${GREEN}========================================${NC}"
