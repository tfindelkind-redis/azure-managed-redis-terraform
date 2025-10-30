# Redis Testing App - Migration Plan
## From Azure Functions (EP1) to App Service (S1)

### 📋 Overview
Create a Flask-based web application that provides both a web UI and REST API for testing Redis connectivity through Private Link.

---

## 🎯 Goals

1. **Cost Reduction**: Use App Service S1 (~$70/month) instead of EP1 (~$150/month)
2. **Manual Testing**: Web UI for ad-hoc testing and monitoring
3. **Automated Testing**: REST API for CI/CD integration
4. **Comprehensive Tests**: Connection, read/write, performance, health checks

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│ Azure App Service (S1 Plan)                    │
│ ┌─────────────────────────────────────────────┐ │
│ │ Flask Web App (Python 3.11)                 │ │
│ │                                             │ │
│ │ ┌──────────────┐  ┌──────────────┐        │ │
│ │ │   Web UI     │  │   REST API   │        │ │
│ │ │  (Manual)    │  │ (Automated)  │        │ │
│ │ └──────────────┘  └──────────────┘        │ │
│ │         │                │                 │ │
│ │         └────────┬───────┘                 │ │
│ │                  │                         │ │
│ │         ┌────────▼────────┐                │ │
│ │         │ Redis Test Suite│                │ │
│ │         └────────┬────────┘                │ │
│ └──────────────────┼─────────────────────────┘ │
│                    │                           │
│              VNet Integration                  │
└────────────────────┼───────────────────────────┘
                     │
                     │ Private Link
                     ▼
         ┌───────────────────────┐
         │ Azure Managed Redis   │
         │ (Private Endpoint)    │
         └───────────────────────┘
```

---

## 📦 Application Components

### 1. **Web UI (Manual Testing)**
- Dashboard showing Redis connection status
- Manual test execution buttons
- Real-time results display
- Performance metrics visualization
- Connection details

### 2. **REST API (Automated Testing)**

#### Endpoints:

```
GET  /api/health              - Health check endpoint
GET  /api/redis/status        - Redis connection status
POST /api/redis/test          - Run full test suite
POST /api/redis/test/simple   - Simple ping test
POST /api/redis/test/write    - Test write operations
POST /api/redis/test/read     - Test read operations
POST /api/redis/test/perf     - Performance test
GET  /api/redis/info          - Redis server info
```

#### Response Format:
```json
{
  "status": "success",
  "timestamp": "2025-10-27T10:30:00Z",
  "duration_ms": 45,
  "tests": {
    "connection": {"status": "pass", "latency_ms": 12},
    "ping": {"status": "pass", "response": "PONG"},
    "set": {"status": "pass", "key": "test_key", "value": "test_value"},
    "get": {"status": "pass", "key": "test_key", "value": "test_value"},
    "delete": {"status": "pass", "key": "test_key"}
  },
  "redis_info": {
    "version": "7.2.4",
    "uptime_seconds": 3600,
    "connected_clients": 5
  }
}
```

### 3. **Redis Test Suite**

Tests to implement:
- ✅ Connection test (TCP/SSL)
- ✅ Authentication test
- ✅ PING command
- ✅ SET operation
- ✅ GET operation
- ✅ DELETE operation
- ✅ INCR operation
- ✅ Key expiration (TTL)
- ✅ Performance test (100 operations)
- ✅ INFO command
- ✅ Database selection
- ✅ Error handling

---

## 📁 Project Structure

```
redis-test-app/
├── app.py                      # Flask application entry point
├── requirements.txt            # Python dependencies
├── config.py                   # Configuration management
├── templates/
│   ├── index.html             # Main dashboard
│   └── test_results.html      # Test results page
├── static/
│   ├── css/
│   │   └── style.css          # Custom styles
│   └── js/
│       └── app.js             # Frontend JavaScript
├── tests/
│   ├── __init__.py
│   ├── redis_tests.py         # Redis test implementations
│   └── test_runner.py         # Test execution logic
└── utils/
    ├── __init__.py
    ├── redis_client.py        # Redis connection wrapper
    └── logger.py              # Logging utilities
