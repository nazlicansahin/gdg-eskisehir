package ports

import "context"

type DeviceToken struct {
	ID       string
	UserID   string
	Token    string
	Platform string
}

type DeviceTokenRepository interface {
	Upsert(ctx context.Context, userID, token, platform string) error
	ListByUserID(ctx context.Context, userID string) ([]DeviceToken, error)
	ListByUserIDs(ctx context.Context, userIDs []string) ([]DeviceToken, error)
	// ListAll returns tokens for every registered device (used for broadcast pushes).
	ListAll(ctx context.Context) ([]DeviceToken, error)
	Delete(ctx context.Context, userID, token string) error
}
