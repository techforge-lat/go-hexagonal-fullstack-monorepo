package application

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/roles/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

// UseCase implements the role business logic
type UseCase struct {
	repo ports.RoleRepository
}

// NewUseCase creates a new RoleUseCase instance
func NewUseCase(roleRepo ports.RoleRepository) *UseCase {
	return &UseCase{
		repo: roleRepo,
	}
}

func (uc UseCase) WithTx(tx ports.Transaction) ports.RoleUseCase {
	return &UseCase{
		repo: uc.repo.WithTx(tx),
	}
}

func (uc UseCase) CreateBulk(ctx context.Context, entities types.List[entity.RoleCreateRequest]) error {
	if entities.IsEmpty() {
		return nil
	}

	for _, entity := range entities {
		if err := entity.Validate(); err != nil {
			return fault.Wrap(err)
		}
	}

	if err := uc.repo.CreateBulk(ctx, entities); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (uc UseCase) Create(ctx context.Context, req entity.RoleCreateRequest) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err)
	}

	if err := uc.repo.Create(ctx, req); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (uc UseCase) Update(ctx context.Context, req entity.RoleUpdateRequest, filters ...dafi.Filter) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err)
	}

	if err := uc.repo.Update(ctx, req, filters...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (uc UseCase) Delete(ctx context.Context, filters ...dafi.Filter) error {
	if err := uc.repo.Delete(ctx, filters...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (uc UseCase) Find(ctx context.Context, criteria dafi.Criteria) (entity.Role, error) {
	result, err := uc.repo.Find(ctx, criteria)
	if err != nil {
		return entity.Role{}, fault.Wrap(err)
	}

	return result, nil
}

func (uc UseCase) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.Role], error) {
	result, err := uc.repo.List(ctx, criteria)
	if err != nil {
		return types.List[entity.Role]{}, fault.Wrap(err)
	}

	return result, nil
}

func (uc UseCase) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
	result, err := uc.repo.Exists(ctx, criteria)
	if err != nil {
		return false, fault.Wrap(err)
	}

	return result, nil
}

func (uc UseCase) Count(ctx context.Context, criteria dafi.Criteria) (int64, error) {
	result, err := uc.repo.Count(ctx, criteria)
	if err != nil {
		return 0, fault.Wrap(err)
	}

	return result, nil
}