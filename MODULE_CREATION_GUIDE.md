# Module Creation Guide - AI Assistant Instructions

This document serves as an AI prompt for creating new CRUD modules following the hexagonal architecture pattern. When a user provides a database schema, you MUST strictly follow the exact table structure without adding any fields that are not explicitly present in the provided schema.

## Overview

Each module follows a consistent structure based on hexagonal architecture principles with clear separation between domain logic, application use cases, and infrastructure concerns.

## Critical Requirements for AI Implementation

**MANDATORY RULE**: When a user provides a database table schema, you MUST implement ONLY the fields that exist in that schema. DO NOT add audit fields (created_at, updated_at, deleted_at, created_by, updated_by, deleted_by) or any other fields unless they are explicitly present in the provided table structure.

**Schema Source of Truth**: The user-provided database schema is the single source of truth. Your implementation must match it exactly.

## Prerequisites

- Understand the project's hexagonal architecture (see `CLAUDE.md`)
- Familiarity with Go, Echo framework, and PostgreSQL
- Knowledge of DAFI query system and SQLCraft query builder
- Understanding of Uber Fx dependency injection

## Module Structure

Every module must follow this exact directory structure:

```
internal/core/{module_name}/
├── application/
│   └── usecase.go
├── domain/
│   └── entity/
│       ├── command.go
│       └── query.go
├── infrastructure/
│   ├── presentation/
│   │   ├── handler.go
│   │   └── ssr/
│   │       └── cms_ui/
│   │           └── {module_name}_list_page.templ
│   └── repository/
│       └── postgres/
│           ├── psql.go
│           └── query.go
└── module.go
```

## Step-by-Step Creation Process

### 1. Create Directory Structure

```bash
mkdir -p internal/core/{module_name}/application
mkdir -p internal/core/{module_name}/domain/entity
mkdir -p internal/core/{module_name}/infrastructure/presentation/ssr/cms_ui
mkdir -p internal/core/{module_name}/infrastructure/repository/postgres
```

### 2. Domain Layer (Business Entities)

#### 2.1 Create Query Entity (`domain/entity/query.go`)

**CRITICAL**: Only include fields that exist in the user-provided database schema. Do not add audit fields unless they are explicitly present in the table structure.

```go
package entity

import (
    // Import only what's needed based on the actual schema fields
    // "time" - only if timestamp fields exist in schema
    // "github.com/google/uuid" - only if UUID fields exist in schema
    // "gopkg.in/guregu/null.v4" - only if nullable fields exist in schema
)

type {ModuleName} struct {
    // Add ONLY the fields that exist in the provided database schema
    // Example for a basic table with only code and name:
    Code string `json:"code,omitzero"`
    Name string `json:"name,omitzero"`
    
    // DO NOT add these unless they exist in the schema:
    // ID        uuid.UUID     `json:"id,omitzero"`
    // CreatedAt time.Time     `json:"createdAt,omitzero"`
    // UpdatedAt null.Time     `json:"updatedAt,omitzero"`
    // DeletedAt null.Time     `json:"deletedAt,omitzero"`
}

// Only add IsDeleted/IsActive methods if DeletedAt field exists in the schema
```

#### 2.2 Create Command Entities (`domain/entity/command.go`)

**CRITICAL**: Only include fields that exist in the user-provided database schema. Do not add audit fields unless they are explicitly present in the table structure.

