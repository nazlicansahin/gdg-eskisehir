package errors

import "testing"

func TestToGraphQLCode(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want string
	}{
		{"unauthorized", ErrUnauthorized, CodeUnauthenticated},
		{"forbidden", ErrForbidden, CodeForbidden},
		{"not-found", ErrNotFound, CodeNotFound},
		{"validation", ErrValidation, CodeValidationFailed},
		{"conflict", ErrConflict, CodeConflict},
		{"already-registered", ErrAlreadyRegistered, CodeConflict},
		{"capacity", ErrCapacityReached, CodeCapacityReached},
		{"invalid-qr", ErrInvalidQRCode, CodeInvalidQRCode},
		{"registration-cancelled", ErrRegistrationCancelled, CodeRegistrationCancelled},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := ToGraphQLCode(tc.err)
			if got != tc.want {
				t.Fatalf("expected %s, got %s", tc.want, got)
			}
		})
	}
}
