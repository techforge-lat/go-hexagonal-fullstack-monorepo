package localconfig

import "go.uber.org/fx"

var Module = fx.Module("config",
	fx.Provide(LoadConfig),
)
