package sqlcraft

import (
	"strconv"
	"strings"

	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
)

type UpdateQuery struct {
	table           string
	columns         []string
	returningValues []string
	values          []any

	isPartialUpdate bool

	sqlColumnByDomainField map[string]string
	filters                dafi.Filters
}

func Update(table string) UpdateQuery {
	return UpdateQuery{
		table:           table,
		columns:         []string{},
		returningValues: []string{},
		values:          []any{},
	}
}

func (u UpdateQuery) WithColumns(columns ...string) UpdateQuery {
	u.columns = columns

	return u
}

func (u UpdateQuery) WithValues(values ...any) UpdateQuery {
	u.values = values

	return u
}

func (u UpdateQuery) Where(filters ...dafi.Filter) UpdateQuery {
	u.filters = filters

	return u
}

func (u UpdateQuery) SQLColumnByDomainField(sqlColumnByDomainField map[string]string) UpdateQuery {
	u.sqlColumnByDomainField = sqlColumnByDomainField

	return u
}

func (u UpdateQuery) Returning(columns ...string) UpdateQuery {
	u.returningValues = columns

	return u
}

func (u UpdateQuery) WithPartialUpdate() UpdateQuery {
	u.isPartialUpdate = true

	return u
}

func (u UpdateQuery) ToSQL() (Result, error) {
	if len(u.values) > 0 && len(u.values) != len(u.columns) {
		return Result{}, ErrMissMatchValues
	}

	builder := strings.Builder{}

	builder.WriteString("UPDATE ")
	builder.WriteString(u.table)
	builder.WriteString(" SET ")

	for i, column := range u.columns {
		if u.isPartialUpdate {
			builder.WriteString(column)
			builder.WriteString(" = COALESCE($")
			builder.WriteString(strconv.Itoa(i + 1))
			builder.WriteString(", ")
			builder.WriteString(column)
			builder.WriteString(")")
		} else {
			builder.WriteString(column)
			builder.WriteString(" = $")
			builder.WriteString(strconv.Itoa(i + 1))
		}

		if i < len(u.columns)-1 {
			builder.WriteString(", ")
		}
	}

	args := u.values
	if len(u.filters) > 0 {
		whereResult, err := WhereSafe(len(u.values), u.sqlColumnByDomainField, u.filters...)
		if err != nil {
			return Result{}, err
		}
		args = append(args, whereResult.Args...)

		builder.WriteString(whereResult.Sql)
	}

	if len(u.returningValues) > 0 {
		builder.WriteString(" RETURNING ")
		builder.WriteString(strings.Join(u.returningValues, ", "))
	}

	return Result{
		Sql:  builder.String(),
		Args: args,
	}, nil
}