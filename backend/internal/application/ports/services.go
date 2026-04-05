package ports

import "context"

type QRCodeService interface {
	GenerateRegistrationCode(ctx context.Context, eventID, userID string) (string, error)
}

type Clock interface {
	NowUTC() int64
}