```go
package entity

import (
    "go-hexagonal-fullstack-monorepo/internal/shared/valid"
    // Import only what's needed based on the actual schema fields
    // "github.com/google/uuid" - only if UUID fields exist in schema
    // "gopkg.in/guregu/null.v4" - only if nullable fields exist in schema
)

var {moduleName}Schema = valid.Object(map[string]valid.Schema{
    // Add validation rules ONLY for fields that exist in the provided schema
    // Example for a basic table with only code and name:
    "code": valid.String().MinLength(1).MaxLength(50).Required(),
    "name": valid.String().MinLength(1).MaxLength(100).Required(),
    
    // DO NOT add validation for audit fields unless they exist in the schema
})

// {ModuleName}CreateRequest represents the request to create a {ModuleName}
type {ModuleName}CreateRequest struct {
    // Add ONLY the fields that exist in the provided database schema
    // Example for a basic table with only code and name:
    Code string `json:"code"`
    Name string `json:"name"`
    
    // DO NOT add these unless they exist in the schema:
    // ID        uuid.UUID     `json:"id"`
    // CreatedAt null.Time     `json:"createdAt"`
    // CreatedBy uuid.NullUUID `json:"-"`
}

// Validate validates the fields of {ModuleName}CreateRequest
func (c {ModuleName}CreateRequest) Validate() error {
    result := {moduleName}Schema.Parse(c)
    if !result.Success {
        return result.Errors[0] // Return first error for simplicity
    }
    return nil
}

// {ModuleName}UpdateRequest represents the request to update a {ModuleName}
type {ModuleName}UpdateRequest struct {
    // Use null types for optional fields in updates
    // Add ONLY the fields that exist in the provided database schema
    // Example for a basic table with only code and name:
    Code null.String `json:"code"`
    Name null.String `json:"name"`
    
    // DO NOT add these unless they exist in the schema:
    // UpdatedAt null.Time     `json:"updatedAt"`
    // UpdatedBy uuid.NullUUID `json:"-"`
}

// Validate validates the fields of {ModuleName}UpdateRequest
func (c {ModuleName}UpdateRequest) Validate() error {
    result := {moduleName}Schema.Parse(c)
    if !result.Success {
        return result.Errors[0] // Return first error for simplicity
    }
    return nil
}

// Only add DeleteRequest if soft delete fields exist in the schema
```

### 3. Application Layer (Use Cases)

#### 3.1 Create Use Case (`application/usecase.go`)

```go
package application

import (
    "context"
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/domain/entity"
    "go-hexagonal-fullstack-monorepo/internal/shared/dafi"
    "go-hexagonal-fullstack-monorepo/internal/shared/fault"
    "go-hexagonal-fullstack-monorepo/internal/shared/ports"
    "go-hexagonal-fullstack-monorepo/internal/shared/types"
)

type UseCase struct {
    repo ports.{ModuleName}Repository
}

func NewUseCase(repo ports.{ModuleName}Repository) *UseCase {
    return &UseCase{repo: repo}
}

func (u UseCase) Create(ctx context.Context, req entity.{ModuleName}CreateRequest) error {
    if err := req.Validate(); err != nil {
        return fault.Wrap(err).Code(fault.UnprocessableEntity)
    }

    if err := u.repo.Create(ctx, req); err != nil {
        return fault.Wrap(err)
    }

    return nil
}

func (u UseCase) Update(ctx context.Context, req entity.{ModuleName}UpdateRequest, filters ...dafi.Filter) error {
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

func (u UseCase) Find(ctx context.Context, criteria dafi.Criteria) (entity.{ModuleName}, error) {
    result, err := u.repo.Find(ctx, criteria)
    if err != nil {
        return entity.{ModuleName}{}, fault.Wrap(err)
    }

    return result, nil
}

func (u UseCase) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.{ModuleName}], error) {
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
```

### 4. Infrastructure Layer

#### 4.1 Database Queries (`infrastructure/repository/postgres/query.go`)

```go
package postgres

import "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"

var table = "schema.{table_name}"

var sqlColumnByDomainField = map[string]string{
    "id":        "id",
    "name":      "name",
    "status":    "status",
    "createdAt": "created_at",
    "createdBy": "created_by",
    "updatedAt": "updated_at",
    "updatedBy": "updated_by",
    "deletedAt": "deleted_at",
    "deletedBy": "deleted_by",
    // Add your field mappings here
}

var (
    insertQuery     = sqlcraft.InsertInto(table).WithColumns("id", "name", "status", "created_at", "created_by")
    updateQuery     = sqlcraft.Update(table).WithColumns("name", "status", "updated_at", "updated_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
    softDeleteQuery = sqlcraft.Update(table).WithColumns("deleted_at", "deleted_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
    deleteQuery     = sqlcraft.DeleteFrom(table).SQLColumnByDomainField(sqlColumnByDomainField)
    existsQuery     = sqlcraft.Select("1").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
    countQuery      = sqlcraft.Select("COUNT(*)").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
)

var selectAllColumns = []string{"id", "name", "status", "created_at", "created_by", "updated_at", "updated_by", "deleted_at", "deleted_by"}
```

