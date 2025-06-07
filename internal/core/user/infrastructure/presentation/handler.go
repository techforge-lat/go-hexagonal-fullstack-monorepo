package presentation

import (
	"go-hexagonal-fullstack-monorepo/internal/core/user/domain/entity"
	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"
	"go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
	"go-hexagonal-fullstack-monorepo/internal/shared/ports"
	"net/http"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	useCase    ports.UserUseCase
	unitOfWork ports.UnitOfWork
	logger     ports.Logger
}

func NewHandler(
	useCase ports.UserUseCase,
	unitOfWork ports.UnitOfWork,
	logger ports.Logger,
) *Handler {
	return &Handler{
		useCase:    useCase,
		unitOfWork: unitOfWork,
		logger:     logger,
	}
}

func (h Handler) Create(c echo.Context) error {
	req := entity.UserCreateRequest{}
	if err := c.Bind(&req); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	if err := h.useCase.Create(c.Request().Context(), req); err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusCreated, response.Created(req))
}

func (h Handler) Update(c echo.Context) error {
	req := entity.UserUpdateRequest{}
	if err := c.Bind(&req); err != nil {
		return fault.Wrap(err).Code(fault.UnprocessableEntity)
	}

	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	if err := h.useCase.Update(c.Request().Context(), req, criteria.Filters...); err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(req))
}

func (h Handler) Delete(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	if err := h.useCase.Delete(c.Request().Context(), criteria.Filters...); err != nil {
		return fault.Wrap(err)
	}

	return c.NoContent(http.StatusNoContent)
}

func (h Handler) Find(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	result, err := h.useCase.Find(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(result))
}

func (h Handler) List(c echo.Context) error {
	criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
	if err != nil {
		return fault.Wrap(err)
	}

	result, err := h.useCase.List(c.Request().Context(), criteria)
	if err != nil {
		return fault.Wrap(err)
	}

	return c.JSON(http.StatusOK, response.Ok(result))
}
