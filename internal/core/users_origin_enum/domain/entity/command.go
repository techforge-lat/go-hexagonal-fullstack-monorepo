package entity

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/valid"

	"gopkg.in/guregu/null.v4"
)

var usersOriginEnumSchema = valid.Object(map[string]valid.Schema{
	"code": valid.String().MinLength(1).MaxLength(50).Required(),
	"name": valid.String().MinLength(1).MaxLength(100).Required(),
})

// UsersOriginEnumCreateRequest represents the request to create a UsersOriginEnum
type UsersOriginEnumCreateRequest struct {
	Code string `json:"code"`
	Name string `json:"name"`
}

// Validate validates the fields of UsersOriginEnumCreateRequest
func (c UsersOriginEnumCreateRequest) Validate() error {
	result := usersOriginEnumSchema.Parse(c)
	if !result.Success {
		return result.Errors[0] // Return first error for simplicity
	}
	return nil
}

// UsersOriginEnumUpdateRequest represents the request to update a UsersOriginEnum
type UsersOriginEnumUpdateRequest struct {
	Code null.String `json:"code"`
	Name null.String `json:"name"`
}

// Validate validates the fields of UsersOriginEnumUpdateRequest
func (c UsersOriginEnumUpdateRequest) Validate() error {
	result := usersOriginEnumSchema.Parse(c)
	if !result.Success {
		return result.Errors[0] // Return first error for simplicity
	}
	return nil
}