#### 4.2 Repository Implementation (`infrastructure/repository/postgres/psql.go`)

```go
package postgres

import (
    "context"
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/domain/entity"
    "go-hexagonal-fullstack-monorepo/internal/shared/dafi"
    "go-hexagonal-fullstack-monorepo/internal/shared/fault"
    "go-hexagonal-fullstack-monorepo/internal/shared/ports"
    "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"
    "go-hexagonal-fullstack-monorepo/internal/shared/types"
    "time"

    "github.com/georgysavva/scany/v2/pgxscan"
    "github.com/google/uuid"
    "gopkg.in/guregu/null.v4"
)

type Repository struct {
    db ports.Database
    tx ports.Tx
}

func NewRepository(db ports.Database) *Repository {
    return &Repository{db: db}
}

// WithTx returns a new instance of the repository with the transaction set
func (r Repository) WithTx(tx ports.Transaction) ports.{ModuleName}Repository {
    return &Repository{
        db: r.db,
        tx: tx.GetTx(),
    }
}

func (r Repository) CreateBulk(ctx context.Context, entities types.List[entity.{ModuleName}CreateRequest]) error {
    query := insertQuery
    for _, entity := range entities {
        if entity.ID == uuid.Nil || entity.ID.String() == "" {
            entity.ID = uuid.New()
        }
        if !entity.CreatedAt.Valid {
            entity.CreatedAt.SetValid(time.Now())
        }

        query = query.WithValues(entity.ID, entity.Name, entity.Status, entity.CreatedAt, entity.CreatedBy)
    }

    result, err := query.ToSQL()
    if err != nil {
        return fault.Wrap(err)
    }

    if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
        return fault.Wrap(err)
    }

    return nil
}

func (r Repository) Create(ctx context.Context, entity entity.{ModuleName}CreateRequest) error {
    if entity.ID == uuid.Nil || entity.ID.String() == "" {
        entity.ID = uuid.New()
    }
    if !entity.CreatedAt.Valid {
        entity.CreatedAt.SetValid(time.Now())
    }

    if !entity.CreatedBy.Valid {
        // CreatedBy should be set by the application layer
    }

    result, err := insertQuery.WithValues(entity.ID, entity.Name, entity.Status, entity.CreatedAt, entity.CreatedBy).ToSQL()
    if err != nil {
        return fault.Wrap(err)
    }

    if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
        return fault.Wrap(err)
    }

    return nil
}

func (r Repository) Update(ctx context.Context, entity entity.{ModuleName}UpdateRequest, filters ...dafi.Filter) error {
    if !entity.UpdatedAt.Valid {
        entity.UpdatedAt.SetValid(time.Now())
    }

    if !entity.UpdatedBy.Valid {
        // UpdatedBy should be set by the application layer
    }

    result, err := updateQuery.WithValues(entity.Name, entity.Status, entity.UpdatedAt, entity.UpdatedBy).Where(filters...).ToSQL()
    if err != nil {
        return fault.Wrap(err)
    }

    if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
        return fault.Wrap(err)
    }

    return nil
}

func (r Repository) Delete(ctx context.Context, filters ...dafi.Filter) error {
    // Perform soft delete by setting deleted_at timestamp
    softDeleteReq := entity.{ModuleName}DeleteRequest{
        DeletedAt: null.TimeFrom(time.Now()),
        // DeletedBy would be set by the application layer based on current user context
    }

    result, err := softDeleteQuery.WithValues(softDeleteReq.DeletedAt, softDeleteReq.DeletedBy).Where(filters...).ToSQL()
    if err != nil {
        return fault.Wrap(err)
    }

    if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
        return fault.Wrap(err)
    }

    return nil
}

// HardDelete permanently removes records from the database
// This should only be used in specific cases like data cleanup or GDPR compliance
func (r Repository) HardDelete(ctx context.Context, filters ...dafi.Filter) error {
    result, err := deleteQuery.Where(filters...).ToSQL()
    if err != nil {
        return fault.Wrap(err)
    }

    if _, err := r.conn().Exec(ctx, result.Sql, result.Args...); err != nil {
        return fault.Wrap(err)
    }

    return nil
}

func (r Repository) Find(ctx context.Context, criteria dafi.Criteria) (entity.{ModuleName}, error) {
    if err := dafi.ValidateSelectFields(criteria.SelectColumns, sqlColumnByDomainField); err != nil {
        return entity.{ModuleName}{}, fault.Wrap(err).Code(fault.BadRequest)
    }

    filters := append(criteria.Filters, dafi.Filter{
        Field:    "deletedAt",
        Operator: dafi.IsNull,
        Value:    nil,
    })

    query := sqlcraft.Select(selectAllColumns...).From(table).SQLColumnByDomainField(sqlColumnByDomainField)
    result, err := query.
        Where(filters...).
        OrderBy(criteria.Sorts...).
        Limit(1).RequiredColumns(criteria.SelectColumns...).
        ToSQL()
    if err != nil {
        return entity.{ModuleName}{}, fault.Wrap(err)
    }

    var m entity.{ModuleName}
    if err := pgxscan.Get(ctx, r.conn(), &m, result.Sql, result.Args...); err != nil {
        return entity.{ModuleName}{}, fault.Wrap(err)
    }

    return m, nil
}

func (r Repository) List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.{ModuleName}], error) {
    if err := dafi.ValidateSelectFields(criteria.SelectColumns, sqlColumnByDomainField); err != nil {
        return nil, fault.Wrap(err).Code(fault.BadRequest)
    }

    filters := append(criteria.Filters, dafi.Filter{
        Field:    "deletedAt",
        Operator: dafi.IsNull,
        Value:    nil,
    })

    query := sqlcraft.Select(selectAllColumns...).From(table).SQLColumnByDomainField(sqlColumnByDomainField)
    result, err := query.
        Where(filters...).
        OrderBy(criteria.Sorts...).
        Limit(criteria.Pagination.PageSize).
        Page(criteria.Pagination.PageNumber).
        RequiredColumns(criteria.SelectColumns...).
        ToSQL()
    if err != nil {
        return nil, fault.Wrap(err)
    }

    var list types.List[entity.{ModuleName}]
    if err := pgxscan.Select(ctx, r.conn(), &list, result.Sql, result.Args...); err != nil {
        return nil, fault.Wrap(err)
    }

    return list, nil
}

func (r Repository) Exists(ctx context.Context, criteria dafi.Criteria) (bool, error) {
    filters := append(criteria.Filters, dafi.Filter{
        Field:    "deletedAt",
        Operator: dafi.IsNull,
        Value:    nil,
    })

    result, err := existsQuery.
        Where(filters...).
        Limit(1).
        ToSQL()
    if err != nil {
        return false, fault.Wrap(err)
    }

    var exists int
    row := r.conn().QueryRow(ctx, result.Sql, result.Args...)

    if err := row.Scan(&exists); err != nil {
        // If no rows found, EXISTS returns false
        if err.Error() == "no rows in result set" {
            return false, nil
        }
        return false, fault.Wrap(err)
    }

    return exists > 0, nil
}

func (r Repository) Count(ctx context.Context, criteria dafi.Criteria) (int64, error) {
    filters := append(criteria.Filters, dafi.Filter{
        Field:    "deletedAt",
        Operator: dafi.IsNull,
        Value:    nil,
    })

    result, err := countQuery.
        Where(filters...).
        ToSQL()
    if err != nil {
        return 0, fault.Wrap(err)
    }

    var count int64
    row := r.conn().QueryRow(ctx, result.Sql, result.Args...)

    if err := row.Scan(&count); err != nil {
        return 0, fault.Wrap(err)
    }

    return count, nil
}

// conn returns the database connection to use
// if there is a transaction, it returns the transaction connection
func (r Repository) conn() ports.DatabaseExecutor {
    if r.tx != nil {
        return r.tx
    }

    return r.db
}
```

