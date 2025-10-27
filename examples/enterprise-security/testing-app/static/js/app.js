// Redis Testing App JavaScript

/**
 * Refresh connection status
 */
async function refreshStatus() {
    try {
        const response = await fetch('/api/ui/status');
        const data = await response.json();
        
        updateConnectionStatus(data);
    } catch (error) {
        console.error('Failed to fetch status:', error);
        updateConnectionStatus({ connected: false, timestamp: new Date().toISOString() });
    }
}

/**
 * Update connection status display
 */
function updateConnectionStatus(data) {
    const indicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('connectionStatus');
    const lastCheck = document.getElementById('lastCheck');
    
    if (data.connected) {
        indicator.className = 'status-indicator connected';
        statusText.textContent = 'Connected';
        statusText.className = 'fw-bold text-success';
    } else {
        indicator.className = 'status-indicator disconnected';
        statusText.textContent = 'Disconnected';
        statusText.className = 'fw-bold text-danger';
    }
    
    const timestamp = new Date(data.timestamp);
    lastCheck.textContent = timestamp.toLocaleTimeString();
}

/**
 * Run a test
 */
async function runTest(testType) {
    const resultsContainer = document.getElementById('resultsContainer');
    const loadingSpinner = document.getElementById('loadingSpinner');
    const testStatus = document.getElementById('testStatus');
    
    // Show loading
    resultsContainer.style.display = 'none';
    loadingSpinner.style.display = 'block';
    testStatus.textContent = 'Running...';
    testStatus.className = 'badge bg-warning';
    
    try {
        const response = await fetch('/api/ui/test', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ type: testType })
        });
        
        const data = await response.json();
        
        // Hide loading
        loadingSpinner.style.display = 'none';
        resultsContainer.style.display = 'block';
        
        // Display results
        displayResults(data, testType);
        
        // Update status badge
        if (data.status === 'success') {
            testStatus.textContent = 'Success';
            testStatus.className = 'badge bg-success';
        } else {
            testStatus.textContent = 'Failed';
            testStatus.className = 'badge bg-danger';
        }
    } catch (error) {
        console.error('Test failed:', error);
        loadingSpinner.style.display = 'none';
        resultsContainer.style.display = 'block';
        
        resultsContainer.innerHTML = `
            <div class="alert alert-danger">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <strong>Error:</strong> ${error.message}
            </div>
        `;
        
        testStatus.textContent = 'Error';
        testStatus.className = 'badge bg-danger';
    }
}

/**
 * Display test results
 */
function displayResults(data, testType) {
    const resultsContainer = document.getElementById('resultsContainer');
    const metricsRow = document.getElementById('metricsRow');
    
    if (testType === 'full' && data.tests) {
        // Display full test suite results
        displayFullTestResults(data);
        
        // Show and update metrics
        metricsRow.style.display = 'flex';
        document.getElementById('testsPassed').textContent = data.tests_passed || 0;
        document.getElementById('testsFailed').textContent = data.tests_failed || 0;
        document.getElementById('totalDuration').textContent = 
            (data.total_duration_ms || 0).toFixed(2) + 'ms';
        
        // Get ops/sec from performance test if available
        const perfOps = data.tests?.performance?.ops_per_second || 0;
        document.getElementById('opsPerSec').textContent = perfOps.toFixed(0);
    } else if (testType === 'simple') {
        // Display simple test result
        displaySimpleTestResult(data);
        metricsRow.style.display = 'none';
    } else if (testType === 'performance') {
        // Display performance test result
        displayPerformanceTestResult(data);
        metricsRow.style.display = 'none';
    } else {
        // Display raw JSON
        resultsContainer.innerHTML = `
            <div class="json-output">
                <pre>${JSON.stringify(data, null, 2)}</pre>
            </div>
        `;
        metricsRow.style.display = 'none';
    }
}

/**
 * Display full test suite results
 */
