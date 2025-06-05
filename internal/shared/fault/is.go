package fault

import "errors"

// Is reports whether any error in err's chain matches target.
// For fault.Error types, it checks the underlying Cause.
func Is(err error, target error) bool {
	var faultErr *Error
	if errors.As(err, &faultErr) {
		return errors.Is(faultErr.Cause, target)
	}

	return errors.Is(err, target)
}