#### 4.3 HTTP Handlers (`infrastructure/presentation/handler.go`)

```go
package presentation

import (
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/domain/entity"
    "go-hexagonal-fullstack-monorepo/internal/shared/dafi"
    "go-hexagonal-fullstack-monorepo/internal/shared/fault"
    "go-hexagonal-fullstack-monorepo/internal/shared/http/server/request"
    "go-hexagonal-fullstack-monorepo/internal/shared/http/server/response"
    "go-hexagonal-fullstack-monorepo/internal/shared/ports"
    "net/http"

    "github.com/labstack/echo/v4"
)

type Handler struct {
    useCase ports.{ModuleName}UseCase
}

func NewHandler(useCase ports.{ModuleName}UseCase) *Handler {
    return &Handler{useCase: useCase}
}

func (h Handler) Create(c echo.Context) error {
    var req entity.{ModuleName}CreateRequest
    if err := c.Bind(&req); err != nil {
        return fault.Wrap(err).Code(fault.UnprocessableEntity)
    }
    req.CreatedBy = request.GetLoggedUserID(c)

    if err := h.useCase.Create(c.Request().Context(), req); err != nil {
        return fault.Wrap(err)
    }

    return response.Created(c, req)
}

func (h Handler) Update(c echo.Context) error {
    var req entity.{ModuleName}UpdateRequest
    if err := c.Bind(&req); err != nil {
        return fault.Wrap(err).Code(fault.UnprocessableEntity)
    }
    req.UpdatedBy = request.GetLoggedUserID(c)

    criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
    if err != nil {
        return fault.Wrap(err).Code(fault.BadRequest)
    }

    if err := h.useCase.Update(c.Request().Context(), req, criteria.Filters...); err != nil {
        return fault.Wrap(err)
    }

    return response.OK(c, req)
}

func (h Handler) Delete(c echo.Context) error {
    criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
    if err != nil {
        return fault.Wrap(err).Code(fault.BadRequest)
    }

    if err := h.useCase.Delete(c.Request().Context(), criteria.Filters...); err != nil {
        return fault.Wrap(err)
    }

    return c.NoContent(http.StatusNoContent)
}

func (h Handler) Find(c echo.Context) error {
    criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
    if err != nil {
        return fault.Wrap(err).Code(fault.BadRequest)
    }

    result, err := h.useCase.Find(c.Request().Context(), criteria)
    if err != nil {
        return fault.Wrap(err)
    }

    return response.OK(c, result)
}

func (h Handler) List(c echo.Context) error {
    criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
    if err != nil {
        return fault.Wrap(err).Code(fault.BadRequest)
    }

    result, err := h.useCase.List(c.Request().Context(), criteria)
    if err != nil {
        return fault.Wrap(err)
    }

    return response.OK(c, result)
}

func (h Handler) Exists(c echo.Context) error {
    criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
    if err != nil {
        return fault.Wrap(err).Code(fault.BadRequest)
    }

    exists, err := h.useCase.Exists(c.Request().Context(), criteria)
    if err != nil {
        return fault.Wrap(err)
    }

    return response.OK(c, map[string]bool{"exists": exists})
}

func (h Handler) Count(c echo.Context) error {
    criteria, err := dafi.NewQueryParser().Parse(c.QueryParams())
    if err != nil {
        return fault.Wrap(err).Code(fault.BadRequest)
    }

    count, err := h.useCase.Count(c.Request().Context(), criteria)
    if err != nil {
        return fault.Wrap(err)
    }

    return response.OK(c, map[string]int64{"count": count})
}
```

