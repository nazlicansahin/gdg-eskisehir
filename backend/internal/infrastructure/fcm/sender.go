package fcm

import (
	"context"
	"encoding/base64"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"google.golang.org/api/option"
)

type Sender struct {
	client *messaging.Client
}

func NewSender(ctx context.Context, projectID, serviceAccountJSONB64 string) (*Sender, error) {
	raw, err := base64.StdEncoding.DecodeString(serviceAccountJSONB64)
	if err != nil {
		return nil, fmt.Errorf("decode service account: %w", err)
	}
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID}, option.WithCredentialsJSON(raw))
	if err != nil {
		return nil, err
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, err
	}
	return &Sender{client: client}, nil
}

func (s *Sender) SendToTokens(ctx context.Context, tokens []string, msg ports.PushMessage) error {
	if len(tokens) == 0 {
		return nil
	}

	notification := &messaging.Notification{
		Title: msg.Title,
		Body:  msg.Body,
	}

	for _, token := range tokens {
		m := &messaging.Message{
			Token:        token,
			Notification: notification,
			Data:         msg.Data,
		}
		if _, err := s.client.Send(ctx, m); err != nil {
			log.Printf("fcm: failed to send to %s: %v", token[:8], err)
		}
	}
	return nil
}
