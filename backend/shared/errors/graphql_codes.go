package errors

import stdErrors "errors"

const (
	CodeUnauthenticated       = "UNAUTHENTICATED"
	CodeForbidden             = "FORBIDDEN"
	CodeNotFound              = "NOT_FOUND"
	CodeValidationFailed      = "VALIDATION_FAILED"
	CodeConflict              = "CONFLICT"
	CodeCapacityReached       = "CAPACITY_REACHED"
	CodeInvalidQRCode         = "INVALID_QR_CODE"
	CodeRegistrationCancelled = "REGISTRATION_CANCELLED"
	CodeAlreadyCheckedIn      = "ALREADY_CHECKED_IN"
	CodeInternal              = "INTERNAL"
)

func ToGraphQLCode(err error) string {
	switch {
	case stdErrors.Is(err, ErrUnauthorized):
		return CodeUnauthenticated
	case stdErrors.Is(err, ErrForbidden):
		return CodeForbidden
	case stdErrors.Is(err, ErrNotFound):
		return CodeNotFound
	case stdErrors.Is(err, ErrValidation):
		return CodeValidationFailed
	case stdErrors.Is(err, ErrConflict), stdErrors.Is(err, ErrAlreadyRegistered):
		return CodeConflict
	case stdErrors.Is(err, ErrCapacityReached):
		return CodeCapacityReached
	case stdErrors.Is(err, ErrInvalidQRCode):
		return CodeInvalidQRCode
	case stdErrors.Is(err, ErrRegistrationCancelled):
		return CodeRegistrationCancelled
	case stdErrors.Is(err, ErrAlreadyCheckedIn):
		return CodeAlreadyCheckedIn
	default:
		return CodeInternal
	}
}
