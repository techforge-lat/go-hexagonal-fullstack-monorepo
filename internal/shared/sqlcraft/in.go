package sqlcraft

import (
	"bytes"
	"reflect"
	"strconv"
	"strings"
)

func In(value any, initialArgCount int) Result {
	if value == nil {
		return Result{}
	}

	builder := bytes.Buffer{}
	builder.WriteString("(")

	var args []any

	// uses reflection to handle different types
	valSlice := reflect.ValueOf(value)
	if valSlice.Kind() == reflect.Slice {
		if valSlice.Len() == 0 {
			return Result{}
		}

		for i := 0; i < valSlice.Len(); i++ {
			builder.WriteString("$")
			builder.WriteString(strconv.Itoa(initialArgCount + i))
			builder.WriteString(", ")

			args = append(args, valSlice.Index(i).Interface())
		}

		if valSlice.Len() > 0 {
			builder.Truncate(builder.Len() - 2)
		}

		builder.WriteString(")")

		return Result{
			Sql:  builder.String(),
			Args: args,
		}
	}

	str, ok := value.(string)
	if !ok {
		return Result{}
	}

	stringValues := strings.Split(str, ",")
	for i, v := range stringValues {
		builder.WriteString("$")
		builder.WriteString(strconv.Itoa(initialArgCount + i))
		builder.WriteString(", ")

		args = append(args, v)
	}

	builder.Truncate(builder.Len() - 2)
	builder.WriteString(")")

	return Result{
		Sql:  builder.String(),
		Args: args,
	}
}