### 5. Module Configuration (`module.go`)

```go
package {module_name}

import (
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/application"
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/infrastructure/presentation"
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/infrastructure/repository/postgres"
    "go-hexagonal-fullstack-monorepo/internal/shared/ports"

    "go.uber.org/fx"
)

var Module = fx.Module("{module_name}",
    fx.Provide(
        fx.Annotate(
            postgres.NewRepository,
            fx.As(new(ports.{ModuleName}Repository)),
        ),
        fx.Annotate(
            application.NewUseCase,
            fx.As(new(ports.{ModuleName}UseCase)),
        ),
        presentation.NewHandler,
    ),
)
```

### 6. Update Shared Ports (`internal/shared/ports/`)

Add the interface definitions for your module:

```go
// Add to internal/shared/ports/{module_name}.go
package ports

import (
    "context"
    "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/domain/entity"
    "go-hexagonal-fullstack-monorepo/internal/shared/dafi"
    "go-hexagonal-fullstack-monorepo/internal/shared/types"
)

type {ModuleName}Repository interface {
    Create(ctx context.Context, entity entity.{ModuleName}CreateRequest) error
    CreateBulk(ctx context.Context, entities types.List[entity.{ModuleName}CreateRequest]) error
    Update(ctx context.Context, entity entity.{ModuleName}UpdateRequest, filters ...dafi.Filter) error
    Delete(ctx context.Context, filters ...dafi.Filter) error
    HardDelete(ctx context.Context, filters ...dafi.Filter) error
    Find(ctx context.Context, criteria dafi.Criteria) (entity.{ModuleName}, error)
    List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.{ModuleName}], error)
    Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)
    Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
    WithTx(tx Transaction) {ModuleName}Repository
}

type {ModuleName}UseCase interface {
    Create(ctx context.Context, req entity.{ModuleName}CreateRequest) error
    Update(ctx context.Context, req entity.{ModuleName}UpdateRequest, filters ...dafi.Filter) error
    Delete(ctx context.Context, filters ...dafi.Filter) error
    Find(ctx context.Context, criteria dafi.Criteria) (entity.{ModuleName}, error)
    List(ctx context.Context, criteria dafi.Criteria) (types.List[entity.{ModuleName}], error)
    Exists(ctx context.Context, criteria dafi.Criteria) (bool, error)
    Count(ctx context.Context, criteria dafi.Criteria) (int64, error)
}
```