```

---

## 🔧 Technology Stack

### Backend
- **Framework**: Flask 3.0
- **Redis Client**: redis-py 5.0
- **Async Support**: aioredis (for async tests)
- **Monitoring**: prometheus-flask-exporter

### Frontend
- **UI Framework**: Bootstrap 5
- **Charts**: Chart.js (for performance metrics)
- **HTTP Client**: Fetch API
- **Real-time**: Auto-refresh with JavaScript

### Testing
- **Unit Tests**: pytest
- **Integration Tests**: pytest with redis mock
- **Load Testing**: locust (optional)

---

## 📝 Implementation Steps

### Phase 1: Infrastructure Setup (Terraform)
```
✓ Create App Service Plan (S1)
✓ Create App Service (Linux, Python 3.11)
✓ Configure VNet Integration
✓ Set App Settings (Redis connection strings)
✓ Enable Application Insights
✓ Configure deployment from local Git
```

### Phase 2: Core Application
```
✓ Initialize Flask application
✓ Create Redis connection manager
✓ Implement basic health check endpoint
✓ Create simple web UI dashboard
✓ Add connection status display
```

### Phase 3: Test Suite Implementation
```
✓ Implement connection tests
✓ Implement CRUD operation tests
✓ Implement performance tests
✓ Add error handling and logging
✓ Create test result formatter
```

### Phase 4: API Development
```
✓ Create REST API endpoints
✓ Add JSON response formatting
✓ Implement authentication (API key)
✓ Add rate limiting
✓ Document API with OpenAPI/Swagger
```

### Phase 5: Web UI Enhancement
```
✓ Create interactive dashboard
✓ Add test execution buttons
✓ Display real-time results
✓ Add performance charts
✓ Implement auto-refresh
```

### Phase 6: Deployment & Testing
```
✓ Deploy to App Service
✓ Test VNet connectivity
✓ Validate all test scenarios
✓ Set up monitoring and alerts
✓ Create user documentation
```

---

## 🚀 Deployment Strategy

### Option A: Git Deployment
```bash
git init
git remote add azure <app-service-git-url>
git push azure main
```

### Option B: ZIP Deployment
```bash
zip -r app.zip .
az webapp deployment source config-zip \
  --resource-group $RG \
  --name $APP_NAME \
  --src app.zip
```

### Option C: Container Deployment
```bash
docker build -t redis-test-app .
docker tag redis-test-app $ACR.azurecr.io/redis-test-app
docker push $ACR.azurecr.io/redis-test-app
az webapp config container set \
  --name $APP_NAME \
  --resource-group $RG \
  --docker-custom-image-name $ACR.azurecr.io/redis-test-app
```

---

## 📊 Monitoring & Observability

### Application Insights Integration
- Request tracking
- Dependency tracking (Redis calls)
- Custom metrics (test success rate)
- Performance counters
- Availability tests

### Custom Metrics
- Redis connection status
- Test execution count
- Test success/failure rate
- Average latency
- Error rate

### Alerts
- Redis connection failures
- High latency (>100ms)
- Test failures
- App Service down

---

## 🔐 Security Considerations

1. **API Authentication**
   - Use API keys for REST API
   - Store in Azure Key Vault
   - Rotate regularly

2. **Network Security**
   - VNet Integration for Private Link access
   - Restrict public access to App Service (optional)
   - Use HTTPS only

3. **Secrets Management**
   - Store Redis password in Key Vault
   - Use Managed Identity for Key Vault access
   - Never log sensitive data

4. **CORS Configuration**
   - Restrict allowed origins
   - Enable only for trusted domains

---

## 💰 Cost Comparison

| Component | Monthly Cost |
|-----------|-------------|
| **Azure Function (EP1)** | $150 |
| **App Service (S1)** | $70 |
| **Savings** | **$80/month** |
| **Savings (Annual)** | **$960/year** |

Additional costs:
- Application Insights: ~$5/month (basic)
- Storage (logs): ~$2/month

**Total estimated cost: ~$77/month** (vs $150/month)

---

## 🧪 Testing Scenarios

### Manual Testing (Web UI)
1. Navigate to: `https://<app-name>.azurewebsites.net`
2. View connection status dashboard
3. Click "Run Full Test Suite"
4. View detailed results
5. Check performance metrics

