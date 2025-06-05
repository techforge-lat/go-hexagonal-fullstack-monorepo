package middleware

import (
	"errors"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"log/slog"

	"github.com/labstack/echo/v4"
)

// ErrorHandler creates a custom error handler that integrates with the fault package
func ErrorHandler(logger *slog.Logger) echo.HTTPErrorHandler {
	return func(err error, c echo.Context) {
		var faultErr *fault.Error
		if errors.As(err, &faultErr) {
			resp := response.FromError(faultErr)
			if jsonErr := c.JSON(resp.GetStatus(), resp); jsonErr != nil {
				logger.Error("failed to send fault error response", "error", jsonErr.Error())
			}
			return
		}

		// Handle Echo HTTP errors
		if he, ok := err.(*echo.HTTPError); ok {
			message := "Internal Server Error"
			if he.Message != nil {
				message = he.Message.(string)
			}
			resp := response.New[any]().Status(he.Code).Detail(message)
			if jsonErr := c.JSON(he.Code, resp); jsonErr != nil {
				logger.Error("failed to send echo error response", "error", jsonErr.Error())
			}
			return
		}

		// Generic error
		logger.Error("unhandled error", "error", err.Error())
		resp := response.InternalError()
		if jsonErr := c.JSON(resp.GetStatus(), resp); jsonErr != nil {
			logger.Error("failed to send generic error response", "error", jsonErr.Error())
		}
	}
}

// RequestLogger creates a middleware that logs requests using structured logging
func RequestLogger(logger *slog.Logger) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			req := c.Request()
			res := c.Response()

			start := req.Context()

			err := next(c)

			logger.InfoContext(start, "http request",
				"method", req.Method,
				"path", req.URL.Path,
				"status", res.Status,
				"size", res.Size,
				"user_agent", req.UserAgent(),
				"remote_ip", c.RealIP(),
			)

			return err
		}
	}
}

