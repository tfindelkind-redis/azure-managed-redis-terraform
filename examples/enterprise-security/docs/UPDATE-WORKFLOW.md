# Update & Bug Fix Workflow

This guide explains how to fix bugs and update the deployed Flask testing application after initial deployment.

## 🐛 Scenario: Bug in Testing App

You've deployed everything, and discover a bug in one of the test functions in the Flask app.

---

## 🔄 Update Workflow

### **Option 1: Quick Fix with Azure App Service Deployment** (Recommended)

This is the fastest way to update just the application code without touching infrastructure.

#### Step 1: Fix the Bug Locally

```bash
cd testing-app

# Example: Fix bug in tests/redis_tests.py
code tests/redis_tests.py  # or your editor

# Test the fix locally
../scripts/run-app-locally.sh
# Visit http://localhost:5000 and test
```

#### Step 2: Deploy the Fixed Code

```bash
# Stop local server (Ctrl+C)
cd ..  # Back to enterprise-security folder

# Get App Service details
APP_NAME=$(terraform output -raw app_service_name)
RG_NAME=$(terraform output -raw resource_group_name)

# Create deployment package
cd testing-app
zip -r ../redis-test-app.zip . \
    -x "*.pyc" \
    -x "__pycache__/*" \
    -x ".env*" \
    -x ".git/*" \
    -x "*.log" \
    -x ".DS_Store" \
    -x "venv/*" \
    -x ".venv/*"

cd ..

# Deploy updated code
az webapp deployment source config-zip \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME" \
    --src redis-test-app.zip \
    --timeout 600

# Restart app to ensure changes take effect
az webapp restart \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME"

# Clean up
rm redis-test-app.zip

# Open the app in browser
az webapp browse --resource-group "$RG_NAME" --name "$APP_NAME"
```

**Time**: ~2-3 minutes ⚡

---

### **Option 2: Use the Deployment Script**

The `deploy-modular.sh` script can redeploy just the application code.

```bash
# Run the deployment script
./scripts/deploy-modular.sh

# Answer prompts:
# Phase 1-4: 'skip' (infrastructure already deployed)
# Phase 5 (App Service): 'y'
# Deploy Flask app?: 'y'
```

This will:
1. Skip infrastructure phases
2. Redeploy the Flask application
3. Update any secrets if needed
4. Restart the app

**Time**: ~5 minutes (more interactive)

---

### **Option 3: CI/CD with GitHub Actions** (Production Best Practice)

For production environments, set up automated deployment:

#### Create `.github/workflows/deploy-app.yml`:

```yaml
name: Deploy Flask App

on:
  push:
    branches: [main]
    paths:
      - 'examples/enterprise-security/testing-app/**'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Get App Service Name
        id: terraform
        run: |
          cd examples/enterprise-security
          echo "app_name=$(terraform output -raw app_service_name)" >> $GITHUB_OUTPUT
          echo "rg_name=$(terraform output -raw resource_group_name)" >> $GITHUB_OUTPUT
      
      - name: Deploy to Azure App Service
        run: |
          cd examples/enterprise-security/testing-app
          zip -r ../app.zip . -x "*.pyc" "__pycache__/*" ".env*" "venv/*"
          cd ..
          az webapp deployment source config-zip \
            --resource-group ${{ steps.terraform.outputs.rg_name }} \
            --name ${{ steps.terraform.outputs.app_name }} \
            --src app.zip
```

**Benefit**: Automatic deployment on every commit to `testing-app/` folder!

---

## 🧪 Testing Your Fix

### Before Deployment (Local)

```bash
# 1. Run syntax check
./scripts/check-app-syntax.sh

# 2. Test locally
./scripts/run-app-locally.sh
# Visit http://localhost:5000
# Test the specific feature you fixed
```

### After Deployment (Azure)

```bash
# Get the App URL
APP_URL=$(terraform output -raw app_service_url)

# Open in browser
open "$APP_URL"  # macOS
# or
start "$APP_URL"  # Windows
# or  
xdg-open "$APP_URL"  # Linux

# Check logs if needed
az webapp log tail \
    --resource-group $(terraform output -raw resource_group_name) \
    --name $(terraform output -raw app_service_name)
```

---

## 🔍 Common Bug Scenarios & Fixes

### Scenario 1: Bug in Redis Test Function

**File**: `testing-app/tests/redis_tests.py`

```python
# Before (bug - wrong method)
def test_increment(self):
    result = self.redis.incr("test:counter", 2)  # Bug: incr doesn't take amount
```

```python
# After (fixed)
def test_increment(self):
    key = "test:counter"
    self.redis.set(key, 0)  # Initialize
    result = self.redis.incr(key)  # Increment by 1
    result = self.redis.incr(key)  # Increment again
```

**Fix & Deploy**:
```bash
# Edit the file
code testing-app/tests/redis_tests.py

# Test locally
./scripts/run-app-locally.sh

# Deploy (Option 1 - Quick)
APP_NAME=$(terraform output -raw app_service_name)
RG_NAME=$(terraform output -raw resource_group_name)

cd testing-app && \
zip -r ../app.zip . -x "*.pyc" "__pycache__/*" ".env*" "venv/*" && \
cd .. && \
az webapp deployment source config-zip \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME" \
    --src app.zip && \
az webapp restart --resource-group "$RG_NAME" --name "$APP_NAME" && \
rm app.zip
```

