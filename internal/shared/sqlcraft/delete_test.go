package sqlcraft

import (
	"reflect"
	"testing"

	"api.system.soluciones-cloud.com/internal/shared/dafi"
)

func TestDeleteQuery_ToSQL(t *testing.T) {
	tests := []struct {
		name    string
		query   DeleteQuery
		want    Result
		wantErr bool
	}{
		{
			name:  "simple delete",
			query: DeleteFrom("users"),
			want: Result{
				Sql:  "DELETE FROM users",
				Args: []any{},
			},
			wantErr: false,
		},
		{
			name:  "delete with returning",
			query: DeleteFrom("users").Returning("id"),
			want: Result{
				Sql:  "DELETE FROM users RETURNING id",
				Args: []any{},
			},
			wantErr: false,
		},
		{
			name:  "delete with returning and filters",
			query: DeleteFrom("users").Where(dafi.Filter{Field: "email", Value: "hernan_rm@outlook.es"}).Returning("id"),
			want: Result{
				Sql:  "DELETE FROM users WHERE email = $1 RETURNING id",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name:  "delete with returning and filters in",
			query: DeleteFrom("users").Where(dafi.Filter{Field: "email", Operator: dafi.In, Value: []string{"hernan_rm@outlook.es", "brownie@gmail.com"}}).Returning("id"),
			want: Result{
				Sql:  "DELETE FROM users WHERE email IN ($1, $2) RETURNING id",
				Args: []any{"hernan_rm@outlook.es", "brownie@gmail.com"},
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tt.query.ToSQL()
			if (err != nil) != tt.wantErr {
				t.Errorf("DeleteQuery.ToSQL() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("DeleteQuery.ToSQL() = %v, want %v", got, tt.want)
			}
		})
	}
}
