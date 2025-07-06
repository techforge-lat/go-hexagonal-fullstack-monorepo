package ports

import (
	"context"

	"github.com/google/uuid"

	"api.system.soluciones-cloud.com/internal/core/users/domain/entity"
	"api.system.soluciones-cloud.com/internal/shared/dafi"
	"api.system.soluciones-cloud.com/internal/shared/types"
)

type UserRepository interface {
	RepositoryTx[UserRepository]
	RepositoryCommand[entity.User, entity.User]
	RepositoryQuery[entity.User]
}

type UserUseCase interface {
	CreateUser(ctx context.Context, req entity.CreateUserRequest) (entity.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (entity.User, error)
	ListUsers(ctx context.Context, criteria dafi.Criteria) (types.List[entity.User], error)
	UpdateUser(ctx context.Context, req entity.UpdateUserRequest) (entity.User, error)
	DeleteUser(ctx context.Context, req entity.DeleteUserRequest) error
	ExistsUser(ctx context.Context, id uuid.UUID) (bool, error)
	CountUsers(ctx context.Context, criteria dafi.Criteria) (int64, error)
}