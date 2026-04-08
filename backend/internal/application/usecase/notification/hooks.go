package notification

import (
	"context"
	"fmt"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
)

func (s *Service) OnRegistration(ctx context.Context, userID, eventTitle string) {
	s.NotifyUser(ctx, userID, ports.PushMessage{
		Title: "Registration confirmed",
		Body:  fmt.Sprintf("You are registered for %s! Your QR ticket is ready.", eventTitle),
		Data:  map[string]string{"type": "registration_success"},
	})
}

func (s *Service) OnCheckIn(ctx context.Context, userID, eventTitle string) {
	s.NotifyUser(ctx, userID, ports.PushMessage{
		Title: "Welcome!",
		Body:  fmt.Sprintf("You are checked in for %s. Enjoy the event!", eventTitle),
		Data:  map[string]string{"type": "check_in_success"},
	})
}

func (s *Service) OnEventPublished(ctx context.Context, regRepo ports.RegistrationRepository, eventID, eventTitle string) {
	// Best-effort: no error propagation to caller.
	go func() {
		s.notifyAllUsers(context.Background(), "New event published", fmt.Sprintf("%s is now open for registration!", eventTitle), map[string]string{
			"type":    "event_published",
			"eventId": eventID,
		})
	}()
}

func (s *Service) OnEventCancelled(ctx context.Context, regRepo ports.RegistrationRepository, eventID, eventTitle, reason string) {
	go func() {
		userIDs := s.registeredUserIDs(context.Background(), regRepo, eventID)
		if len(userIDs) == 0 {
			return
		}
		s.NotifyUsers(context.Background(), userIDs, ports.PushMessage{
			Title: "Event cancelled",
			Body:  fmt.Sprintf("%s has been cancelled. Reason: %s", eventTitle, reason),
			Data:  map[string]string{"type": "event_cancelled", "eventId": eventID},
		})
	}()
}

func (s *Service) OnScheduleUpdated(ctx context.Context, regRepo ports.RegistrationRepository, eventID, eventTitle string) {
	go func() {
		userIDs := s.registeredUserIDs(context.Background(), regRepo, eventID)
		if len(userIDs) == 0 {
			return
		}
		s.NotifyUsers(context.Background(), userIDs, ports.PushMessage{
			Title: "Schedule updated",
			Body:  fmt.Sprintf("The schedule for %s has been updated. Check the latest agenda!", eventTitle),
			Data:  map[string]string{"type": "schedule_updated", "eventId": eventID},
		})
	}()
}

func (s *Service) registeredUserIDs(ctx context.Context, regRepo ports.RegistrationRepository, eventID string) []string {
	regs, err := regRepo.ListByEventID(ctx, eventID)
	if err != nil {
		return nil
	}
	ids := make([]string, 0, len(regs))
	for _, r := range regs {
		if r.Status == "active" {
			ids = append(ids, r.UserID)
		}
	}
	return ids
}

func (s *Service) notifyAllUsers(ctx context.Context, title, body string, data map[string]string) {
	// For "all users" notifications, we send to all device tokens.
	// A more scalable approach would use FCM topics.
	tokens, err := s.deviceTokens.ListByUserIDs(ctx, []string{})
	if err != nil || len(tokens) == 0 {
		return
	}
	raw := make([]string, len(tokens))
	for i, t := range tokens {
		raw[i] = t.Token
	}
	_ = s.push.SendToTokens(ctx, raw, ports.PushMessage{Title: title, Body: body, Data: data})
}