### Automated Testing (API)
```bash
# Health check
curl https://<app-name>.azurewebsites.net/api/health

# Run full test suite
curl -X POST https://<app-name>.azurewebsites.net/api/redis/test \
  -H "X-API-Key: <your-api-key>" \
  -H "Content-Type: application/json"

# Get Redis status
curl https://<app-name>.azurewebsites.net/api/redis/status \
  -H "X-API-Key: <your-api-key>"
```

### CI/CD Integration Example
```yaml
# GitHub Actions
- name: Test Redis Connectivity
  run: |
    response=$(curl -s -X POST \
      https://${{ env.APP_NAME }}.azurewebsites.net/api/redis/test \
      -H "X-API-Key: ${{ secrets.API_KEY }}")
    
    status=$(echo $response | jq -r '.status')
    if [ "$status" != "success" ]; then
      echo "Redis test failed!"
      exit 1
    fi
```

---

## 📚 Sample Code Snippets

### Redis Connection Manager
```python
import redis
from config import Config

class RedisManager:
    def __init__(self):
        self.client = None
        
    def connect(self):
        self.client = redis.Redis(
            host=Config.REDIS_HOSTNAME,
            port=Config.REDIS_PORT,
            password=Config.REDIS_PASSWORD,
            ssl=Config.REDIS_SSL,
            decode_responses=True
        )
        return self.client.ping()
```

### Test Suite Example
```python
def run_full_test_suite():
    results = {
        "timestamp": datetime.utcnow().isoformat(),
        "tests": {}
    }
    
    # Connection test
    results["tests"]["connection"] = test_connection()
    
    # CRUD operations
    results["tests"]["set"] = test_set_operation()
    results["tests"]["get"] = test_get_operation()
    results["tests"]["delete"] = test_delete_operation()
    
    # Performance test
    results["tests"]["performance"] = test_performance()
    
    return results
```

---

## 🎯 Success Criteria

- ✅ App Service deployed and accessible via HTTPS
- ✅ VNet integration configured and working
- ✅ Web UI loads and displays Redis status
- ✅ All manual tests can be executed from UI
- ✅ REST API endpoints return valid responses
- ✅ Automated tests pass in CI/CD pipeline
- ✅ Application Insights collecting telemetry
- ✅ Response time < 500ms for all tests
- ✅ 99.9% uptime SLA met

---

## 📅 Estimated Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: Infrastructure | 2 hours | Terraform code, deployed resources |
| Phase 2: Core App | 3 hours | Basic Flask app, Redis connection |
| Phase 3: Test Suite | 4 hours | Complete test implementations |
| Phase 4: API | 3 hours | REST API with all endpoints |
| Phase 5: Web UI | 4 hours | Interactive dashboard |
| Phase 6: Deployment | 2 hours | Production deployment, docs |
| **Total** | **18 hours** | **Fully functional testing app** |

---

## 🔄 Next Steps

1. **Review this plan** - Get approval on approach
2. **Create Terraform module** - App Service infrastructure
3. **Build Flask application** - Core app structure
4. **Implement test suite** - Redis tests
5. **Create web UI** - Dashboard and controls
6. **Deploy and test** - End-to-end validation

---

## 📖 Documentation Deliverables

1. **README.md** - Setup and deployment instructions
2. **API.md** - REST API documentation
3. **TESTING.md** - Test scenarios and usage guide
4. **DEPLOYMENT.md** - Deployment procedures
5. **TROUBLESHOOTING.md** - Common issues and solutions

---

**Ready to proceed?** Let me know and I'll start implementing this plan!
