package logger

import (
	"api.system.soluciones-cloud.com/internal/shared/localconfig"
	"api.system.soluciones-cloud.com/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("logger",
	fx.Provide(NewLogger),
)

func NewLogger(config *localconfig.Config) ports.Logger {
	return NewFromConfig(config.Logger)
}
