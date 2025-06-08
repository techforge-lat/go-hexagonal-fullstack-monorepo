package application

import (
	"context"
	"go-hexagonal-fullstack-monorepo/internal/core/users_origin_enum/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"go-hexagonal-fullstack-monorepo/internal/shared/types"
)

type UseCase struct {
	repo ports.UsersOriginEnumRepository
}

func NewUseCase(repo ports.UsersOriginEnumRepository) *UseCase {
	return &UseCase{repo: repo}
}

func (u UseCase) Create(ctx context.Context, req entity.UsersOriginEnumCreateRequest) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	if err := u.repo.Create(ctx, req); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (u UseCase) Update(ctx context.Context, req entity.UsersOriginEnumUpdateRequest, filters ...dafi.Filter) error {
	if err := req.Validate(); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	if err := u.repo.Update(ctx, req, filters...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (u UseCase) Delete(ctx context.Context, filters ...dafi.Filter) error {
	if err := u.repo.Delete(ctx, filters...); err != nil {
		return fault.Wrap(err)
	}

	return nil
}

func (u UseCase) Find(ctx context.Context, criteria dafi.Criteria) (entity.UsersOriginEnum, error) {
	result, err := u.repo.Find(ctx, criteria)
	if err != nil {
		return entity.UsersOriginEnum{}, fault.Wrap(err)
	}

	return result, nil
}

func (u UseCase) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.UsersOriginEnum], error) {
	result, err := u.repo.List(ctx, criteria)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	return result, nil
}

func (u UseCase) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
	exists, err := u.repo.Exists(ctx, criteria)
	if err != nil {
		return false, fault.Wrap(err)
	}

	return exists, nil
}

func (u UseCase) Count(ctx context.Context, criteria dafi.Criteria) (int64, error) {
	count, err := u.repo.Count(ctx, criteria)
	if err != nil {
		return 0, fault.Wrap(err)
	}

	return count, nil
}