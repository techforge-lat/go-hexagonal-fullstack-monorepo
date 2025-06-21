package ports

import (
	"go-hexagonal-fullstack-monorepo/internal/core/roles/domain/entity"
)

type RoleUseCase interface {
	UseCaseTx[RoleUseCase]
	UseCaseCommand[entity.RoleCreateRequest, entity.RoleUpdateRequest]
	UseCaseQuery[entity.Role]
}

type RoleRepository interface {
	RepositoryTx[RoleRepository]
	RepositoryCommand[entity.RoleCreateRequest, entity.RoleUpdateRequest]
	RepositoryQuery[entity.Role]
}