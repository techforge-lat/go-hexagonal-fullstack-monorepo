package response

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"net/http"
)

const DefaultProblemType = "about:blank"

// Response represents an RFC 9457 Problem Details response
type Response struct {
	// RFC 9457 standard fields
	TypeURI     string `json:"type"`
	TitleText   string `json:"title,omitempty"`
	DetailText  string `json:"detail,omitempty"`
	StatusCode  int    `json:"status"`
	InstanceURI string `json:"instance,omitempty"`

	// Success response field
	DataValue any `json:"data,omitempty"`

	// Extensions (any additional fields)
	Extensions map[string]any `json:"-"`
}

// New creates a new response builder with default problem type
func New() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		Extensions: make(map[string]any),
	}
}

// Type sets the problem type URI
func (r *Response) Type(uri string) *Response {
	r.TypeURI = uri
	return r
}

// Title sets the problem title
func (r *Response) Title(title string) *Response {
	r.TitleText = title
	return r
}

// Detail sets the problem detail
func (r *Response) Detail(detail string) *Response {
	r.DetailText = detail
	return r
}

// Status sets the HTTP status code
func (r *Response) Status(code int) *Response {
	r.StatusCode = code
	return r
}

// Instance sets the problem instance URI
func (r *Response) Instance(uri string) *Response {
	r.InstanceURI = uri
	return r
}

// Data sets the success response data
func (r *Response) Data(data any) *Response {
	r.DataValue = data
	return r
}

// Extension adds a custom extension field
func (r *Response) Extension(key string, value any) *Response {
	if r.Extensions == nil {
		r.Extensions = make(map[string]any)
	}
	r.Extensions[key] = value
	return r
}

// GetStatus returns the HTTP status code
func (r *Response) GetStatus() int {
	return r.StatusCode
}

// IsSuccess returns true if the response represents a successful operation
func (r *Response) IsSuccess() bool {
	return r.StatusCode >= 200 && r.StatusCode < 300
}

// IsError returns true if the response represents an error
func (r *Response) IsError() bool {
	return r.StatusCode >= 400
}

// Ok creates a successful response with data
func Ok(data any) *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		StatusCode: http.StatusOK,
		DataValue:  data,
	}
}

// Created creates a 201 Created response with data
func Created(data any) *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Resource Created",
		DetailText: "The resource was successfully created",
		StatusCode: http.StatusCreated,
		DataValue:  data,
	}
}

// FromError creates a problem details response from a fault.Error
func FromError(err *fault.Error) *Response {
	if err == nil {
		return InternalError()
	}

	response := &Response{
		TypeURI:    DefaultProblemType,
		StatusCode: err.HTTPStatus(),
		Extensions: make(map[string]any),
	}

	// Use fault title if available
	if err.HasTitle() {
		response.TitleText = err.TitleText
	} else {
		// Use default title based on status code
		if title, exists := TitleByStatus[response.StatusCode]; exists {
			response.TitleText = title
		}
	}

	// Use fault message as detail
	if err.MessageText != "" {
		response.DetailText = err.MessageText
	} else {
		// Use default detail based on status code
		if detail, exists := DetailByStatus[response.StatusCode]; exists {
			response.DetailText = detail
		}
	}

	// Add debug information as extension
	if err.Error() != "" {
		response.Extension("debug_error", err.Error())
	}

	// Add fault code as extension
	if err.CodeName != "" {
		response.Extension("error_code", err.CodeName)
	}

	return response
}

// Predefined error responses

// NotFound creates a 404 Not Found response
func NotFound() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Resource Not Found",
		DetailText: "The requested resource could not be found",
		StatusCode: http.StatusNotFound,
	}
}

// BadRequest creates a 400 Bad Request response
func BadRequest() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Bad Request",
		DetailText: "The request is invalid or malformed",
		StatusCode: http.StatusBadRequest,
	}
}

// Unauthorized creates a 401 Unauthorized response
func Unauthorized() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Unauthorized",
		DetailText: "Authentication is required to access this resource",
		StatusCode: http.StatusUnauthorized,
	}
}

// Forbidden creates a 403 Forbidden response
func Forbidden() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Forbidden",
		DetailText: "You do not have permission to access this resource",
		StatusCode: http.StatusForbidden,
	}
}

// InternalError creates a 500 Internal Server Error response
func InternalError() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Internal Server Error",
		DetailText: "An unexpected error occurred on the server",
		StatusCode: http.StatusInternalServerError,
	}
}

// UnprocessableEntity creates a 422 Unprocessable Entity response
func UnprocessableEntity() *Response {
	return &Response{
		TypeURI:    DefaultProblemType,
		TitleText:  "Validation Failed",
		DetailText: "The provided data failed validation requirements",
		StatusCode: http.StatusUnprocessableEntity,
	}
}
