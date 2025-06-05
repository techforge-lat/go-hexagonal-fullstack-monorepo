package response

import "time"

// HealthResponse represents the health check response data
type HealthResponse struct {
	Status      string    `json:"status" example:"healthy"`
	ServiceName string    `json:"serviceName" example:"api"`
	ServerTime  time.Time `json:"serverTime" example:"2023-01-01T00:00:00Z"`
}

// ErrorResponse represents error response extensions
type ErrorResponse struct {
	ServiceName string    `json:"serviceName,omitempty" example:"api"`
	ServerTime  time.Time `json:"serverTime,omitempty" example:"2023-01-01T00:00:00Z"`
}
