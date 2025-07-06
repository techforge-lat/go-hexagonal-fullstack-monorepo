package entity

import (
	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"

	"api.system.soluciones-cloud.com/internal/shared/valid"
)

type CreateUserRequest struct {
	Origin    string     `json:"origin" validate:"required,max=50"`
	FirstName string     `json:"first_name" validate:"required,max=100"`
	LastName  string     `json:"last_name,omitempty" validate:"omitempty,max=100"`
	Picture   string     `json:"picture,omitempty"`
	IsActive  bool       `json:"is_active"`
	CreatedBy *uuid.UUID `json:"created_by,omitempty"`
}

func (r CreateUserRequest) Validate() error {
	schema := valid.Object(map[string]valid.Schema{
		"origin":     valid.String().MaxLength(50).Required(),
		"first_name": valid.String().MaxLength(100).Required(),
		"last_name":  valid.String().MaxLength(100),
		"picture":    valid.String(),
		"created_by": valid.String().UUID(),
	})
	
	result := schema.Parse(r)
	if !result.Success {
		return &result.Errors[0]
	}
	return nil
}

type UpdateUserRequest struct {
	ID        uuid.UUID   `json:"id" validate:"required,uuid"`
	Origin    null.String `json:"origin,omitempty" validate:"omitempty,max=50"`
	FirstName null.String `json:"first_name,omitempty" validate:"omitempty,max=100"`
	LastName  null.String `json:"last_name,omitempty" validate:"omitempty,max=100"`
	Picture   null.String `json:"picture,omitempty"`
	IsActive  null.Bool   `json:"is_active,omitempty"`
	UpdatedBy *uuid.UUID  `json:"updated_by,omitempty"`
}

func (r UpdateUserRequest) Validate() error {
	schema := valid.Object(map[string]valid.Schema{
		"id":         valid.String().UUID().Required(),
		"origin":     valid.String().MaxLength(50),
		"first_name": valid.String().MaxLength(100),
		"last_name":  valid.String().MaxLength(100),
		"picture":    valid.String(),
		"updated_by": valid.String().UUID(),
	})
	
	result := schema.Parse(r)
	if !result.Success {
		return &result.Errors[0]
	}
	return nil
}

type DeleteUserRequest struct {
	ID        uuid.UUID `json:"id" validate:"required,uuid"`
	DeletedBy uuid.UUID `json:"deleted_by" validate:"required,uuid"`
}

func (r DeleteUserRequest) Validate() error {
	schema := valid.Object(map[string]valid.Schema{
		"id":         valid.String().UUID().Required(),
		"deleted_by": valid.String().UUID().Required(),
	})
	
	result := schema.Parse(r)
	if !result.Success {
		return &result.Errors[0]
	}
	return nil
}

