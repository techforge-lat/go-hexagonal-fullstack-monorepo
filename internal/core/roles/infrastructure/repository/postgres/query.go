package postgres

import "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"

var table = "auth.roles"

var sqlColumnByDomainField = map[string]string{
	"id":        "id",
	"code":      "code",
	"name":      "name",
	"createdAt": "created_at",
	"createdBy": "created_by",
	"updatedAt": "updated_at",
	"updatedBy": "updated_by",
}

var (
	insertQuery = sqlcraft.InsertInto(table).WithColumns("id", "code", "name", "created_at", "created_by")
	updateQuery = sqlcraft.Update(table).WithColumns("code", "name", "updated_at", "updated_by").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
	deleteQuery = sqlcraft.DeleteFrom(table).SQLColumnByDomainField(sqlColumnByDomainField)
	existsQuery = sqlcraft.Select("1").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	countQuery  = sqlcraft.Select("COUNT(*)").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
)

var selectAllColumns = []string{"id", "code", "name", "created_at", "created_by", "updated_at", "updated_by"}