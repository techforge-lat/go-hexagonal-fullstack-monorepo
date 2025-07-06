package sqlcraft

import (
	"strings"

	"api.system.soluciones-cloud.com/internal/shared/dafi"
)

type DeleteQuery struct {
	table            string
	returningColumns []string

	rawValues []any

	sqlColumnByDomainField map[string]string
	filters                dafi.Filters
}

func DeleteFrom(table string) DeleteQuery {
	return DeleteQuery{
		table:            table,
		returningColumns: []string{},
	}
}

func (d DeleteQuery) Where(filters ...dafi.Filter) DeleteQuery {
	d.filters = filters

	return d
}

func (d DeleteQuery) SQLColumnByDomainField(sqlColumnByDomainField map[string]string) DeleteQuery {
	d.sqlColumnByDomainField = sqlColumnByDomainField

	return d
}

func (d DeleteQuery) Returning(columns ...string) DeleteQuery {
	d.returningColumns = columns

	return d
}

func (d DeleteQuery) ToSQL() (Result, error) {
	builder := strings.Builder{}

	builder.WriteString("DELETE FROM ")
	builder.WriteString(d.table)

	args := []any{}
	if len(d.filters) > 0 {
		whereResult, err := WhereSafe(len(d.rawValues), d.sqlColumnByDomainField, d.filters...)
		if err != nil {
			return Result{}, err
		}
		args = whereResult.Args

		builder.WriteString(whereResult.Sql)
	}

	if len(d.returningColumns) > 0 {
		builder.WriteString(" RETURNING ")
		builder.WriteString(strings.Join(d.returningColumns, ", "))
	}

	return Result{
		Sql:  builder.String(),
		Args: args,
	}, nil
}
