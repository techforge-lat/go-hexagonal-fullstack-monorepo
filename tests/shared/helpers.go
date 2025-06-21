package shared

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/go-resty/resty/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestSuite represents a complete integration test setup
type TestSuite struct {
	DB        *PostgreSQLContainer
	API       *APIContainer
	Client    *HTTPClient
	T         *testing.T
	ctx       context.Context
	cancelled context.CancelFunc
}

// NewTestSuite creates a new integration test suite
func NewTestSuite(t *testing.T) *TestSuite {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	
	return &TestSuite{
		T:         t,
		ctx:       ctx,
		cancelled: cancel,
	}
}

// Setup initializes the test environment
func (ts *TestSuite) Setup() error {
	ts.T.Log("Setting up integration test environment...")

	// 1. Start PostgreSQL container
	ts.T.Log("Starting PostgreSQL container...")
	db, err := CreatePostgreSQLContainer(ts.ctx)
	if err != nil {
		return fmt.Errorf("failed to create PostgreSQL container: %w", err)
	}
	ts.DB = db

	// 2. Run database migrations
	ts.T.Log("Running database migrations...")
	if err := RunMigrations(ts.ctx, db.GetDSN()); err != nil {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	// 3. Start API container
	ts.T.Log("Starting API container...")
	api, err := CreateAPIContainer(ts.ctx, db)
	if err != nil {
		return fmt.Errorf("failed to create API container: %w", err)
	}
	ts.API = api

	// 4. Initialize HTTP client
	ts.T.Log("Initializing HTTP client...")
	ts.Client = NewHTTPClient(api.BaseURL)

	// 5. Wait for API to be ready
	ts.T.Log("Waiting for API to be ready...")
	if err := ts.WaitForAPI(); err != nil {
		return fmt.Errorf("API failed to become ready: %w", err)
	}

	ts.T.Log("Integration test environment ready!")
	return nil
}

// Teardown cleans up the test environment
func (ts *TestSuite) Teardown() {
	ts.T.Log("Tearing down integration test environment...")
	
	if ts.API != nil {
		if err := ts.API.Close(ts.ctx); err != nil {
			ts.T.Errorf("Failed to close API container: %v", err)
		}
	}
	
	if ts.DB != nil {
		if err := ts.DB.Close(ts.ctx); err != nil {
			ts.T.Errorf("Failed to close PostgreSQL container: %v", err)
		}
	}
	
	if ts.cancelled != nil {
		ts.cancelled()
	}
	
	ts.T.Log("Integration test environment cleaned up!")
}

// WaitForAPI waits for the API to become ready
func (ts *TestSuite) WaitForAPI() error {
	maxAttempts := 30
	for i := 0; i < maxAttempts; i++ {
		resp, err := ts.Client.Get("/health")
		if err == nil && resp.StatusCode() == 200 {
			return nil
		}
		
		ts.T.Logf("API not ready yet (attempt %d/%d), retrying in 2 seconds...", i+1, maxAttempts)
		time.Sleep(2 * time.Second)
	}
	
	return fmt.Errorf("API failed to become ready after %d attempts", maxAttempts)
}

// AssertJSONResponse validates a JSON response structure
func (ts *TestSuite) AssertJSONResponse(resp *resty.Response, expectedStatus int, expectedKeys ...string) {
	require.Equal(ts.T, expectedStatus, resp.StatusCode(), "Unexpected status code")
	
	var jsonBody map[string]interface{}
	err := json.Unmarshal(resp.Body(), &jsonBody)
	require.NoError(ts.T, err, "Failed to parse JSON response")
	
	for _, key := range expectedKeys {
		assert.Contains(ts.T, jsonBody, key, "Missing expected key in JSON response: %s", key)
	}
}

// AssertHealthyResponse validates a health check response
func (ts *TestSuite) AssertHealthyResponse(resp *resty.Response) {
	ts.AssertJSONResponse(resp, 200, "status", "time")
	
	var jsonBody map[string]interface{}
	json.Unmarshal(resp.Body(), &jsonBody)
	
	status, ok := jsonBody["status"].(string)
	require.True(ts.T, ok, "Status field should be a string")
	assert.Equal(ts.T, "healthy", status, "Status should be 'healthy'")
	
	_, ok = jsonBody["time"].(string)
	require.True(ts.T, ok, "Time field should be a string")
}

// AssertUnhealthyResponse validates an unhealthy response
func (ts *TestSuite) AssertUnhealthyResponse(resp *resty.Response) {
	ts.AssertJSONResponse(resp, 503, "status", "error", "time")
	
	var jsonBody map[string]interface{}
	json.Unmarshal(resp.Body(), &jsonBody)
	
	status, ok := jsonBody["status"].(string)
	require.True(ts.T, ok, "Status field should be a string")
	assert.Equal(ts.T, "unhealthy", status, "Status should be 'unhealthy'")
}

// CreateTestRecord creates a test record and returns its ID for cleanup
func (ts *TestSuite) CreateTestRecord(endpoint string, requestData interface{}) string {
	resp, err := ts.Client.Post(endpoint, requestData)
	require.NoError(ts.T, err, "Failed to create test record")
	require.Equal(ts.T, 201, resp.StatusCode(), "Failed to create test record")
	
	var response map[string]interface{}
	err = json.Unmarshal(resp.Body(), &response)
	require.NoError(ts.T, err, "Failed to parse create response")
	
	data, ok := response["data"].(map[string]interface{})
	require.True(ts.T, ok, "Response should contain data field")
	
	id, ok := data["id"].(string)
	require.True(ts.T, ok, "Response data should contain id field")
	
	return id
}

// CleanupTestRecord deletes a test record by ID
func (ts *TestSuite) CleanupTestRecord(endpoint string, id string) {
	resp, err := ts.Client.Delete(fmt.Sprintf("%s/%s", endpoint, id))
	if err != nil {
		ts.T.Logf("Warning: Failed to cleanup test record %s: %v", id, err)
		return
	}
	
	if resp.StatusCode() != 204 && resp.StatusCode() != 404 {
		ts.T.Logf("Warning: Unexpected status code when cleaning up test record %s: %d", id, resp.StatusCode())
	}
}

// LogResponse logs the response details for debugging
func (ts *TestSuite) LogResponse(resp *resty.Response) {
	ts.T.Logf("Response Status: %d", resp.StatusCode())
	ts.T.Logf("Response Headers: %v", resp.Header())
	ts.T.Logf("Response Body: %s", string(resp.Body()))
}