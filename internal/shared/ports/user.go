package ports

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/domain/entity"
)

type UserUseCase interface {
	UseCaseTx[UserUseCase]
	UseCaseCommand[entity.UserCreateRequest, entity.UserUpdateRequest]
	UseCaseQuery[entity.User]
}

type UserRepository interface {
	RepositoryTx[UserRepository]
	RepositoryCommand[entity.UserCreateRequest, entity.UserUpdateRequest]
	RepositoryQuery[entity.User]
}
