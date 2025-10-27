#!/bin/bash

##############################################################################
# Quick Syntax Check for Flask App
# Tests if the Python files have valid syntax without installing dependencies
##############################################################################

set -e

echo "🔍 Flask App Syntax Check"
echo "========================="
echo ""

cd testing-app

# Check Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

echo "✓ Python: $(python3 --version)"
echo ""

# Check syntax of all Python files
echo "Checking Python file syntax..."
echo ""

FILES=(
    "app.py"
    "config.py"
    "utils/redis_client.py"
    "utils/logger.py"
    "tests/redis_tests.py"
)

all_passed=true

for file in "${FILES[@]}"; do
    echo -n "  $file ... "
    if python3 -m py_compile "$file" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ SYNTAX ERROR"
        python3 -m py_compile "$file"
        all_passed=false
    fi
done

echo ""

if [ "$all_passed" = true ]; then
    echo "✅ All Python files have valid syntax!"
    echo ""
    echo "Next steps:"
    echo "  1. Install dependencies: cd redis-test-app && pip install -r requirements.txt"
    echo "  2. Create .env file: cp .env.example .env"
    echo "  3. Run locally: python app.py"
    exit 0
else
    echo "❌ Some files have syntax errors"
    exit 1
fi