function displayFullTestResults(data) {
    const resultsContainer = document.getElementById('resultsContainer');
    
    let html = '<div class="test-results">';
    
    // Add summary
    html += `
        <div class="alert ${data.status === 'success' ? 'alert-success' : 'alert-danger'} mb-3">
            <div class="d-flex justify-content-between align-items-center">
                <div>
                    <i class="bi ${data.status === 'success' ? 'bi-check-circle-fill' : 'bi-x-circle-fill'}"></i>
                    <strong>Test Suite ${data.status === 'success' ? 'Passed' : 'Failed'}</strong>
                </div>
                <div>
                    ${data.tests_passed}/${data.tests_total} tests passed
                    (${data.total_duration_ms.toFixed(2)}ms)
                </div>
            </div>
        </div>
    `;
    
    // Add individual test results
    for (const [testName, result] of Object.entries(data.tests)) {
        const isPassed = result.status === 'pass';
        const icon = isPassed ? 'check-circle-fill text-success' : 'x-circle-fill text-danger';
        
        html += `
            <div class="test-result ${isPassed ? 'pass' : 'fail'}">
                <div class="d-flex justify-content-between align-items-start">
                    <div class="flex-grow-1">
                        <div class="test-name">
                            <i class="bi bi-${icon}"></i>
                            ${testName.replace(/_/g, ' ')}
                        </div>
                        <div class="test-detail">
                            ${formatTestDetails(testName, result)}
                        </div>
                    </div>
                    ${result.duration_ms ? 
                        `<span class="badge bg-secondary">${result.duration_ms.toFixed(2)}ms</span>` : 
                        ''
                    }
                </div>
            </div>
        `;
    }
    
    html += '</div>';
    resultsContainer.innerHTML = html;
}

/**
 * Display simple test result
 */
function displaySimpleTestResult(data) {
    const resultsContainer = document.getElementById('resultsContainer');
    const isPassed = data.status === 'pass';
    
    resultsContainer.innerHTML = `
        <div class="alert ${isPassed ? 'alert-success' : 'alert-danger'}">
            <h5>
                <i class="bi bi-${isPassed ? 'check-circle-fill' : 'x-circle-fill'}"></i>
                Ping Test ${isPassed ? 'Passed' : 'Failed'}
            </h5>
            <p class="mb-0">
                Response: ${data.message || 'No response'} 
                (${data.duration_ms ? data.duration_ms.toFixed(2) + 'ms' : 'N/A'})
            </p>
            ${data.error ? `<p class="mb-0 mt-2"><strong>Error:</strong> ${data.error}</p>` : ''}
        </div>
    `;
}

/**
 * Display performance test result
 */
function displayPerformanceTestResult(data) {
    const resultsContainer = document.getElementById('resultsContainer');
    const isPassed = data.status === 'pass';
    
    resultsContainer.innerHTML = `
        <div class="alert ${isPassed ? 'alert-success' : 'alert-danger'}">
            <h5>
                <i class="bi bi-${isPassed ? 'check-circle-fill' : 'x-circle-fill'}"></i>
                Performance Test ${isPassed ? 'Passed' : 'Failed'}
            </h5>
            ${isPassed ? `
                <div class="row mt-3">
                    <div class="col-md-3">
                        <strong>Iterations:</strong><br>
                        ${data.iterations}
                    </div>
                    <div class="col-md-3">
                        <strong>Total Operations:</strong><br>
                        ${data.total_operations}
                    </div>
                    <div class="col-md-3">
                        <strong>Ops/Second:</strong><br>
                        ${data.ops_per_second.toFixed(2)}
                    </div>
                    <div class="col-md-3">
                        <strong>Avg Latency:</strong><br>
                        ${data.avg_latency_ms.toFixed(2)}ms
                    </div>
                </div>
                <div class="row mt-2">
                    <div class="col-md-4">
                        <small><strong>SET operations:</strong> ${data.operations.set}</small>
                    </div>
                    <div class="col-md-4">
                        <small><strong>GET operations:</strong> ${data.operations.get}</small>
                    </div>
                    <div class="col-md-4">
                        <small><strong>DELETE operations:</strong> ${data.operations.delete}</small>
                    </div>
                </div>
            ` : `
                <p class="mb-0 mt-2"><strong>Error:</strong> ${data.error}</p>
            `}
        </div>
    `;
}

/**
 * Format test details based on test type
 */
function formatTestDetails(testName, result) {
    if (result.error) {
        return `<span class="text-danger">Error: ${result.error}</span>`;
    }
    
    switch (testName) {
        case 'connection':
            return result.message || 'Connection test';
        case 'set':
        case 'get':
            return `Key: ${result.key || 'N/A'}, Value: ${result.value || 'N/A'}`;
        case 'delete':
            return `Key: ${result.key || 'N/A'}, Deleted: ${result.deleted || false}`;
        case 'incr':
            return `Counter value: ${result.value || 'N/A'}`;
        case 'ttl':
            return `TTL: ${result.ttl_remaining || 0}s remaining`;
        case 'performance':
            return `${result.total_operations || 0} operations, ${result.ops_per_second ? result.ops_per_second.toFixed(2) : 0} ops/sec`;
        case 'info':
            return `Redis ${result.redis_version || 'unknown'}, ${result.connected_clients || 0} clients`;
        default:
            return JSON.stringify(result);
    }
}

// Initialize tooltips if Bootstrap is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (typeof bootstrap !== 'undefined') {
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }
});
