package fault

import (
	"errors"
	"fmt"
	"net/http"
	"path/filepath"
	"runtime"
	"strings"
)

type Error struct {
	TitleText   string  `json:"title,omitempty"`
	MessageText string  `json:"message"`
	CodeName    string  `json:"code"`
	Cause       error   `json:"cause,omitempty"`
	Stack       []Frame `json:"stack,omitempty"`
}

type Frame struct {
	File     string `json:"file"`
	Line     int    `json:"line"`
	Function string `json:"function"`
}

// Wrap starts a new error builder chain if the cause error is not nil.
// Returns nil if causeError is nil.
func Wrap(causeError error) *Error {
	if causeError == nil {
		return nil
	}

	var errTrace *Error
	if errors.As(causeError, &errTrace) {
		errTrace.Stack = append(errTrace.Stack, captureStack())
		return errTrace
	}

	return &Error{
		Cause: causeError,
		Stack: []Frame{captureStack()},
	}
}

// Code sets the error code
func (e *Error) Code(code Code) *Error {
	e.CodeName = string(code)
	return e
}

// Message sets the error message
func (e *Error) Message(msg string) *Error {
	e.MessageText = msg
	return e
}

// Title sets the error title
func (e *Error) Title(title string) *Error {
	e.TitleText = title
	return e
}

// HasTitle returns true if the error has a title
func (e *Error) HasTitle() bool {
	return e.TitleText != ""
}

// HasCode returns true if the error has a code
func (e *Error) HasCode() bool {
	return e.CodeName != ""
}

// HasMessage returns true if the error has a message
func (e *Error) HasMessage() bool {
	return e.MessageText != ""
}

// HTTPStatus returns the HTTP status code for the error code
func (e *Error) HTTPStatus() int {
	if e.CodeName == "" {
		return http.StatusInternalServerError
	}

	if status, ok := HTTPStatusByCode[Code(e.CodeName)]; ok {
		return status
	}

	return http.StatusInternalServerError
}

// Error implements the error interface with a logging-friendly format
func (e *Error) Error() string {
	var parts []string

	if len(e.Stack) > 0 {
		var stackPaths []string
		// Stack is already in correct order, just format it
		for _, frame := range e.Stack {
			location := fmt.Sprintf("%s:%d", frame.File, frame.Line)
			stackPaths = append(stackPaths, location)
		}
		parts = append(parts, fmt.Sprintf("[stack=%s]", strings.Join(stackPaths, ` > `)))
	}

	if e.CodeName != "" {
		parts = append(parts, fmt.Sprintf("[code=%s]", strings.ToLower(e.CodeName)))
	}

	msg := e.MessageText
	if e.Cause != nil {
		msg = fmt.Sprintf("%s: %v", e.MessageText, e.Cause)
	}
	parts = append(parts, fmt.Sprintf("[error=%s]", msg))

	return strings.Join(parts, " ")
}

// captureStack captures the current stack frame
func captureStack() Frame {
	fn, file, line, _ := runtime.Caller(2)

	fullFuncName := runtime.FuncForPC(fn).Name()

	if lastSlash := strings.LastIndex(fullFuncName, "/"); lastSlash != -1 {
		file = fmt.Sprintf("%s/%s", fullFuncName[:lastSlash], filepath.Base(file))
	}

	if lastDot := strings.LastIndex(fullFuncName, "."); lastDot != -1 {
		fullFuncName = fullFuncName[lastDot+1:]
	}

	return Frame{
		File:     file,
		Line:     line,
		Function: fullFuncName,
	}
}
