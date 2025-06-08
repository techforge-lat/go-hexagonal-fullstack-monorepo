package postgres

import "go-hexagonal-fullstack-monorepo/internal/shared/sqlcraft"

var table = "auth.users_origin_enum"

var sqlColumnByDomainField = map[string]string{
	"code": "code",
	"name": "name",
}

var (
	insertQuery = sqlcraft.InsertInto(table).WithColumns("code", "name")
	updateQuery = sqlcraft.Update(table).WithColumns("code", "name").SQLColumnByDomainField(sqlColumnByDomainField).WithPartialUpdate()
	deleteQuery = sqlcraft.DeleteFrom(table).SQLColumnByDomainField(sqlColumnByDomainField)
	existsQuery = sqlcraft.Select("1").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
	countQuery  = sqlcraft.Select("COUNT(*)").From(table).SQLColumnByDomainField(sqlColumnByDomainField)
)

var selectAllColumns = []string{"code", "name"}