---

### Scenario 2: Bug in Web UI (JavaScript)

**File**: `testing-app/static/js/app.js`

```javascript
// Before (bug - wrong endpoint)
fetch('/api/redis/tests')  // Bug: wrong URL

// After (fixed)
fetch('/api/redis/test')  // Correct URL
```

**Fix & Deploy**: Same process as above, just edit the JS file.

---

### Scenario 3: Bug in Flask Route

**File**: `testing-app/app.py`

```python
# Before (bug - missing error handling)
@app.route('/api/redis/status')
def redis_status():
    result = redis_client.ping()  # Bug: can throw exception
    return jsonify({"status": "connected"})
```

```python
# After (fixed)
@app.route('/api/redis/status')
def redis_status():
    try:
        result = redis_client.ping()
        return jsonify({"status": "connected", "ping": result})
    except Exception as e:
        return jsonify({"status": "disconnected", "error": str(e)}), 500
```

**Fix & Deploy**: Same quick deploy process.

---

## 📋 Complete Quick Fix Script

Save this as `scripts/deploy-app-fix.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Quick Deploy Flask App Fix"
echo "==============================="
echo ""

# Get Terraform outputs
APP_NAME=$(terraform output -raw app_service_name)
RG_NAME=$(terraform output -raw resource_group_name)

echo "📦 App Service: $APP_NAME"
echo "📁 Resource Group: $RG_NAME"
echo ""

# Syntax check
echo "🔍 Running syntax check..."
./scripts/check-app-syntax.sh
echo ""

# Create package
echo "📦 Creating deployment package..."
cd testing-app
zip -r ../app-fix.zip . \
    -x "*.pyc" \
    -x "__pycache__/*" \
    -x ".env*" \
    -x ".git/*" \
    -x "*.log" \
    -x ".DS_Store" \
    -x "venv/*" \
    -x ".venv/*" \
    > /dev/null 2>&1
cd ..
echo "✓ Package created"
echo ""

# Deploy
echo "🚀 Deploying to Azure..."
az webapp deployment source config-zip \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME" \
    --src app-fix.zip \
    --timeout 600 \
    > /dev/null 2>&1
echo "✓ Deployed"
echo ""

# Restart
echo "🔄 Restarting app..."
az webapp restart \
    --resource-group "$RG_NAME" \
    --name "$APP_NAME" \
    --output none
echo "✓ Restarted"
echo ""

# Clean up
rm app-fix.zip

# Get URL
APP_URL=$(terraform output -raw app_service_url)

echo "✅ Deployment complete!"
echo ""
echo "🌐 App URL: $APP_URL"
echo ""
echo "Next steps:"
echo "  1. Visit $APP_URL"
echo "  2. Test your fix"
echo "  3. Check logs if needed:"
echo "     az webapp log tail --resource-group $RG_NAME --name $APP_NAME"
```

**Usage**:
```bash
chmod +x scripts/deploy-app-fix.sh
./scripts/deploy-app-fix.sh
```

---

## 🔄 Rollback Strategy

If your fix made things worse:

### Option 1: Redeploy Previous Version

```bash
# If you have the previous version in git
git checkout HEAD~1 -- testing-app/
./scripts/deploy-app-fix.sh
git checkout HEAD -- testing-app/  # Restore current version
```

### Option 2: Use Azure App Service Deployment Slots (Advanced)

```hcl
# Add to app-service.tf
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.redis_test.id

  site_config {
    # Same config as production
  }
}
```

Deploy to staging → Test → Swap to production if good.

---

## 📊 Monitoring After Deployment

```bash
# Watch logs in real-time
az webapp log tail \
    --resource-group $(terraform output -raw resource_group_name) \
    --name $(terraform output -raw app_service_name)

# Check Application Insights metrics
az monitor metrics list \
    --resource $(terraform output -raw app_service_id) \
    --metric "Http5xx" "ResponseTime"
```

---

## ⏱️ Time Comparison

| Method | Time | Complexity | Best For |
|--------|------|------------|----------|
| Quick Deploy (ZIP) | 2-3 min | Low | Hot fixes |
| Deployment Script | 5 min | Medium | Controlled updates |
| CI/CD Pipeline | Automatic | High (setup) | Production |

---

## ✅ Best Practices

1. **Always test locally first** with `./scripts/run-app-locally.sh`
2. **Check syntax** with `./scripts/check-app-syntax.sh`
3. **Use git** to track changes and enable easy rollback
4. **Monitor logs** after deployment for errors
5. **Keep deployment packages small** (exclude venv, cache, etc.)
6. **Document breaking changes** in commit messages
7. **Consider deployment slots** for zero-downtime updates

---

## 🎯 Summary

**For quick bug fixes:**
1. Edit code in `testing-app/`
2. Test locally: `./scripts/run-app-locally.sh`
3. Deploy: `./scripts/deploy-app-fix.sh` (create this script)
4. Verify: Visit the App Service URL
5. Monitor: Check logs if needed

**Infrastructure changes** (Terraform files) require `terraform apply`, but **application code changes** only need a ZIP deploy - much faster! 🚀