### 7. Database Migration

Create database migration files:

```sql
-- migrations/xxxxx_create_{table_name}_table.up.sql
CREATE TABLE IF NOT EXISTS schema.{table_name} (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    status VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID,
    updated_at TIMESTAMPTZ,
    updated_by UUID,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID
);

CREATE INDEX IF NOT EXISTS idx_{table_name}_deleted_at ON schema.{table_name}(deleted_at);
CREATE INDEX IF NOT EXISTS idx_{table_name}_name ON schema.{table_name}(name);
CREATE INDEX IF NOT EXISTS idx_{table_name}_status ON schema.{table_name}(status);

-- migrations/xxxxx_create_{table_name}_table.down.sql
DROP TABLE IF EXISTS schema.{table_name};
```

### 8. Register Routes

Add routes to your application router:

```go
// In cmd/api/router/{module_name}_routes.go
package router

import (
    "{module_name}Handler" "go-hexagonal-fullstack-monorepo/internal/core/{module_name}/infrastructure/presentation"
    "github.com/labstack/echo/v4"
)

func Register{ModuleName}Routes(api *echo.Group, handler *{module_name}Handler.Handler) {
    {module_name}Group := api.Group("/{module_name_plural}")
    
    {module_name}Group.POST("", handler.Create)
    {module_name}Group.GET("", handler.List)
    {module_name}Group.GET("/:id", handler.Find)
    {module_name}Group.PATCH("/:id", handler.Update)
    {module_name}Group.DELETE("/:id", handler.Delete)
    {module_name}Group.HEAD("", handler.Exists)
    {module_name}Group.GET("/count", handler.Count)
}
```

### 9. Update Main Application

Add your module to the application modules:

```go
// In cmd/api/main.go or appropriate module loader
fx.Provide(
    // ... existing modules
    {module_name}.Module,
),
```

### 10. OpenAPI Documentation

Add your module to the OpenAPI specification following the established patterns:

#### 10.1 Add Paths

