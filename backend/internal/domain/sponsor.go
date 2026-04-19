package domain

import "time"

type Sponsor struct {
	ID         string
	EventID    *string
	Name       string
	LogoURL    *string
	WebsiteURL *string
	Tier       string
	CreatedAt  time.Time
}
