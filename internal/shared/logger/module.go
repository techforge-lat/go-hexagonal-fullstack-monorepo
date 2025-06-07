package logger

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/localconfig"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("logger",
	fx.Provide(NewLogger),
)

func NewLogger(config *localconfig.Config) ports.Logger {
	return NewFromConfig(config.Logger)
}
