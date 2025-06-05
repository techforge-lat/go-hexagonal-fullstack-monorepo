package valid

import (
	"regexp"
	"strings"

	"github.com/google/uuid"
)

type StringSchema struct {
	baseSchema
	minLength *int
	maxLength *int
	pattern   *regexp.Regexp
	email     bool
	url       bool
	uuid      bool
}

func String() *StringSchema {
	return &StringSchema{
		baseSchema: baseSchema{},
	}
}

func (s *StringSchema) Parse(value interface{}) *Result {
	return s.parseWithPath(value, "")
}

func (s *StringSchema) parseWithPath(value interface{}, path string) *Result {
	if s.optional && isNilOrEmpty(value) {
		return newResult(true, value, nil)
	}

	if errors := s.validateRequired(value, path); len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	if isNilOrEmpty(value) && !s.required {
		return newResult(true, value, nil)
	}

	str, ok := value.(string)
	if !ok {
		if ptr, isPtr := value.(*string); isPtr && ptr != nil {
			str = *ptr
		} else {
			return newResult(false, nil, []ValidationError{{
				Path:    path,
				Message: getMessage(msgs.TypeString),
				Code:    "type_error",
			}})
		}
	}

	var errors []ValidationError

	if s.minLength != nil && len(str) < *s.minLength {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.MinLength, *s.minLength),
			Code:    "min_length",
		})
	}

	if s.maxLength != nil && len(str) > *s.maxLength {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.MaxLength, *s.maxLength),
			Code:    "max_length",
		})
	}

	if s.pattern != nil && !s.pattern.MatchString(str) {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Pattern),
			Code:    "pattern",
		})
	}

	if s.email && !isValidEmail(str) {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.Email),
			Code:    "email",
		})
	}

	if s.url && !isValidURL(str) {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.URL),
			Code:    "url",
		})
	}

	if s.uuid && !isValidUUID(str) {
		errors = append(errors, ValidationError{
			Path:    path,
			Message: getMessage(msgs.UUID),
			Code:    "uuid",
		})
	}

	errors = append(errors, s.validateCustom(str, path)...)

	if len(errors) > 0 {
		return newResult(false, nil, errors)
	}

	return newResult(true, str, nil)
}

func (s *StringSchema) MinLength(min int) *StringSchema {
	s.minLength = &min
	return s
}

func (s *StringSchema) MaxLength(max int) *StringSchema {
	s.maxLength = &max
	return s
}

func (s *StringSchema) Length(min, max int) *StringSchema {
	s.minLength = &min
	s.maxLength = &max
	return s
}

func (s *StringSchema) Pattern(pattern string) *StringSchema {
	s.pattern = regexp.MustCompile(pattern)
	return s
}

func (s *StringSchema) Email() *StringSchema {
	s.email = true
	return s
}

func (s *StringSchema) URL() *StringSchema {
	s.url = true
	return s
}

func (s *StringSchema) UUID() *StringSchema {
	s.uuid = true
	return s
}

func (s *StringSchema) Optional() Schema {
	s.baseSchema.setOptional()
	return s
}

func (s *StringSchema) Required() Schema {
	s.baseSchema.setRequired()
	return s
}

func (s *StringSchema) Custom(fn CustomValidatorFunc) Schema {
	s.baseSchema.addCustom(fn)
	return s
}

func isValidEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

func isValidURL(url string) bool {
	return strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://")
}

func isValidUUID(uuidStr string) bool {
	_, err := uuid.Parse(uuidStr)
	return err == nil
}