package entity

import (
	"time"

	"github.com/google/uuid"
	"gopkg.in/guregu/null.v4"
)

type User struct {
	ID        uuid.UUID   `json:"id" db:"id"`
	Origin    string      `json:"origin" db:"origin"`
	FirstName string      `json:"first_name" db:"first_name"`
	LastName  null.String `json:"last_name" db:"last_name"`
	Picture   null.String `json:"picture" db:"picture"`
	IsActive  bool        `json:"is_active" db:"is_active"`
	CreatedAt time.Time   `json:"created_at" db:"created_at"`
	CreatedBy *uuid.UUID  `json:"created_by" db:"created_by"`
	UpdatedAt null.Time   `json:"updated_at" db:"updated_at"`
	UpdatedBy *uuid.UUID  `json:"updated_by" db:"updated_by"`
	DeletedAt null.Time   `json:"deleted_at" db:"deleted_at"`
	DeletedBy *uuid.UUID  `json:"deleted_by" db:"deleted_by"`
}

func NewNullString(s string) null.String {
	if s == "" {
		return null.String{}
	}
	return null.StringFrom(s)
}

func NewNullTime(t time.Time) null.Time {
	return null.TimeFrom(t)
}