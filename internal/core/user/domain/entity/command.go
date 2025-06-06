package entity

import (
	"go-hexagonal-fullstack-monorepo/internal/shared/valid"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

var userSchema = valid.Object(map[string]valid.Schema{
	"firstName": valid.String().MinLength(3).MaxLength(50).Required(),
	"lastName":  valid.String().MaxLength(50).Optional(),
	"origin":    valid.String().MinLength(3).MaxLength(30).Required(),
})

// UserCreateRequest represents the request to create a User
type UserCreateRequest struct {
	ID        uuid.UUID     `json:"id"`
	FirstName string        `json:"firstName"`
	LastName  null.String   `json:"lastName"`
	Origin    string        `json:"origin"`
	CreatedAt null.Time     `json:"createdAt"`
	CreatedBy uuid.NullUUID `json:"-"`
}

// Validate validates the fields of UserCreateRequest
func (c UserCreateRequest) Validate() error {
	return userSchema.Parse(c)
}

// UserUpdateRequest represents the request to update a User
type UserUpdateRequest struct {
	FirstName null.String   `json:"firstName"`
	LastName  null.String   `json:"lastName"`
	Origin    null.String   `json:"origin"`
	UpdatedAt null.Time     `json:"updatedAt"`
	UpdatedBy uuid.NullUUID `json:"-"`
}

// Validate validates the fields of UserUpdateRequest
func (c UserUpdateRequest) Validate() error {
	return userSchema.Parse(c)
}
