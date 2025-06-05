package logger

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"io"
	"log/slog"
	"os"
)

type Logger struct {
	*slog.Logger
}

type Config struct {
	Level     string
	Format    string
	AddSource bool
	Output    io.Writer
}

func New(config Config) *Logger {
	var level slog.Level
	switch config.Level {
	case "debug":
		level = slog.LevelDebug
	case "info":
		level = slog.LevelInfo
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	default:
		level = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{
		Level:     level,
		AddSource: config.AddSource,
	}

	output := config.Output
	if output == nil {
		output = os.Stdout
	}

	var handler slog.Handler
	switch config.Format {
	case "json":
		handler = slog.NewJSONHandler(output, opts)
	default:
		handler = slog.NewTextHandler(output, opts)
	}

	return &Logger{
		Logger: slog.New(handler),
	}
}

func Default() *Logger {
	return &Logger{
		Logger: slog.Default(),
	}
}

func NewFromConfig(config localconfig.LoggerConfig) *Logger {
	return New(Config{
		Level:     config.Level,
		Format:    config.Format,
		AddSource: config.AddSource,
	})
}

func (l *Logger) With(args ...any) *Logger {
	return &Logger{
		Logger: l.Logger.With(args...),
	}
}

func (l *Logger) WithGroup(name string) *Logger {
	return &Logger{
		Logger: l.Logger.WithGroup(name),
	}
}

func (l *Logger) Debug(msg string, args ...any) {
	l.Logger.Debug(msg, args...)
}

func (l *Logger) DebugContext(ctx context.Context, msg string, args ...any) {
	l.Logger.DebugContext(ctx, msg, args...)
}

func (l *Logger) Info(msg string, args ...any) {
	l.Logger.Info(msg, args...)
}

func (l *Logger) InfoContext(ctx context.Context, msg string, args ...any) {
	l.Logger.InfoContext(ctx, msg, args...)
}

func (l *Logger) Warn(msg string, args ...any) {
	l.Logger.Warn(msg, args...)
}

func (l *Logger) WarnContext(ctx context.Context, msg string, args ...any) {
	l.Logger.WarnContext(ctx, msg, args...)
}

func (l *Logger) Error(msg string, args ...any) {
	l.Logger.Error(msg, args...)
}

func (l *Logger) ErrorContext(ctx context.Context, msg string, args ...any) {
	l.Logger.ErrorContext(ctx, msg, args...)
}

func (l *Logger) Log(ctx context.Context, level slog.Level, msg string, args ...any) {
	l.Logger.Log(ctx, level, msg, args...)
}

func (l *Logger) LogAttrs(ctx context.Context, level slog.Level, msg string, attrs ...slog.Attr) {
	l.Logger.LogAttrs(ctx, level, msg, attrs...)
}

func (l *Logger) Enabled(ctx context.Context, level slog.Level) bool {
	return l.Logger.Enabled(ctx, level)
}
