package graphql

import (
	"fmt"

	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type Error struct {
	Message    string
	Extensions map[string]any
}

func (e *Error) Error() string {
	return e.Message
}

func WrapError(err error) error {
	if err == nil {
		return nil
	}
	code := sharedErrors.ToGraphQLCode(err)
	return &Error{
		Message: fmt.Sprintf("graphql operation failed: %v", err),
		Extensions: map[string]any{
			"code": code,
		},
	}
}
