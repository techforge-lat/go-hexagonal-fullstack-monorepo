package email_credentials

import (
	"go-hexagonal-fullstack-monorepo/internal/core/email_credentials/application"
	"go-hexagonal-fullstack-monorepo/internal/core/email_credentials/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/core/email_credentials/infrastructure/repository/postgres"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"go.uber.org/fx"
)

var Module = fx.Module("email_credentials",
	fx.Provide(
		fx.Annotate(
			postgres.NewRepository,
			fx.As(new(ports.EmailCredentialsRepository)),
		),
		fx.Annotate(
			application.NewUseCase,
			fx.As(new(ports.EmailCredentialsUseCase)),
		),
		presentation.NewHandler,
	),
)