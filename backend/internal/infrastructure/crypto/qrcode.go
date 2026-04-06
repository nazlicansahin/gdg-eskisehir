package crypto

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
)

type QRCodeService struct{}

func NewQRCodeService() *QRCodeService {
	return &QRCodeService{}
}

func (s *QRCodeService) GenerateRegistrationCode(
	_ context.Context,
	eventID, userID string,
) (string, error) {
	_ = eventID
	_ = userID
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("qr code generation: %w", err)
	}
	return "qr_" + hex.EncodeToString(buf), nil
}
