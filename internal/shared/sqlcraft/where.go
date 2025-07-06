package sqlcraft

import (
	"errors"
	"fmt"
	"strconv"
	"strings"

	"api.system.soluciones-cloud.com/internal/shared/dafi"
	"api.system.soluciones-cloud.com/internal/shared/fault"
)

var (
	ErrInvalidOperator  = errors.New("invalid dafi operator")
	ErrInvalidFieldName = errors.New("invalid field name")
)

var psqlOperatorByDafiOperator = map[dafi.FilterOperator]string{
	dafi.Equal:          "=",
	dafi.NotEqual:       "<>",
	dafi.Greater:        ">",
	dafi.GreaterOrEqual: ">=",
	dafi.Less:           "<",
	dafi.LessOrEqual:    "<=",
	dafi.Contains:       "ILIKE",
	dafi.NotContains:    "NOT ILIKE",
	dafi.Is:             "IS",
	dafi.IsNull:         "IS NULL",
	dafi.IsNot:          "IS NOT",
	dafi.IsNotNull:      "IS NOT NULL",
	dafi.In:             "IN",
	dafi.NotIn:          "NOT IN",
	dafi.Default:        "",
}

// WhereSafe maps domain field names to sql column names,
// if a filter with an unknow domain field name is found it will return an error
func WhereSafe(initialArgCount int, sqlColumnByDomainField map[string]string, filters ...dafi.Filter) (Result, error) {
	if len(sqlColumnByDomainField) > 0 {
		for i, filter := range filters {
			sqlColumnName, ok := sqlColumnByDomainField[string(filter.Field)]
			if !ok {
				return Result{}, fault.Wrap(ErrInvalidFieldName).
					Code(fault.BadRequest).
					Message(fmt.Sprintf("invalid field name: %s", filter.Field))
			}
			filters[i].Field = dafi.FilterField(sqlColumnName)
		}
	}

	return Where(initialArgCount, filters...)
}

func Where(initialArgCount int, filters ...dafi.Filter) (Result, error) {
	if len(filters) == 0 {
		return Result{}, nil
	}

	builder := strings.Builder{}
	builder.WriteString(" WHERE ")

	args := []any{}
	argCount := initialArgCount

	for i, filter := range filters {
		if filter.IsGroupOpen {
			for j := 0; j < max(1, filter.GroupOpenQty); j++ {
				builder.WriteString("(")
			}
		}

		// Handle operator - default to Equal if not set
		operator := filter.Operator
		if operator == "" {
			operator = dafi.Equal
		}

		if operator == dafi.IsNull || operator == dafi.IsNotNull {
			builder.WriteString(string(filter.Field))
			builder.WriteString(" ")
			builder.WriteString(psqlOperatorByDafiOperator[operator])
		} else if operator == dafi.In || operator == dafi.NotIn {
			builder.WriteString(string(filter.Field))
			builder.WriteString(" ")
			builder.WriteString(psqlOperatorByDafiOperator[operator])
			builder.WriteString(" ")

			inResult := In(filter.Value, argCount+1)
			builder.WriteString(inResult.Sql)
			args = append(args, inResult.Args...)
			argCount += len(inResult.Args)
		} else if operator == dafi.Contains || operator == dafi.NotContains {
			builder.WriteString(string(filter.Field))
			builder.WriteString(" ")
			builder.WriteString(psqlOperatorByDafiOperator[operator])
			builder.WriteString(" ")
			builder.WriteString("$")
			builder.WriteString(strconv.Itoa(argCount + 1))

			args = append(args, fmt.Sprintf("%%%v%%", filter.Value))
			argCount++
		} else {
			builder.WriteString(string(filter.Field))
			builder.WriteString(" ")
			builder.WriteString(psqlOperatorByDafiOperator[operator])
			builder.WriteString(" ")
			builder.WriteString("$")
			builder.WriteString(strconv.Itoa(argCount + 1))

			args = append(args, filter.Value)
			argCount++
		}

		if filter.IsGroupClose {
			for j := 0; j < max(1, filter.GroupCloseQty); j++ {
				builder.WriteString(")")
			}
		}

		// Add chaining key for all but the last filter
		if i < len(filters)-1 {
			chainingKey := filter.ChainingKey
			if chainingKey == "" {
				chainingKey = dafi.And // Default to AND
			}
			builder.WriteString(" ")
			builder.WriteString(string(chainingKey))
			builder.WriteString(" ")
		}
	}

	return Result{
		Sql:  builder.String(),
		Args: args,
	}, nil
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
