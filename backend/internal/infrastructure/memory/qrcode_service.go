package memory

import (
	"context"
	"fmt"
	"sync/atomic"
)

type QRCodeService struct {
	counter int64
}

func NewQRCodeService() *QRCodeService {
	return &QRCodeService{}
}

func (s *QRCodeService) GenerateRegistrationCode(
	_ context.Context,
	eventID, userID string,
) (string, error) {
	n := atomic.AddInt64(&s.counter, 1)
	return fmt.Sprintf("qr_%s_%s_%d", eventID, userID, n), nil
}
