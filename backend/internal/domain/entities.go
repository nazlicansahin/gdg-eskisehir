package domain

import "time"

type User struct {
	ID          string
	FirebaseUID string
	Email       string
	DisplayName string
	Role        Role
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type Event struct {
	ID          string
	Title       string
	Description string
	Status      EventStatus
	Capacity    int
	StartsAt    time.Time
	EndsAt      time.Time
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type Registration struct {
	ID           string
	EventID      string
	UserID       string
	Status       RegistrationStatus
	QRCodeValue  string
	CheckedInAt  *time.Time
	CancelledAt  *time.Time
	CancelReason *string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
