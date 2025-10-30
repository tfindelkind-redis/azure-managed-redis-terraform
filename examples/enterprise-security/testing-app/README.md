# Redis Testing Application

A Flask-based web application for testing Azure Managed Redis connectivity through Private Link.

## Features

- 🌐 **Web UI Dashboard** - Interactive interface for manual testing
- 🔌 **REST API** - Automated testing via HTTP endpoints
- 🧪 **Comprehensive Tests** - Connection, CRUD, performance, and health checks
- 📊 **Real-time Monitoring** - Live connection status and metrics
- 🔐 **Secure** - API key authentication, VNet integration, HTTPS only
- 📈 **Application Insights** - Full telemetry and monitoring

## Quick Start

### Local Development

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your Redis connection details
   ```

3. **Run the application:**
   ```bash
   python app.py
   ```

4. **Access the dashboard:**
   ```
   http://localhost:5000
   ```

### Deploy to Azure App Service

1. **Deploy infrastructure with Terraform:**
   ```bash
   cd ../
   terraform apply
   ```

2. **Deploy application code:**
   ```bash
   cd redis-test-app
   zip -r ../app.zip .
   
   az webapp deployment source config-zip \
     --resource-group <resource-group> \
     --name <app-service-name> \
     --src ../app.zip
   ```

3. **Get API key:**
   ```bash
   terraform output api_key_command
   # Run the outputted command
   ```

## API Documentation

All API endpoints require the `X-API-Key` header (except UI endpoints).

### Health Check
```bash
GET /api/health
```

### Redis Status
```bash
GET /api/redis/status
Headers: X-API-Key: <your-api-key>
```

### Run Full Test Suite
```bash
POST /api/redis/test
Headers: X-API-Key: <your-api-key>
```

### Simple Ping Test
```bash
POST /api/redis/test/simple
Headers: X-API-Key: <your-api-key>
```

### Performance Test
```bash
POST /api/redis/test/perf
Headers: 
  X-API-Key: <your-api-key>
  Content-Type: application/json
Body:
  {
    "iterations": 100
  }
```

### Redis Info
```bash
GET /api/redis/info
Headers: X-API-Key: <your-api-key>
```

## Web UI Endpoints (No API Key Required)

```bash
GET  /                    # Dashboard
GET  /api/ui/status       # Connection status
POST /api/ui/test         # Run tests from UI
```

## Testing

### Manual Testing via Web UI
1. Navigate to the App Service URL
2. View connection status
3. Click test buttons
4. View results in dashboard

### Automated Testing via API
```bash
# Get API key from Key Vault
API_KEY=$(az keyvault secret show \
  --vault-name <key-vault-name> \
  --name api-key \
  --query value -o tsv)

# Run tests
curl -X POST https://<app-name>.azurewebsites.net/api/redis/test \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json"
```

### CI/CD Integration Example
```yaml
# GitHub Actions
- name: Test Redis
  run: |
    response=$(curl -s -X POST \
      https://${{ env.APP_NAME }}.azurewebsites.net/api/redis/test \
      -H "X-API-Key: ${{ secrets.REDIS_API_KEY }}")
    
    status=$(echo $response | jq -r '.status')
    if [ "$status" != "success" ]; then
      echo "Redis test failed!"
      exit 1
    fi
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `REDIS_HOSTNAME` | Redis hostname | Yes |
| `REDIS_PORT` | Redis port (default: 10000) | Yes |
| `REDIS_PASSWORD` | Redis password | Yes |
| `REDIS_SSL` | Enable SSL (default: true) | Yes |
| `API_KEY` | API key for authentication | Yes |
| `FLASK_ENV` | Flask environment (development/production) | No |
| `LOG_LEVEL` | Logging level (INFO/DEBUG/WARNING) | No |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string | No |

## Project Structure

```
redis-test-app/
├── app.py                  # Flask application
├── config.py               # Configuration
├── requirements.txt        # Python dependencies
├── templates/
│   └── index.html         # Web UI dashboard
├── static/
│   ├── css/
│   │   └── style.css      # Custom styles
│   └── js/
│       └── app.js         # Frontend JavaScript
├── tests/
│   └── redis_tests.py     # Redis test suite
└── utils/
    ├── redis_client.py    # Redis connection manager
    └── logger.py          # Logging utilities
```

## Monitoring

The application integrates with Azure Application Insights for:
- Request tracking
- Dependency tracking (Redis calls)
- Custom metrics
- Performance counters
- Error tracking

View metrics in Azure Portal under Application Insights.

## Troubleshooting

### Connection Fails
- Verify VNet integration is enabled
- Check Private Endpoint connectivity
- Verify Redis password in Key Vault
- Check NSG rules

### API Key Invalid
- Retrieve from Key Vault: `terraform output api_key_command`
- Verify `X-API-Key` header is set correctly

### Tests Timeout
- Check Redis is running
- Verify network connectivity
- Increase timeout in `config.py`

## License

MIT
