package shared

import (
	"time"

	"github.com/go-resty/resty/v2"
)

// HTTPClient wraps a configured resty HTTP client for tests
type HTTPClient struct {
	Client  *resty.Client
	BaseURL string
}

// NewHTTPClient creates a new HTTP client for integration tests
func NewHTTPClient(baseURL string) *HTTPClient {
	client := resty.New()
	
	// Configure timeouts
	client.SetTimeout(30 * time.Second)
	client.SetRetryCount(3)
	client.SetRetryWaitTime(1 * time.Second)
	client.SetRetryMaxWaitTime(5 * time.Second)
	
	// Configure base URL
	client.SetBaseURL(baseURL)
	
	// Configure headers
	client.SetHeader("Content-Type", "application/json")
	client.SetHeader("Accept", "application/json")
	
	// Configure debug mode for tests
	client.SetDebug(false) // Set to true for detailed HTTP logs
	
	return &HTTPClient{
		Client:  client,
		BaseURL: baseURL,
	}
}

// Get performs a GET request
func (c *HTTPClient) Get(url string) (*resty.Response, error) {
	return c.Client.R().Get(url)
}

// Post performs a POST request with a JSON body
func (c *HTTPClient) Post(url string, body interface{}) (*resty.Response, error) {
	return c.Client.R().SetBody(body).Post(url)
}

// Put performs a PUT request with a JSON body
func (c *HTTPClient) Put(url string, body interface{}) (*resty.Response, error) {
	return c.Client.R().SetBody(body).Put(url)
}

// Delete performs a DELETE request
func (c *HTTPClient) Delete(url string) (*resty.Response, error) {
	return c.Client.R().Delete(url)
}

// WithAuth sets authentication header for subsequent requests
func (c *HTTPClient) WithAuth(token string) *HTTPClient {
	c.Client.SetAuthToken(token)
	return c
}

// WithHeader sets a custom header for subsequent requests
func (c *HTTPClient) WithHeader(key, value string) *HTTPClient {
	c.Client.SetHeader(key, value)
	return c
}

// WithQueryParam sets a query parameter for subsequent requests
func (c *HTTPClient) WithQueryParam(key, value string) *HTTPClient {
	c.Client.SetQueryParam(key, value)
	return c
}

// WithQueryParams sets multiple query parameters for subsequent requests
func (c *HTTPClient) WithQueryParams(params map[string]string) *HTTPClient {
	c.Client.SetQueryParams(params)
	return c
}