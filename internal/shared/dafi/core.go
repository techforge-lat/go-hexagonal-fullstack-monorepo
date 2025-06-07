package dafi

const (
	groupOpenIndex = iota + 1
	fieldIndex
	operatorIndex
	valueIndex
	groupCloseIndex
	chainingKeyIndex
)

type Criteria struct {
	SelectColumns   []string
	Joins           []string
	Filters         Filters
	FiltersByModule map[string]Filters
	Sorts           Sorts
	Pagination      Pagination
}

func New() Criteria {
	return Criteria{}
}

func Where(field string, operator FilterOperator, value any) Criteria {
	return Criteria{
		Filters: FilterBy(field, operator, value),
	}
}

func (c Criteria) AndGroup(filters ...Filter) Criteria {
	c.Filters = c.Filters.AndGroup(filters...)

	return c
}

func (c Criteria) OrGroup(filters ...Filter) Criteria {
	c.Filters = c.Filters.OrGroup(filters...)

	return c
}

func (c Criteria) Or(field string, operator FilterOperator, value any) Criteria {
	c.Filters = c.Filters.Or(field, operator, value)

	return c
}

func (c Criteria) And(field string, operator FilterOperator, value any) Criteria {
	c.Filters = c.Filters.And(field, operator, value)

	return c
}

func (c Criteria) SortBy(field string, sortType SortType) Criteria {
	c.Sorts = append(c.Sorts, Sort{Field: SortBy(field), Type: sortType})

	return c
}

func (c Criteria) Limit(value uint) Criteria {
	c.Pagination.PageSize = value

	return c
}

func (c Criteria) Page(value uint) Criteria {
	c.Pagination.PageNumber = value

	return c
}

func (c Criteria) Select(columns ...string) Criteria {
	c.SelectColumns = columns

	return c
}
