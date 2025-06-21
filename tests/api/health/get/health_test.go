//go:build integration

package get

import (
	"testing"

	"go-hexagonal-fullstack-monorepo/tests/shared"

	"github.com/stretchr/testify/suite"
)

// HealthTestSuite defines the health endpoint test suite
type HealthTestSuite struct {
	suite.Suite
	testSuite *shared.TestSuite
}

// SetupSuite runs before all tests in the suite
func (s *HealthTestSuite) SetupSuite() {
	s.testSuite = shared.NewTestSuite(s.T())
	err := s.testSuite.Setup()
	s.Require().NoError(err, "Failed to setup test environment")
}

// TearDownSuite runs after all tests in the suite
func (s *HealthTestSuite) TearDownSuite() {
	if s.testSuite != nil {
		s.testSuite.Teardown()
	}
}

// TestHealthEndpoint_WhenDatabaseIsHealthy_ShouldReturnHealthyStatus tests the health endpoint with a healthy database
func (s *HealthTestSuite) TestHealthEndpoint_WhenDatabaseIsHealthy_ShouldReturnHealthyStatus() {
	// Given: A running API with a healthy database
	s.T().Log("Testing health endpoint with healthy database")

	// When: We call the health endpoint
	resp, err := s.testSuite.Client.Get("/health")

	// Then: We should get a healthy response
	s.Require().NoError(err, "Health request should not fail")
	s.testSuite.AssertHealthyResponse(resp)
	
	// Log response for debugging
	s.testSuite.LogResponse(resp)
}

// TestHealthEndpoint_ResponseFormat tests the health endpoint response format
func (s *HealthTestSuite) TestHealthEndpoint_ResponseFormat() {
	// Given: A running API
	s.T().Log("Testing health endpoint response format")

	// When: We call the health endpoint
	resp, err := s.testSuite.Client.Get("/health")

	// Then: We should get the correct response format
	s.Require().NoError(err, "Health request should not fail")
	s.Equal(200, resp.StatusCode(), "Should return 200 OK")
	s.Contains(resp.Header().Get("Content-Type"), "application/json", "Should return JSON content type")
	
	// Validate JSON structure
	s.testSuite.AssertJSONResponse(resp, 200, "status", "time")
}

// TestHealthEndpoint_MultipleRequests tests multiple consecutive health check requests
func (s *HealthTestSuite) TestHealthEndpoint_MultipleRequests() {
	s.T().Log("Testing multiple consecutive health check requests")

	// Perform multiple health checks
	for i := 0; i < 5; i++ {
		s.T().Logf("Health check request %d/5", i+1)
		
		resp, err := s.testSuite.Client.Get("/health")
		s.Require().NoError(err, "Health request %d should not fail", i+1)
		s.testSuite.AssertHealthyResponse(resp)
	}
}

// TestHealthEndpoint_ConcurrentRequests tests concurrent health check requests
func (s *HealthTestSuite) TestHealthEndpoint_ConcurrentRequests() {
	s.T().Log("Testing concurrent health check requests")

	// Channel to collect results
	results := make(chan error, 10)

	// Perform concurrent health checks
	for i := 0; i < 10; i++ {
		go func(requestID int) {
			resp, err := s.testSuite.Client.Get("/health")
			if err != nil {
				results <- err
				return
			}
			
			if resp.StatusCode() != 200 {
				results <- err
				return
			}
			
			results <- nil
		}(i)
	}

	// Collect all results
	for i := 0; i < 10; i++ {
		err := <-results
		s.NoError(err, "Concurrent health request %d should not fail", i+1)
	}
}

// TestHealthEndpoint_WithQueryParameters tests health endpoint with query parameters (should be ignored)
func (s *HealthTestSuite) TestHealthEndpoint_WithQueryParameters() {
	s.T().Log("Testing health endpoint with query parameters")

	// When: We call the health endpoint with query parameters
	client := s.testSuite.Client.WithQueryParams(map[string]string{
		"test":  "value",
		"extra": "parameter",
	})
	
	resp, err := client.Get("/health")

	// Then: Query parameters should be ignored and response should be healthy
	s.Require().NoError(err, "Health request with query params should not fail")
	s.testSuite.AssertHealthyResponse(resp)
}

// TestHealthEndpoint_WithCustomHeaders tests health endpoint with custom headers
func (s *HealthTestSuite) TestHealthEndpoint_WithCustomHeaders() {
	s.T().Log("Testing health endpoint with custom headers")

	// When: We call the health endpoint with custom headers
	client := s.testSuite.Client.WithHeader("X-Test-Header", "test-value")
	
	resp, err := client.Get("/health")

	// Then: Custom headers should be ignored and response should be healthy
	s.Require().NoError(err, "Health request with custom headers should not fail")
	s.testSuite.AssertHealthyResponse(resp)
}

// TestSuite runs the health endpoint test suite
func TestSuite(t *testing.T) {
	suite.Run(t, new(HealthTestSuite))
}