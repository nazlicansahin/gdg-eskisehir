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
		log.Printf("notification: NotifyUsers skipped: zero user ids")
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
	log.Printf("notification: NotifyUsers users=%d device_tokens=%d title=%q", len(userIDs), len(raw), msg.Title)
	if err := s.push.SendToTokens(ctx, raw, msg); err != nil {
		log.Printf("notification: push to %d users: %v", len(userIDs), err)
	}
}

func (s *Service) NotifyAllDevices(ctx context.Context, msg ports.PushMessage) {
	tokens, err := s.deviceTokens.ListAll(ctx)
	if err != nil {
		log.Printf("[announcement] NotifyAllDevices list tokens: %v", err)
		return
	}
	if len(tokens) == 0 {
		log.Printf("[announcement] NotifyAllDevices: no device tokens in DB")
		return
	}
	raw := make([]string, len(tokens))
	for i, t := range tokens {
		raw[i] = t.Token
	}
	log.Printf("[announcement] NotifyAllDevices device_tokens=%d title=%q", len(raw), msg.Title)
	if err := s.push.SendToTokens(ctx, raw, msg); err != nil {
		log.Printf("[announcement] NotifyAllDevices SendToTokens: %v", err)
	}
}
