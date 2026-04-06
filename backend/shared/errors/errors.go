package errors

import "errors"

var (
	ErrUnauthorized          = errors.New("unauthorized")
	ErrForbidden             = errors.New("forbidden")
	ErrNotFound              = errors.New("not found")
	ErrValidation            = errors.New("validation failed")
	ErrConflict              = errors.New("conflict")
	ErrAlreadyRegistered     = errors.New("already registered")
	ErrCapacityReached       = errors.New("capacity reached")
	ErrInvalidQRCode         = errors.New("invalid qr code")
	ErrRegistrationCancelled = errors.New("registration cancelled")
	ErrAlreadyCheckedIn      = errors.New("already checked in")
)
