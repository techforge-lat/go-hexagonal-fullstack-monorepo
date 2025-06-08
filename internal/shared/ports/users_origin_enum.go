package ports

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

type UsersOriginEnumRepository interface {
	Create(ctx context.Context, entity entity.UsersOriginEnumCreateRequest) error
	CreateBulk(ctx context.Context, entities types.List[entity.UsersOriginEnumCreateRequest]) error
	Update(ctx context.Context, entity entity.UsersOriginEnumUpdateRequest, filters ...dafi.Filter) error
	Delete(ctx context.Context, filters ...dafi.Filter) error
	HardDelete(ctx context.Context, filters ...dafi.Filter) error
	Find(ctx context.Context, criteria dafi.Criteria) (entity.UsersOriginEnum, error)
	List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.UsersOriginEnum], error)
	Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)
	Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
	WithTx(tx Transaction) UsersOriginEnumRepository
}

type UsersOriginEnumUseCase interface {
	Create(ctx context.Context, req entity.UsersOriginEnumCreateRequest) error
	Update(ctx context.Context, req entity.UsersOriginEnumUpdateRequest, filters ...dafi.Filter) error
	Delete(ctx context.Context, filters ...dafi.Filter) error
	Find(ctx context.Context, criteria dafi.Criteria) (entity.UsersOriginEnum, error)
	List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.UsersOriginEnum], error)
	Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)
	Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
}