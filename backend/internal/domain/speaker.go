package domain

import "time"

type Speaker struct {
	ID        string
	FullName  string
	Bio       string
	AvatarURL string
	CreatedAt time.Time
	UpdatedAt time.Time
}
