package logger

import (
	"bytes"
	"context"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"log/slog"
	"strings"
	"testing"
)

func TestNew(t *testing.T) {
	tests := []struct {
		name   string
		config Config
	}{
		{
			name: "text format info level",
			config: Config{
				Level:     "info",
				Format:    "text",
				AddSource: false,
			},
		},
		{
			name: "json format debug level",
			config: Config{
				Level:     "debug",
				Format:    "json",
				AddSource: true,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var buf bytes.Buffer
			tt.config.Output = &buf

			logger := New(tt.config)
			if logger == nil {
				t.Fatal("expected logger to be created")
			}

			logger.Info(context.Background(), "test message", "key", "value")

			output := buf.String()
			if output == "" {
				t.Error("expected log output")
			}

			if strings.Contains(output, "test message") == false {
				t.Error("expected log message in output")
			}
		})
	}
}

func TestNewFromConfig(t *testing.T) {
	config := localconfig.LoggerConfig{
		Level:     "debug",
		Format:    "json",
		AddSource: true,
	}

	logger := NewFromConfig(config)
	if logger == nil {
		t.Fatal("expected logger to be created")
	}

	ctx := context.Background()
	if !logger.Enabled(ctx, slog.LevelDebug) {
		t.Error("expected debug level to be enabled")
	}
}

func TestDefault(t *testing.T) {
	logger := Default()
	if logger == nil {
		t.Fatal("expected default logger to be created")
	}
}

func TestLoggerMethods(t *testing.T) {
	var buf bytes.Buffer
	logger := New(Config{
		Level:  "debug",
		Format: "text",
		Output: &buf,
	})

	ctx := context.Background()

	logger.Debug(context.Background(), "debug message")
	logger.Info(context.Background(), "info message")
	logger.Warn(context.Background(), "warn message")
	logger.Error(context.Background(), "error message")

	logger.DebugContext(ctx, "debug context message")
	logger.InfoContext(ctx, "info context message")
	logger.WarnContext(ctx, "warn context message")
	logger.ErrorContext(ctx, "error context message")

	output := buf.String()
	expectedMessages := []string{
		"debug message",
		"info message",
		"warn message",
		"error message",
		"debug context message",
		"info context message",
		"warn context message",
		"error context message",
	}

	for _, msg := range expectedMessages {
		if !strings.Contains(output, msg) {
			t.Errorf("expected %q in output", msg)
		}
	}
}

func TestLoggerWith(t *testing.T) {
	var buf bytes.Buffer
	logger := New(Config{
		Level:  "info",
		Format: "text",
		Output: &buf,
	})

	childLogger := logger.With("service", "test")
	childLogger.Info(context.Background(), "test message")

	output := buf.String()
	if !strings.Contains(output, "service=test") {
		t.Error("expected service=test in output")
	}
}

func TestLoggerWithGroup(t *testing.T) {
	var buf bytes.Buffer
	logger := New(Config{
		Level:  "info",
		Format: "text",
		Output: &buf,
	})

	groupLogger := logger.WithGroup("database")
	groupLogger.Info(context.Background(), "connection established", "host", "localhost")

	output := buf.String()
	if !strings.Contains(output, "database") {
		t.Error("expected database group in output")
	}
}
