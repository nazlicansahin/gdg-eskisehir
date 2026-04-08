package notification

import (
	"context"
	"log"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
)

type Service struct {
	deviceTokens ports.DeviceTokenRepository
	push         ports.PushSender
}

func NewService(deviceTokens ports.DeviceTokenRepository, push ports.PushSender) *Service {
	return &Service{deviceTokens: deviceTokens, push: push}
}

func (s *Service) RegisterDeviceToken(ctx context.Context, userID, token, platform string) error {
	return s.deviceTokens.Upsert(ctx, userID, token, platform)
}

func (s *Service) NotifyUser(ctx context.Context, userID string, msg ports.PushMessage) {
	tokens, err := s.deviceTokens.ListByUserID(ctx, userID)
	if err != nil {
		log.Printf("notification: list tokens for user %s: %v", userID, err)
		return
	}
	raw := make([]string, len(tokens))
	for i, t := range tokens {
		raw[i] = t.Token
	}
	if err := s.push.SendToTokens(ctx, raw, msg); err != nil {
		log.Printf("notification: push to user %s: %v", userID, err)
	}
}

func (s *Service) NotifyUsers(ctx context.Context, userIDs []string, msg ports.PushMessage) {
	if len(userIDs) == 0 {
		return
	}
	tokens, err := s.deviceTokens.ListByUserIDs(ctx, userIDs)
	if err != nil {
		log.Printf("notification: list tokens for %d users: %v", len(userIDs), err)
		return
	}
	raw := make([]string, len(tokens))
	for i, t := range tokens {
		raw[i] = t.Token
	}
	if err := s.push.SendToTokens(ctx, raw, msg); err != nil {
		log.Printf("notification: push to %d users: %v", len(userIDs), err)
	}
}
