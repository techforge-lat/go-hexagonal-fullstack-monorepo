package sqlcraft

import (
	"reflect"
	"testing"

	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
)

func TestUpdateQuery_ToSQL(t *testing.T) {
	tests := []struct {
		name    string
		query   UpdateQuery
		want    Result
		wantErr bool
	}{
		{
			name:  "update one field",
			query: Update("employees").WithColumns("salary").WithValues(4000),
			want: Result{
				Sql:  "UPDATE employees SET salary = $1",
				Args: []any{4000},
			},
			wantErr: false,
		},
		{
			name:  "update two fields",
			query: Update("employees").WithColumns("salary", "name").WithValues(4000, "Hernan"),
			want: Result{
				Sql:  "UPDATE employees SET salary = $1, name = $2",
				Args: []any{4000, "Hernan"},
			},
			wantErr: false,
		},
		{
			name:  "update two fields with returning",
			query: Update("employees").WithColumns("salary", "name").WithValues(4000, "Hernan").Returning("id"),
			want: Result{
				Sql:  "UPDATE employees SET salary = $1, name = $2 RETURNING id",
				Args: []any{4000, "Hernan"},
			},
			wantErr: false,
		},
		{
			name:  "update two fields with partial update",
			query: Update("employees").WithColumns("salary", "name").WithValues(4000, "Hernan").WithPartialUpdate(),
			want: Result{
				Sql:  "UPDATE employees SET salary = COALESCE($1, salary), name = COALESCE($2, name)",
				Args: []any{4000, "Hernan"},
			},
			wantErr: false,
		},
		{
			name:  "update without providen values",
			query: Update("employees").WithColumns("salary", "name").WithPartialUpdate(),
			want: Result{
				Sql:  "UPDATE employees SET salary = COALESCE($1, salary), name = COALESCE($2, name)",
				Args: []any{},
			},
			wantErr: false,
		},
		{
			name:  "error with missmatch of values",
			query: Update("employees").WithColumns("salary", "name").WithValues("salary").WithPartialUpdate(),
			want: Result{
				Sql:  "",
				Args: nil,
			},
			wantErr: true,
		},
		{
			name:  "update two fields with partial update and filters",
			query: Update("employees").WithColumns("salary", "name").WithValues(4000, "Hernan").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}).WithPartialUpdate(),
			want: Result{
				Sql:  "UPDATE employees SET salary = COALESCE($1, salary), name = COALESCE($2, name) WHERE email = $3",
				Args: []any{4000, "Hernan", "hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name:  "update two fields with partial update and filters",
			query: Update("employees").WithColumns("salary", "name").WithValues(4000, "Hernan").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}, dafi.Filter{Field: "nickname", Operator: dafi.In, Value: []string{"hernan", "brownie"}}).WithPartialUpdate(),
			want: Result{
				Sql:  "UPDATE employees SET salary = COALESCE($1, salary), name = COALESCE($2, name) WHERE email = $3 AND nickname IN ($4, $5)",
				Args: []any{4000, "Hernan", "hernan_rm@outlook.es", "hernan", "brownie"},
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tt.query.ToSQL()
			if (err != nil) != tt.wantErr {
				t.Errorf("UpdateQuery.ToSQL() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("UpdateQuery.ToSQL() = %v, want %v", got, tt.want)
			}
		})
	}
}