# rapi

**rapi** is a Go package that implements [RFC 9457 (Problem Details for HTTP APIs)](https://datatracker.ietf.org/doc/html/rfc9457) with seamless integration to the `fault` error handling library.

## Features

- Full RFC 9457 compliance for HTTP API problem details
- Seamless integration with `fault` error library
- Fluent API for building responses
- Built-in HTTP status code mapping
- Predefined common response types
- Support for custom extensions
- Automatic error conversion from `fault.Error`

## Installation

```bash
go get github.com/techforge-lat/rapi
go get github.com/techforge-lat/fault
```

## Usage Examples

### Basic Success Response

```go
import "github.com/techforge-lat/rapi"

// Simple success response
response := rapi.Ok(map[string]string{"message": "Hello World"})
```

### Error Response from fault.Error

```go
import (
    "github.com/techforge-lat/rapi"
    "github.com/techforge-lat/fault"
)

// Create a fault error
err := fault.Wrap(dbErr).
    Code(fault.BadRequest).
    Message("Invalid user data").
    Title("Validation Error")

// Convert to RFC 9457 response
response := rapi.FromError(err)
```

### Custom Response Building

```go
response := rapi.New().
    Type("https://example.com/probs/user-not-found").
    Title("User Not Found").
    Detail("The requested user ID does not exist").
    Status(404).
    Instance("/users/123").
    Extension("trace_id", "abc123")
```

## Methods Overview

### Factory Methods
- `New()`: Create a new response builder
- `Ok(data)`: Create success response with data
- `Created(data)`: Create 201 Created response
- `FromError(faultErr)`: Create response from fault.Error

### Builder Methods
- `Type(uri)`: Set problem type URI
- `Title(title)`: Set problem title
- `Detail(detail)`: Set problem detail
- `Status(code)`: Set HTTP status code
- `Instance(uri)`: Set problem instance URI
- `Extension(key, value)`: Add custom extension

### Predefined Responses
- `NotFound()`: 404 Not Found response
- `BadRequest()`: 400 Bad Request response
- `Unauthorized()`: 401 Unauthorized response
- `Forbidden()`: 403 Forbidden response
- `InternalError()`: 500 Internal Server Error response

## Integration with fault

The `rapi.FromError()` function automatically extracts information from `fault.Error`:

- Maps `fault.Code` to appropriate HTTP status
- Uses `fault.Title` as problem title
- Uses `fault.Message` as problem detail
- Includes debug information in development mode

## RFC 9457 Compliance

This library fully implements RFC 9457 standard fields:

- `type`: URI identifying the problem type
- `title`: Short human-readable summary
- `detail`: Human-readable explanation
- `status`: HTTP status code
- `instance`: URI identifying the specific occurrence

Plus support for custom extensions as specified in the RFC.

## License

This project is licensed under the MIT License.
