#!/bin/bash

##############################################################################
# Run Flask App Locally
# Starts the Redis Testing Dashboard on http://localhost:5000
# The UI will work even without Redis connection (shows "Not Connected")
##############################################################################

set -e

echo "🚀 Starting Redis Testing Dashboard Locally"
echo "==========================================="
echo ""

cd testing-app

# Check if .env.local exists, copy if not
if [ ! -f .env.local ]; then
    echo "❌ .env.local not found"
    exit 1
fi

echo "📝 Using .env.local configuration"
cp .env.local .env
echo ""

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "✓ Python: $PYTHON_VERSION"
echo ""

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo ""
fi

echo "🔧 Activating virtual environment..."
source venv/bin/activate
echo ""

# Install minimal dependencies for UI testing
echo "📥 Installing minimal dependencies..."
cat > requirements-local.txt << 'EOF'
Flask==3.0.0
python-dotenv==1.0.0
Werkzeug==3.0.1
redis==5.0.0
EOF

pip install -q -r requirements-local.txt
echo "✓ Dependencies installed"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🌐 Starting Flask Development Server                     ║"
echo "║                                                            ║"
echo "║  URL: http://localhost:5000                                ║"
echo "║                                                            ║"
echo "║  The UI will work even without Redis connection.          ║"
echo "║  Connection status will show 'Not Connected' - that's OK! ║"
echo "║                                                            ║"
echo "║  Press Ctrl+C to stop the server                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Run the app
python3 app.py
