package notification

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
)

type Scheduler struct {
	notifier   *Service
	events     ports.EventRepository
	sessions   ports.SessionRepository
	regs       ports.RegistrationRepository
	interval   time.Duration
	stopCh     chan struct{}
}

func NewScheduler(
	notifier *Service,
	events ports.EventRepository,
	sessions ports.SessionRepository,
	regs ports.RegistrationRepository,
) *Scheduler {
	return &Scheduler{
		notifier: notifier,
		events:   events,
		sessions: sessions,
		regs:     regs,
		interval: 1 * time.Minute,
		stopCh:   make(chan struct{}),
	}
}

func (s *Scheduler) Start() {
	go s.loop()
}

func (s *Scheduler) Stop() {
	close(s.stopCh)
}

func (s *Scheduler) loop() {
	ticker := time.NewTicker(s.interval)
	defer ticker.Stop()
	for {
		select {
		case <-s.stopCh:
			return
		case <-ticker.C:
			s.tick()
		}
	}
}

func (s *Scheduler) tick() {
	ctx := context.Background()
	now := time.Now().UTC()

	s.sendSessionReminders(ctx, now)
	s.sendEventDayReminders(ctx, now)
}

func (s *Scheduler) listPublishedEvents(ctx context.Context) ([]*domain.Event, error) {
	published := domain.EventStatus("published")
	return s.events.List(ctx, ports.EventListFilter{Status: &published})
}

func (s *Scheduler) sendSessionReminders(ctx context.Context, now time.Time) {
	events, err := s.listPublishedEvents(ctx)
	if err != nil {
		log.Printf("scheduler: list events: %v", err)
		return
	}

	windowStart := now.Add(14 * time.Minute)
	windowEnd := now.Add(16 * time.Minute)

	for _, ev := range events {
		sessions, err := s.sessions.ListByEventID(ctx, ev.ID)
		if err != nil {
			continue
		}
		for _, sess := range sessions {
			if sess.StartsAt.After(windowStart) && sess.StartsAt.Before(windowEnd) {
				userIDs := s.registeredUserIDs(ctx, ev.ID)
				if len(userIDs) == 0 {
					continue
				}
				room := ""
				if sess.Room != "" {
					room = fmt.Sprintf(" at %s", sess.Room)
				}
				s.notifier.NotifyUsers(ctx, userIDs, ports.PushMessage{
					Title: "Session starting soon",
					Body:  fmt.Sprintf("%s is starting in 15 minutes%s", sess.Title, room),
					Data: map[string]string{
						"type":    "session_reminder",
						"eventId": ev.ID,
					},
				})
			}
		}
	}
}

func (s *Scheduler) sendEventDayReminders(ctx context.Context, now time.Time) {
	events, err := s.listPublishedEvents(ctx)
	if err != nil {
		return
	}

	// Send reminder at ~9:00 AM UTC the day before the event.
	// Window: 08:59 - 09:01 to catch exactly one tick per day.
	for _, ev := range events {
		dayBefore := ev.StartsAt.Add(-24 * time.Hour)
		reminderTime := time.Date(dayBefore.Year(), dayBefore.Month(), dayBefore.Day(), 9, 0, 0, 0, time.UTC)

		if now.After(reminderTime.Add(-1*time.Minute)) && now.Before(reminderTime.Add(1*time.Minute)) {
			userIDs := s.registeredUserIDs(ctx, ev.ID)
			if len(userIDs) == 0 {
				continue
			}
			s.notifier.NotifyUsers(ctx, userIDs, ports.PushMessage{
				Title: "Event tomorrow!",
				Body:  fmt.Sprintf("%s is tomorrow! Don't forget your ticket.", ev.Title),
				Data: map[string]string{
					"type":    "event_reminder",
					"eventId": ev.ID,
				},
			})
		}
	}
}

func (s *Scheduler) registeredUserIDs(ctx context.Context, eventID string) []string {
	regs, err := s.regs.ListByEventID(ctx, eventID)
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
