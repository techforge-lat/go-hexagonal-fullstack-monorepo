package entity

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/valid"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

var emailCredentialsSchema = valid.Object(map[string]valid.Schema{
	"userId":       valid.String().Required(), // UUID validation
	"email":        valid.String().MinLength(1).MaxLength(255).Required(),
	"passwordHash": valid.String().MaxLength(255).Optional(),
})

// EmailCredentialsCreateRequest represents the request to create an EmailCredentials
type EmailCredentialsCreateRequest struct {
	ID           uuid.UUID     `json:"id"`
	UserID       uuid.UUID     `json:"userId"`
	Email        string        `json:"email"`
	PasswordHash null.String   `json:"passwordHash"`
	IsVerified   bool          `json:"isVerified"`
	CreatedAt    null.Time     `json:"createdAt"`
	CreatedBy    uuid.NullUUID `json:"-"`
}

// Validate validates the fields of EmailCredentialsCreateRequest
func (c EmailCredentialsCreateRequest) Validate() error {
	result := emailCredentialsSchema.Parse(c)
	if !result.Success {
		return result.Errors[0] // Return first error for simplicity
	}
	return nil
}

// EmailCredentialsUpdateRequest represents the request to update an EmailCredentials
type EmailCredentialsUpdateRequest struct {
	UserID       uuid.NullUUID `json:"userId"`
	Email        null.String   `json:"email"`
	PasswordHash null.String   `json:"-"`
	IsVerified   null.Bool     `json:"isVerified"`
	UpdatedAt    null.Time     `json:"updatedAt"`
	UpdatedBy    uuid.NullUUID `json:"-"`
}

// Validate validates the fields of EmailCredentialsUpdateRequest
func (c EmailCredentialsUpdateRequest) Validate() error {
	result := emailCredentialsSchema.Parse(c)
	if !result.Success {
		return result.Errors[0] // Return first error for simplicity
	}
	return nil
}
