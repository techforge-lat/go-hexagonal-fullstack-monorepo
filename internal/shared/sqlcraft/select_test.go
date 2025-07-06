package sqlcraft

import (
	"reflect"
	"testing"

	"api.system.soluciones-cloud.com/internal/shared/dafi"
)

func TestSelectQuery_ToSQL(t *testing.T) {
	tests := []struct {
		name    string
		query   SelectQuery
		want    Result
		wantErr bool
	}{
		{
			name:  "error empty columns",
			query: Select().From("users"),
			want: Result{
				Sql: "",
			},
			wantErr: true,
		},
		{
			name:  "simple select",
			query: Select("first_name", "last_name").From("users"),
			want: Result{
				Sql:  "SELECT first_name, last_name FROM users",
				Args: []any{},
			},
			wantErr: false,
		},
		{
			name:  "select with required columns",
			query: Select("first_name", "last_name").From("users").RequiredColumns("first_name"),
			want: Result{
				Sql:  "SELECT first_name FROM users",
				Args: []any{},
			},
			wantErr: false,
		},
		{
			name:  "select with filters",
			query: Select("first_name", "last_name").From("users").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}),
			want: Result{
				Sql:  "SELECT first_name, last_name FROM users WHERE email = $1",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name:  "select with filters and order by",
			query: Select("first_name", "last_name").From("users").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}).OrderBy(dafi.Sort{Field: "created_at"}),
			want: Result{
				Sql:  "SELECT first_name, last_name FROM users WHERE email = $1 ORDER BY created_at",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name:  "select with filters and order by desc",
			query: Select("first_name", "last_name").From("users").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}).OrderBy(dafi.Sort{Field: "created_at", Type: dafi.Desc}),
			want: Result{
				Sql:  "SELECT first_name, last_name FROM users WHERE email = $1 ORDER BY created_at DESC",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name:  "select with filters and order by desc and pagination",
			query: Select("first_name", "last_name").From("users").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}).OrderBy(dafi.Sort{Field: "created_at", Type: dafi.Desc}).Limit(10),
			want: Result{
				Sql:  "SELECT first_name, last_name FROM users WHERE email = $1 ORDER BY created_at DESC LIMIT 10 OFFSET 0",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name:  "select with filters and order by desc and pagination limit and page",
			query: Select("first_name", "last_name").From("users").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}).OrderBy(dafi.Sort{Field: "created_at", Type: dafi.Desc}).Limit(10).Page(2),
			want: Result{
				Sql:  "SELECT first_name, last_name FROM users WHERE email = $1 ORDER BY created_at DESC LIMIT 10 OFFSET 10",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tt.query.ToSQL()
			if (err != nil) != tt.wantErr {
				t.Errorf("SelectQuery.ToSQL() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("SelectQuery.ToSQL() = %v, want %v", got, tt.want)
			}
		})
	}
}
