package ports

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/email_credentials/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

type EmailCredentialsRepository interface {
	Create(ctx context.Context, entity entity.EmailCredentialsCreateRequest) error
	CreateBulk(ctx context.Context, entities types.List[entity.EmailCredentialsCreateRequest]) error
	Update(ctx context.Context, entity entity.EmailCredentialsUpdateRequest, filters ...dafi.Filter) error
	Delete(ctx context.Context, filters ...dafi.Filter) error
	HardDelete(ctx context.Context, filters ...dafi.Filter) error
	Find(ctx context.Context, criteria dafi.Criteria) (entity.EmailCredentials, error)
	List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.EmailCredentials], error)
	Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)
	Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
	WithTx(tx Transaction) EmailCredentialsRepository
}

type EmailCredentialsUseCase interface {
	Create(ctx context.Context, req entity.EmailCredentialsCreateRequest) error
	Update(ctx context.Context, req entity.EmailCredentialsUpdateRequest, filters ...dafi.Filter) error
	Delete(ctx context.Context, filters ...dafi.Filter) error
	Find(ctx context.Context, criteria dafi.Criteria) (entity.EmailCredentials, error)
	List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.EmailCredentials], error)
	Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)
	Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
}