package response

import (
	"errors"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"net/http"

	"github.com/jackc/pgx/v5"
)

const DefaultProblemType = "about:blank"

// Response represents an RFC 9457 Problem Details response with typed data
type Response[T any] struct {
	// RFC 9457 standard fields
	TypeURI     string `json:"type"`
	TitleText   string `json:"title,omitempty"`
	DetailText  string `json:"detail,omitempty"`
	StatusCode  int    `json:"status"`
	InstanceURI string `json:"instance,omitempty"`

	// Success response field with type safety
	DataValue T `json:"data,omitempty"`

	// Extensions (any additional fields)
	Extensions map[string]any `json:"-"`
}

// New creates a new response builder with default problem type
func New[T any]() *Response[T] {
	return &Response[T]{
		TypeURI:    DefaultProblemType,
		Extensions: make(map[string]any),
	}
}

// Type sets the problem type URI
func (r *Response[T]) Type(uri string) *Response[T] {
	r.TypeURI = uri
	return r
}

// Title sets the problem title
func (r *Response[T]) Title(title string) *Response[T] {
	r.TitleText = title
	return r
}

// Detail sets the problem detail
func (r *Response[T]) Detail(detail string) *Response[T] {
	r.DetailText = detail
	return r
}

// Status sets the HTTP status code
func (r *Response[T]) Status(code int) *Response[T] {
	r.StatusCode = code
	return r
}

// Instance sets the problem instance URI
func (r *Response[T]) Instance(uri string) *Response[T] {
	r.InstanceURI = uri
	return r
}

// Data sets the success response data
func (r *Response[T]) Data(data T) *Response[T] {
	r.DataValue = data
	return r
}

// Extension adds a custom extension field
func (r *Response[T]) Extension(key string, value any) *Response[T] {
	if r.Extensions == nil {
		r.Extensions = make(map[string]any)
	}
	r.Extensions[key] = value
	return r
}

// GetStatus returns the HTTP status code
func (r *Response[T]) GetStatus() int {
	return r.StatusCode
}

// IsSuccess returns true if the response represents a successful operation
func (r *Response[T]) IsSuccess() bool {
	return r.StatusCode >= 200 && r.StatusCode < 300
}

// IsError returns true if the response represents an error
func (r *Response[T]) IsError() bool {
	return r.StatusCode >= 400
}

// Ok creates a successful response with data
func Ok[T any](data T) *Response[T] {
	return &Response[T]{
		TypeURI:    DefaultProblemType,
		StatusCode: http.StatusOK,
		DataValue:  data,
	}
}

// Created creates a 201 Created response with data
func Created[T any](data T) *Response[T] {
	return &Response[T]{
		TypeURI:    DefaultProblemType,
		TitleText:  "Recurso Creado",
		DetailText: "El recurso fue creado exitosamente",
		StatusCode: http.StatusCreated,
		DataValue:  data,
	}
}

// FromError creates a problem details response from a fault.Error
func FromError(err *fault.Error) *Response[any] {
	if err == nil {
		return InternalError()
	}

	if errors.Is(err.Cause, pgx.ErrNoRows) {
		return NotFound()
	}

	response := &Response[any]{
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
func NotFound() *Response[any] {
	return &Response[any]{
		TypeURI:    DefaultProblemType,
		TitleText:  "Recurso No Encontrado",
		DetailText: "El recurso solicitado no pudo ser encontrado",
		StatusCode: http.StatusNotFound,
	}
}

// BadRequest creates a 400 Bad Request response
func BadRequest() *Response[any] {
	return &Response[any]{
		TypeURI:    DefaultProblemType,
		TitleText:  "Solicitud Incorrecta",
		DetailText: "La solicitud es inválida o está mal formada",
		StatusCode: http.StatusBadRequest,
	}
}

// Unauthorized creates a 401 Unauthorized response
func Unauthorized() *Response[any] {
	return &Response[any]{
		TypeURI:    DefaultProblemType,
		TitleText:  "No Autorizado",
		DetailText: "Se requiere autenticación para acceder a este recurso",
		StatusCode: http.StatusUnauthorized,
	}
}

// Forbidden creates a 403 Forbidden response
func Forbidden() *Response[any] {
	return &Response[any]{
		TypeURI:    DefaultProblemType,
		TitleText:  "Prohibido",
		DetailText: "No tienes permisos para acceder a este recurso",
		StatusCode: http.StatusForbidden,
	}
}

// InternalError creates a 500 Internal Server Error response
func InternalError() *Response[any] {
	return &Response[any]{
		TypeURI:    DefaultProblemType,
		TitleText:  "Error Interno del Servidor",
		DetailText: "Ocurrió un error inesperado en el servidor",
		StatusCode: http.StatusInternalServerError,
	}
}

// UnprocessableEntity creates a 422 Unprocessable Entity response
func UnprocessableEntity() *Response[any] {
	return &Response[any]{
		TypeURI:    DefaultProblemType,
		TitleText:  "Validación Fallida",
		DetailText: "Los datos proporcionados no cumplen con los requisitos de validación",
		StatusCode: http.StatusUnprocessableEntity,
	}
}
