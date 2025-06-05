package valid

import (
	"fmt"
	"strings"
)

func (r *Result) Error() string {
	if r.Success {
		return ""
	}
	
	var messages []string
	for _, err := range r.Errors {
		if err.Path != "" {
			messages = append(messages, fmt.Sprintf("%s: %s", err.Path, err.Message))
		} else {
			messages = append(messages, err.Message)
		}
	}
	
	return strings.Join(messages, "; ")
}

func (r *Result) HasErrors() bool {
	return !r.Success
}

func (r *Result) GetErrors() []ValidationError {
	return r.Errors
}

func (r *Result) GetErrorsForField(field string) []ValidationError {
	var errors []ValidationError
	for _, err := range r.Errors {
		if err.Path == field || strings.HasPrefix(err.Path, field+".") {
			errors = append(errors, err)
		}
	}
	return errors
}

func combineResults(results ...*Result) *Result {
	var allErrors []ValidationError
	var lastData interface{}
	
	for _, result := range results {
		if result != nil {
			allErrors = append(allErrors, result.Errors...)
			if result.Data != nil {
				lastData = result.Data
			}
		}
	}
	
	return &Result{
		Success: len(allErrors) == 0,
		Data:    lastData,
		Errors:  allErrors,
	}
}

func addPathPrefix(errors []ValidationError, prefix string) []ValidationError {
	var prefixedErrors []ValidationError
	for _, err := range errors {
		newPath := prefix
		if err.Path != "" {
			newPath = prefix + "." + err.Path
		}
		prefixedErrors = append(prefixedErrors, ValidationError{
			Path:    newPath,
			Message: err.Message,
			Code:    err.Code,
		})
	}
	return prefixedErrors
}