```yaml
paths:
  /{module_name_plural}:
    post:
      summary: Create a new {module_name}
      description: Creates a new {module_name} with the provided information
      operationId: create{ModuleName}
      tags:
        - {ModuleName}s
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/{ModuleName}CreateRequest"
            examples:
              basic_{module_name}:
                summary: Basic {module_name} creation
                value:
                  id: "123e4567-e89b-12d3-a456-426614174000"
                  name: "Example Name"
                  status: "active"
      responses:
        "201":
          description: {ModuleName} created successfully
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ApiResponse"

    get:
      summary: List {module_name_plural}
      description: Retrieves a list of {module_name_plural} with optional filtering, sorting, and pagination
      operationId: list{ModuleName}s
      tags:
        - {ModuleName}s
      parameters:
        - $ref: "#/components/parameters/SelectParam"
        - $ref: "#/components/parameters/PaginationParam"
        - name: name
          in: query
          description: "Filter by name OR Sort by name. Filter format: operator:value[:chaining]. Sort format: sort:direction. Operators: eq, ne, gt, gte, lt, lte, like, in, nin, contains, ncontains, is, isn. Chaining: and (default), or. Direction: asc, desc"
          schema:
            type: string
            example: "eq:Example"
        - name: status
          in: query
          description: "Filter by status OR Sort by status. Filter format: operator:value[:chaining]. Sort format: sort:direction. Operators: eq, ne, gt, gte, lt, lte, like, in, nin, contains, ncontains, is, isn. Chaining: and (default), or. Direction: asc, desc"
          schema:
            type: string
            example: "eq:active"
        - name: createdAt
          in: query
          description: "Filter by createdAt OR Sort by createdAt. Filter format: operator:value[:chaining]. Sort format: sort:direction. Operators: eq, ne, gt, gte, lt, lte, like, in, nin, contains, ncontains, is, isn. Chaining: and (default), or. Direction: asc, desc"
          schema:
            type: string
            example: "gte:2023-01-01T00:00:00Z"
      responses:
        "200":
          description: List of {module_name_plural} retrieved successfully
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ApiResponse"

  /{module_name_plural}/{id}:
    get:
      summary: Get {module_name} by ID
      description: Retrieves a specific {module_name} by their ID
      operationId: get{ModuleName}
      tags:
        - {ModuleName}s
      parameters:
        - name: id
          in: path
          required: true
          description: {ModuleName} ID
          schema:
            type: string
            format: uuid
            example: "123e4567-e89b-12d3-a456-426614174000"
        - $ref: "#/components/parameters/SelectParam"
      responses:
        "200":
          description: {ModuleName} retrieved successfully
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ApiResponse"

    patch:
      summary: Update {module_name}
      description: Updates an existing {module_name} with the provided information
      operationId: update{ModuleName}
      tags:
        - {ModuleName}s
      parameters:
        - name: id
          in: path
          required: true
          description: {ModuleName} ID
          schema:
            type: string
            format: uuid
            example: "123e4567-e89b-12d3-a456-426614174000"
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/{ModuleName}UpdateRequest"
      responses:
        "200":
          description: {ModuleName} updated successfully
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ApiResponse"

    delete:
      summary: Delete {module_name}
      description: Soft deletes a {module_name} by their ID
      operationId: delete{ModuleName}
      tags:
        - {ModuleName}s
      parameters:
        - name: id
          in: path
          required: true
          description: {ModuleName} ID
          schema:
            type: string
            format: uuid
            example: "123e4567-e89b-12d3-a456-426614174000"
      responses:
        "204":
          description: {ModuleName} deleted successfully
```

#### 10.2 Add Schemas

```yaml
components:
  schemas:
    {ModuleName}:
      type: object
      description: {ModuleName} entity with all fields
      properties:
        id:
          type: string
          format: uuid
          description: Unique identifier for the {module_name}
          example: "123e4567-e89b-12d3-a456-426614174000"
        name:
          type: string
          description: {ModuleName} name
          minLength: 3
          maxLength: 100
          example: "Example Name"
        status:
          type: string
          nullable: true
          description: {ModuleName} status
          maxLength: 50
          example: "active"
        createdAt:
          type: string
          format: date-time
          description: Timestamp when {module_name} was created
          example: "2023-01-01T00:00:00Z"
        updatedAt:
          type: string
          format: date-time
          nullable: true
          description: Timestamp when {module_name} was last updated
          example: "2023-01-02T00:00:00Z"
        deletedAt:
          type: string
          format: date-time
          nullable: true
          description: Timestamp when {module_name} was deleted (soft delete)
          example: "2023-01-03T00:00:00Z"
      required:
        - id
        - name
        - createdAt

    {ModuleName}CreateRequest:
      type: object
      description: Request payload for creating a new {module_name}
      properties:
        id:
          type: string
          format: uuid
          description: {ModuleName} ID
          example: "123e4567-e89b-12d3-a456-426614174000"
        name:
          type: string
          description: {ModuleName} name
          minLength: 3
          maxLength: 100
          example: "Example Name"
        status:
          type: string
          nullable: true
          description: {ModuleName} status
          maxLength: 50
          example: "active"
        createdAt:
          type: string
          format: date-time
          nullable: true
          description: Creation timestamp
          example: "2023-01-01T00:00:00Z"
      required:
        - name

    {ModuleName}UpdateRequest:
      type: object
      description: Request payload for updating a {module_name}
      properties:
        name:
          type: string
          nullable: true
          description: {ModuleName} name
          minLength: 3
          maxLength: 100
          example: "Updated Name"
        status:
          type: string
          nullable: true
          description: {ModuleName} status
          maxLength: 50
          example: "inactive"
        updatedAt:
          type: string
          format: date-time
          nullable: true
          description: Update timestamp
          example: "2023-01-02T00:00:00Z"
```

