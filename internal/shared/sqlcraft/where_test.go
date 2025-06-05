package sqlcraft

import (
	"reflect"
	"testing"

	"go-hexagonal-fullstack-monorepo/internal/shared/dafi"
)

func TestWhere(t *testing.T) {
	type args struct {
		filters dafi.Filters
	}
	tests := []struct {
		name    string
		args    args
		want    Result
		wantErr bool
	}{
		{
			name: "one filter",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						Field:    dafi.FilterField("email"),
						Operator: dafi.Equal,
						Value:    "hernan_rm@outlook.es",
					},
				},
			},
			want: Result{
				Sql:  " WHERE email = $1",
				Args: []any{"hernan_rm@outlook.es"},
			},
			wantErr: false,
		},
		{
			name: "and chaining key",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						Field:    "email",
						Operator: dafi.Equal,
						Value:    "hernan_rm@outlook.es",
					},
					dafi.Filter{
						Field:    "nickname",
						Operator: dafi.Equal,
						Value:    "hernanreyes",
					},
				},
			},
			want: Result{
				Sql:  " WHERE email = $1 AND nickname = $2",
				Args: []any{"hernan_rm@outlook.es", "hernanreyes"},
			},
			wantErr: false,
		},
		{
			name: "or chaining key",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						Field:       "email",
						Operator:    dafi.Equal,
						Value:       "hernan_rm@outlook.es",
						ChainingKey: dafi.Or,
					},
					dafi.Filter{
						Field:    "nickname",
						Operator: dafi.Equal,
						Value:    "hernanreyes",
					},
				},
			},
			want: Result{
				Sql:  " WHERE email = $1 OR nickname = $2",
				Args: []any{"hernan_rm@outlook.es", "hernanreyes"},
			},
			wantErr: false,
		},
		{
			name: "one condition group",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						IsGroupOpen: true,
						Field:       "email",
						Operator:    dafi.Equal,
						Value:       "hernan_rm@outlook.es",
						ChainingKey: dafi.Or,
					},
					dafi.Filter{
						Field:        "nickname",
						Operator:     dafi.Equal,
						Value:        "hernanreyes",
						IsGroupClose: true,
					},
				},
			},
			want: Result{
				Sql:  " WHERE (email = $1 OR nickname = $2)",
				Args: []any{"hernan_rm@outlook.es", "hernanreyes"},
			},
			wantErr: false,
		},
		{
			name: "two conditions group",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						IsGroupOpen: true,
						Field:       "email",
						Operator:    dafi.Equal,
						Value:       "hernan_rm@outlook.es",
						ChainingKey: dafi.Or,
					},
					dafi.Filter{
						Field:        "nickname",
						Operator:     dafi.Equal,
						Value:        "hernanreyes",
						IsGroupClose: true,
					},
					dafi.Filter{
						IsGroupOpen: true,
						Field:       "phone_number",
						Operator:    dafi.Equal,
						Value:       "12345679",
						ChainingKey: dafi.Or,
					},
					dafi.Filter{
						Field:        "full_name",
						Operator:     dafi.Contains,
						Value:        "Hernan Reyes",
						IsGroupClose: true,
					},
				},
			},
			want: Result{
				Sql:  " WHERE (email = $1 OR nickname = $2) AND (phone_number = $3 OR full_name ILIKE $4)",
				Args: []any{"hernan_rm@outlook.es", "hernanreyes", "12345679", "%Hernan Reyes%"},
			},
			wantErr: false,
		},
		{
			name: "two conditions group with multiple opening and clsing parenthesis",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						IsGroupOpen:  true,
						GroupOpenQty: 2,
						Field:        "email",
						Operator:     dafi.Equal,
						Value:        "hernan_rm@outlook.es",
						ChainingKey:  dafi.Or,
					},
					dafi.Filter{
						Field:        "nickname",
						Operator:     dafi.Equal,
						Value:        "hernanreyes",
						IsGroupClose: true,
						GroupOpenQty: 1,
					},
					dafi.Filter{
						IsGroupOpen:  true,
						GroupOpenQty: 1,
						Field:        "phone_number",
						Operator:     dafi.Equal,
						Value:        "12345679",
						ChainingKey:  dafi.Or,
					},
					dafi.Filter{
						Field:         "full_name",
						Operator:      dafi.Contains,
						Value:         "Hernan Reyes",
						IsGroupClose:  true,
						GroupCloseQty: 2,
					},
				},
			},
			want: Result{
				Sql:  " WHERE ((email = $1 OR nickname = $2) AND (phone_number = $3 OR full_name ILIKE $4))",
				Args: []any{"hernan_rm@outlook.es", "hernanreyes", "12345679", "%Hernan Reyes%"},
			},
			wantErr: false,
		},
		{
			name: "in operator",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						Field:    "id",
						Operator: dafi.In,
						Value:    []uint{1, 2, 3},
					},
				},
			},
			want: Result{
				Sql:  " WHERE id IN ($1, $2, $3)",
				Args: []any{uint(1), uint(2), uint(3)},
			},
			wantErr: false,
		},
		{
			name: "not in operator",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						Field:    "id",
						Operator: dafi.NotIn,
						Value:    []uint{1, 2, 3},
					},
				},
			},
			want: Result{
				Sql:  " WHERE id NOT IN ($1, $2, $3)",
				Args: []any{uint(1), uint(2), uint(3)},
			},
			wantErr: false,
		},
		{
			name: "in operator with float",
			args: args{
				filters: dafi.Filters{
					dafi.Filter{
						Field:    "price",
						Operator: dafi.In,
						Value:    []float64{1.1, 2.2, 3.3},
					},
				},
			},
			want: Result{
				Sql:  " WHERE price IN ($1, $2, $3)",
				Args: []any{1.1, 2.2, 3.3},
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Where(0, tt.args.filters...)
			if (err != nil) != tt.wantErr {
				t.Errorf("Where() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Where() = %v, want %v", got, tt.want)
			}
		})
	}
}