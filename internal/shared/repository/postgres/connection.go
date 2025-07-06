package postgres

import (
	"context"
	"fmt"
	"api.system.soluciones-cloud.com/internal/shared/fault"
	"api.system.soluciones-cloud.com/internal/shared/localconfig"

	"github.com/exaring/otelpgx"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Adapter struct {
	*pgxpool.Pool
}

func New(configDB localconfig.DatabaseConfig) (*Adapter, error) {
	connectionString := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
		configDB.User,
		configDB.Password,
		configDB.Host,
		configDB.Port,
		configDB.DBName,
		configDB.SSLMode,
	)

	config, err := pgxpool.ParseConfig(connectionString)
	if err != nil {
		return nil, fault.Wrap(fmt.Errorf("unable to parse config connection: %w", err))
	}

	config.ConnConfig.Tracer = otelpgx.NewTracer(otelpgx.WithIncludeQueryParameters())

	dbPool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, fault.Wrap(fmt.Errorf("unable to create connection pool: %w", err))
	}

	if err := dbPool.Ping(context.Background()); err != nil {
		return nil, fault.Wrap(fmt.Errorf("unable to ping database: %w", err))
	}

	return &Adapter{dbPool}, nil
}
