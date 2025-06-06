package user

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/application"
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/presentation"
	"go-hexagonal-fullstack-monorepo/internal/core/user/infrastructure/repository/postgres"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"

	"github.com/techforge-lat/linkit"
)

const (
	HandlerDependency    = "user.handler"
	UseCaseDependency    = "user.usecase"
	RepositoryDependency = "user.repository"
)

func ProvideModuleDependencies(container *linkit.DependencyContainer, db ports.Database) {
	repo := postgres.NewRepository(db)
	container.Provide(RepositoryDependency, repo)

	useCase := application.NewUseCase(repo)
	container.Provide(UseCaseDependency, useCase)

	handler := presentation.NewHandler(useCase)
	container.Provide(HandlerDependency, handler)
}
