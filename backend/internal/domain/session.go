package domain

import "time"

type Session struct {
	ID          string
	EventID     string
	Title       string
	Description string
	Room        string
	StartsAt    time.Time
	EndsAt      time.Time
	SortOrder   int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}
