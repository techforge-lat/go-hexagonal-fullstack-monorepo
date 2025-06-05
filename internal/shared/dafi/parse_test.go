package dafi

import (
	"net/url"
	"reflect"
	"sort"
	"testing"
)

func TestQueryParser_Parse(t *testing.T) {
	defaultOperators := map[FilterOperator]struct{}{
		"eq":        {},
		"ne":        {},
		"gt":        {},
		"gte":       {},
		"lt":        {},
		"lte":       {},
		"like":      {},
		"in":        {},
		"nin":       {},
		"contains":  {},
		"ncontains": {},
		"is":        {},
		"isn":       {},
	}

	type fields struct {
		operators map[FilterOperator]struct{}
	}
	type args struct {
		values url.Values
	}
	tests := []struct {
		name    string
		fields  fields
		args    args
		want    Criteria
		wantErr bool
	}{
		{
			name:    "empty values",
			fields:  fields{operators: defaultOperators},
			args:    args{values: url.Values{}},
			want:    Criteria{},
			wantErr: false,
		},
		{
			name:   "basic pagination",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"x": []string{"page:1", "limit:10"},
			}},
			want: Criteria{
				Pagination: Pagination{
					PageNumber: 1,
					PageSize:   10,
				},
			},
			wantErr: false,
		},
		{
			name:   "basic filtering with different operators",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"name":   []string{"eq:john"},
				"age":    []string{"gt:18"},
				"status": []string{"in:active,pending"},
				"email":  []string{"contains:example.com"},
			}},
			want: Criteria{
				Filters: Filters{
					{Field: "name", Operator: "eq", Value: "john", ChainingKey: And},
					{Field: "age", Operator: "gt", Value: "18", ChainingKey: And},
					{Field: "status", Operator: "in", Value: []string{"active", "pending"}, ChainingKey: And},
					{Field: "email", Operator: "contains", Value: "example.com", ChainingKey: And},
				},
			},
			wantErr: false,
		},
		{
			name:   "negative operators",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"status": []string{"ne:inactive"},
				"role":   []string{"nin:admin,superuser"},
				"email":  []string{"ncontains:spam"},
			}},
			want: Criteria{
				Filters: Filters{
					{Field: "status", Operator: "ne", Value: "inactive", ChainingKey: And},
					{Field: "role", Operator: "nin", Value: []string{"admin", "superuser"}, ChainingKey: And},
					{Field: "email", Operator: "ncontains", Value: "spam", ChainingKey: And},
				},
			},
			wantErr: false,
		},
		{
			name:   "comparison operators",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"price":    []string{"gte:100"},
				"quantity": []string{"lte:50"},
				"rating":   []string{"gt:4.5"},
				"discount": []string{"lt:10"},
			}},
			want: Criteria{
				Filters: Filters{
					{Field: "price", Operator: "gte", Value: "100", ChainingKey: And},
					{Field: "quantity", Operator: "lte", Value: "50", ChainingKey: And},
					{Field: "rating", Operator: "gt", Value: "4.5", ChainingKey: And},
					{Field: "discount", Operator: "lt", Value: "10", ChainingKey: And},
				},
			},
			wantErr: false,
		},
		{
			name:   "combined with sorting and chaining",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"x":      []string{"page:1", "limit:10"},
				"name":   []string{"sort:asc", "like:john%:or"},
				"age":    []string{"gte:18:and"},
				"status": []string{"in:active,pending:or"},
			}},
			want: Criteria{
				Pagination: Pagination{
					PageNumber: 1,
					PageSize:   10,
				},
				Sorts: Sorts{
					{Field: "name", Type: Asc},
				},
				Filters: Filters{
					{Field: "name", Operator: "like", Value: "john%", ChainingKey: Or},
					{Field: "age", Operator: "gte", Value: "18", ChainingKey: And},
					{Field: "status", Operator: "in", Value: []string{"active", "pending"}, ChainingKey: Or},
				},
			},
			wantErr: false,
		},
		{
			name:   "invalid operator defaults to eq",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"name": []string{"invalid:john"},
			}},
			want: Criteria{
				Filters: Filters{
					{Field: "name", Operator: "eq", Value: "john", ChainingKey: And},
				},
			},
			wantErr: false,
		},
		{
			name:   "override previous filter chaining key",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"name":         []string{"eq:john:or"},
				"workspace_id": []string{"and:eq:123:and"},
			}},
			want: Criteria{
				Filters: Filters{
					{Field: "name", Operator: "eq", Value: "john", ChainingKey: And},
					{Field: "workspace_id", Operator: "eq", Value: "123", ChainingKey: And},
				},
			},
			wantErr: false,
		},
		{
			name:   "override previous filter chaining key with",
			fields: fields{operators: defaultOperators},
			args: args{values: url.Values{
				"name":         []string{"eq:john:or"},
				"workspace_id": []string{"and:eq:123"},
			}},
			want: Criteria{
				Filters: Filters{
					{Field: "name", Operator: "eq", Value: "john", ChainingKey: And},
					{Field: "workspace_id", Operator: "eq", Value: "123", ChainingKey: And},
				},
			},
			wantErr: false,
		},
		// {
		// 	name:   "filters by module",
		// 	fields: fields{operators: defaultOperators},
		// 	args: args{values: url.Values{
		// 		"name":         []string{"eq:john:or"},
		// 		"workspace_id": []string{"and:eq:123"},
		// 		"category.id":  []string{"eq:eq:123"},
		// 	}},
		// 	want: Criteria{
		// 		Filters: Filters{
		// 			{Field: "name", Operator: Equal, Value: "john", ChainingKey: And},
		// 			{Field: "workspace_id", Operator: Equal, Value: "123", ChainingKey: And},
		// 		},
		// 		FiltersByModule: map[string]Filters{
		// 			"category": {
		// 				{Module: "category", Field: "id", Operator: "eq", Value: "123", ChainingKey: And},
		// 			},
		// 		},
		// 	},
		// 	wantErr: false,
		// },
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := &QueryParser{
				operators: tt.fields.operators,
			}

			got, err := p.Parse(tt.args.values)
			if (err != nil) != tt.wantErr {
				t.Errorf("QueryParser.Parse() \n\n error = %+v \n\n, wantErr %+v\n\n", err, tt.wantErr)
				return
			}

			sortFilters(got.Filters)
			sortFilters(tt.want.Filters)

			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("QueryParser.Parse() \n\n got = %+v \n\n, want %+v\n\n", got, tt.want)
			}
		})
	}
}

func sortFilters(filters Filters) {
	sort.Slice(filters, func(i, j int) bool {
		if filters[i].Field != filters[j].Field {
			return filters[i].Field < filters[j].Field
		}

		return filters[i].Operator < filters[j].Operator
	})
}
