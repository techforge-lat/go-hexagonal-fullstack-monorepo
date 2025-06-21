package entity

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/valid"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

var roleSchema = valid.Object(map[string]valid.Schema{
	"code": valid.String().MinLength(3).MaxLength(100).Required(),
	"name": valid.String().MinLength(3).MaxLength(100).Required(),
})

// RoleCreateRequest represents the request to create a Role
type RoleCreateRequest struct {
	ID        uuid.UUID     `json:"id"`
	Code      string        `json:"code"`
	Name      string        `json:"name"`
	CreatedAt null.Time     `json:"createdAt"`
	CreatedBy uuid.NullUUID `json:"-"`
}

// Validate validates the fields of RoleCreateRequest
func (c RoleCreateRequest) Validate() error {
	result := roleSchema.Parse(c)
	if !result.Success {
		return result.Errors[0] // Return first error for simplicity
	}
	return nil
}

// RoleUpdateRequest represents the request to update a Role
type RoleUpdateRequest struct {
	Code      null.String   `json:"code"`
	Name      null.String   `json:"name"`
	UpdatedAt null.Time     `json:"updatedAt"`
	UpdatedBy uuid.NullUUID `json:"-"`
}

// Validate validates the fields of RoleUpdateRequest
func (c RoleUpdateRequest) Validate() error {
	result := roleSchema.Parse(c)
	if !result.Success {
		return result.Errors[0] // Return first error for simplicity
	}
	return nil
}

