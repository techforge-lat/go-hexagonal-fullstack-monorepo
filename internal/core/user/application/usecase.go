package application

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/user/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

// UseCase implements the user business logic
type UseCase struct {
	repo ports.UserRepository
}

// NewUseCase creates a new UserUseCase instance
func NewUseCase(userRepo ports.UserRepository) *UseCase {
	return &UseCase{
		repo: userRepo,
	}
}

func (uc UseCase) WithTx(tx ports.Transaction) ports.UserUseCase {
	return &UseCase{
		repo: uc.repo.WithTx(tx),
	}
}

func (uc UseCase) CreateBulk(ctx context.Context, entities types.List[entity.UserCreateRequest]) error {
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

func (uc UseCase) Create(ctx context.Context, req entity.UserCreateRequest) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err)
	}

	if err := uc.repo.Create(ctx, req); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (uc UseCase) Update(ctx context.Context, req entity.UserUpdateRequest, filters ...dafi.Filter) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err)
	}

	if err := uc.repo.Update(ctx, req); err != nil {
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

func (uc UseCase) Find(ctx context.Context, criteria dafi.Criteria) (entity.User, error) {
	result, err := uc.repo.Find(ctx, criteria)
	if err != nil {
		return entity.User{}, fault.Wrap(err)
	}

	return result, nil
}

func (uc UseCase) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.User], error) {
	result, err := uc.repo.List(ctx, criteria)
	if err != nil {
		return types.List[entity.User]{}, fault.Wrap(err)
	}

	return result, nil
}
