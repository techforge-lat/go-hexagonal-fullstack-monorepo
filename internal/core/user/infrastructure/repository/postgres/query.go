package postgres

import "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"

var table = "auth.users"

var sqlColumnByDomainField = map[string]string{
	"id":         "id",
	"first_name": "first_name",
	"last_name":  "last_name",
	"origin":     "origin",
	"created_at": "created_at",
	"created_by": "created_by",
	"updated_at": "updated_at",
	"updated_by": "updated_by",
}

var (
	insertQuery = sqlcraft.InsertInto(table).WithColumns("id", "first_name", "last_name", "origin", "created_at", "created_by")
	updateQuery = sqlcraft.Update(table).WithColumns("first_name", "last_name", "origin", "updated_at", "updated_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
	deleteQuery = sqlcraft.DeleteFrom(table).SQLColumnByDomainField(sqlColumnByDomainField)
	selectQuery = sqlcraft.Select("id", "first_name", "last_name", "origin", "created_at", "created_by", "updated_at", "updated_by").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
)
