package domain

import "time"

type Announcement struct {
	ID        string
	EventID   *string
	Title     string
	Body      string
	CreatedBy string
	CreatedAt time.Time
}
