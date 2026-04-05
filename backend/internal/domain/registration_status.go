package domain

type RegistrationStatus string

const (
	RegistrationStatusActive    RegistrationStatus = "active"
	RegistrationStatusCancelled RegistrationStatus = "cancelled"
)
