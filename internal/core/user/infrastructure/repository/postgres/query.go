package postgres

import "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"

var table = "auth.users"

var sqlColumnByDomainField = map[string]string{
	"id":        "id",
	"firstName": "first_name",
	"lastName":  "last_name",
	"origin":    "origin",
	"createdAt": "created_at",
	"createdBy": "created_by",
	"updatedAt": "updated_at",
	"updatedBy": "updated_by",
	"deletedAt": "deleted_at",
	"deletedBy": "deleted_by",
}

var (
	insertQuery     = sqlcraft.InsertInto(table).WithColumns("id", "first_name", "last_name", "origin", "created_at", "created_by")
	updateQuery     = sqlcraft.Update(table).WithColumns("first_name", "last_name", "origin", "updated_at", "updated_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
	softDeleteQuery = sqlcraft.Update(table).WithColumns("deleted_at", "deleted_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
	deleteQuery     = sqlcraft.DeleteFrom(table).SQLColumnByDomainField(sqlColumnByDomainField)
	selectQuery     = sqlcraft.Select("id", "first_name", "last_name", "origin", "created_at", "created_by", "updated_at", "updated_by", "deleted_at", "deleted_by").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	existsQuery     = sqlcraft.Select("1").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	countQuery      = sqlcraft.Select("COUNT(*)").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
)
