# fault

**fault** is a Go package for enhanced error tracing and handling. It wraps standard Go errors, providing context like error location, metadata, status codes, and detailed error information to make debugging easier.

## Motivation
From my experience working on various projects, handling errors required manually adding context, such as the package and function, which was tedious and error-prone. Fault was created to automate this process, ensuring that context is always included with each error. Additionally, the library provides a way to define user-friendly error messages, like titles and details, which can be used in the presentation layer to offer clear, helpful responses to the client.

## Features

- Add error metadata and status codes
- Track error origins with `runtime.Caller`
- Easy to wrap and chain errors
- Built-in HTTP status code mapping
- Clean, fluent API

## Installation

```bash
go get github.com/techforge-lat/fault
```

## Usage Example

```go
import "github.com/techforge-lat/fault"

err := someFunc()
trace := fault.Wrap(err).
    Code(fault.BadRequest).
    Message("Failed to connect").
    Title("Database Error")

fmt.Println(trace.Error())
```

## Methods Overview

- `Wrap(err error)`: Wraps an error with tracing.
- `Code(code Code)`: Sets the error code and HTTP status.
- `Message(msg string)`: Sets the error message.
- `Title(title string)`: Adds a title to the error.
- `From(cause error)`: Adds a cause to the error.
- `Error()`: Outputs error details and trace.

## Error Codes

Built-in error codes with HTTP status mapping:

- `BadRequest` (400)
- `Unauthorized` (401)
- `Forbidden` (403)
- `NotFound` (404)
- `UnprocessableEntity` (422)
- `InternalError` (500)
- `BindFailed` (400)

## License

This project is licensed under the MIT License.

---

Let me know if you'd like more details or changes!