#### 10.3 Add Tags

```yaml
tags:
  - name: {ModuleName}s
    description: {ModuleName} management operations
```

## Important Rules and Guidelines

### 1. Naming Conventions
- Use PascalCase for struct names: `UserCreateRequest`, `Product`, `OrderItem`
- Use camelCase for field names and JSON tags: `firstName`, `createdAt`, `isActive`
- Use snake_case for database columns: `first_name`, `created_at`, `is_active`
- Use kebab-case for URLs: `/users`, `/order-items`, `/product-categories`

### 2. Field Mapping Guidelines
- Always include audit fields: `created_at`, `created_by`, `updated_at`, `updated_by`, `deleted_at`, `deleted_by`
- Use `null` types for optional and nullable fields: `null.String`, `null.Time`, `null.Int`
- Include `omitzero` in JSON tags for response entities
- Exclude audit fields from JSON output using `json:"-"` for `*_by` fields

### 3. Validation Rules
- Define validation schema in `command.go` using the shared validation package
- Include minimum/maximum length constraints
- Mark required fields explicitly
- Use appropriate field types (string, int, bool, time)

### 4. Database Guidelines
- Always use UUIDs for primary keys
- Include soft delete support with `deleted_at` timestamp
- Create indexes for frequently queried fields
- Use appropriate PostgreSQL schemas for organization

### 5. DAFI Integration
- Map all domain fields to SQL columns in `sqlColumnByDomainField`
- Support filtering, sorting, and pagination on all relevant fields
- Include field validation in repository layer
- Use consistent operator patterns across modules

### 6. OpenAPI Guidelines
- Follow the unified parameter approach for filter/sort operations
- Include comprehensive examples for all endpoints
- Use consistent error response patterns
- Document all query parameters with proper DAFI format

### 7. Error Handling
- Use the fault package for all error handling
- Wrap errors with appropriate context
- Map business logic errors to proper HTTP status codes
- Include validation error details

### 8. Testing Guidelines
- Create unit tests for all use cases
- Test validation logic comprehensively
- Include integration tests for repository operations
- Test error scenarios and edge cases

### 9. Security Considerations
- Always validate input data
- Use parameterized queries (handled by SQLCraft)
- Include audit trail for all operations
- Implement proper authorization checks in handlers

### 10. Performance Guidelines
- Use field selection to avoid over-fetching
- Implement proper pagination for list operations
- Add database indexes for frequently queried fields
- Use connection pooling and transaction management

## Template Variables

When creating a new module, replace these template variables:

- `{module_name}`: snake_case module name (e.g., `user`, `product`, `order_item`)
- `{ModuleName}`: PascalCase module name (e.g., `User`, `Product`, `OrderItem`)
- `{moduleName}`: camelCase module name (e.g., `user`, `product`, `orderItem`)
- `{module_name_plural}`: snake_case plural (e.g., `users`, `products`, `order_items`)
- `{table_name}`: database table name (e.g., `users`, `products`, `order_items`)
- `{schema}`: database schema name (e.g., `auth`, `inventory`, `orders`)

## Checklist

After creating a module, verify:

- [ ] All directory structure follows the pattern
- [ ] Domain entities include proper JSON tags and validation
- [ ] Repository implements all CRUD operations
- [ ] Use case layer includes proper error handling
- [ ] HTTP handlers follow REST conventions
- [ ] Database migration files created
- [ ] Module registered in dependency injection
- [ ] Routes registered in router
- [ ] OpenAPI documentation added
- [ ] Ports interfaces defined
- [ ] Tests written and passing
- [ ] DAFI query support implemented
- [ ] Soft delete functionality included
- [ ] Audit trail fields properly handled

This guide ensures consistency across all modules and provides a solid foundation for scalable, maintainable code following hexagonal architecture principles.