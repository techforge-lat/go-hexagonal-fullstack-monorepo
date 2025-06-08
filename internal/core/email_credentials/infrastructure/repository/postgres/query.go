package postgres

import "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"

var table = "auth.email_credentials"

var sqlColumnByDomainField = map[string]string{
	"id":         "id",
	"userId":     "user_id",
	"email":      "email",
	"isVerified": "is_verified",
	"createdAt":  "created_at",
	"createdBy":  "created_by",
	"updatedAt":  "updated_at",
	"updatedBy":  "updated_by",
}

var (
	insertQuery = sqlcraft.InsertInto(table).WithColumns("id", "user_id", "email", "password_hash", "is_verified", "created_at", "created_by")
	updateQuery = sqlcraft.Update(table).WithColumns("user_id", "email", "password_hash", "is_verified", "updated_at", "updated_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
	deleteQuery = sqlcraft.DeleteFrom(table).SQLColumnByDomainField(sqlColumnByDomainField)
	existsQuery = sqlcraft.Select("1").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	countQuery  = sqlcraft.Select("COUNT(*)").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
)

var selectAllColumns = []string{"id", "user_id", "email", "is_verified", "created_at", "created_by", "updated_at", "updated_by"}
