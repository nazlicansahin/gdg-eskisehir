package domain

type EventStatus string

const (
	EventStatusDraft     EventStatus = "draft"
	EventStatusPublished EventStatus = "published"
	EventStatusCancelled EventStatus = "cancelled"
)

func (s EventStatus) IsRegisterable() bool {
	return s == EventStatusPublished
}
