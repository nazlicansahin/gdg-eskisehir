package speaker

import (
	"context"
	"strings"

	"github.com/gdg-eskisehir/events/backend/internal/application/policy"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type CreateSpeakerUseCase struct {
	speakers ports.SpeakerRepository
}

func NewCreateSpeakerUseCase(speakers ports.SpeakerRepository) *CreateSpeakerUseCase {
	return &CreateSpeakerUseCase{speakers: speakers}
}

type CreateSpeakerInput struct {
	ActorRole domain.Role
	FullName  string
	Bio       string
	AvatarURL string
}

func (uc *CreateSpeakerUseCase) Execute(ctx context.Context, in CreateSpeakerInput) (*domain.Speaker, error) {
	if err := policy.CanCreateEvent(in.ActorRole); err != nil {
		return nil, err
	}
	name := strings.TrimSpace(in.FullName)
	if name == "" {
		return nil, sharedErrors.ErrValidation
	}
	s := &domain.Speaker{
		FullName:  name,
		Bio:       strings.TrimSpace(in.Bio),
		AvatarURL: strings.TrimSpace(in.AvatarURL),
	}
	if err := uc.speakers.Create(ctx, s); err != nil {
		return nil, err
	}
	return s, nil
}

type UpdateSpeakerUseCase struct {
	speakers ports.SpeakerRepository
}

func NewUpdateSpeakerUseCase(speakers ports.SpeakerRepository) *UpdateSpeakerUseCase {
	return &UpdateSpeakerUseCase{speakers: speakers}
}

type UpdateSpeakerInput struct {
	ActorRole domain.Role
	SpeakerID string
	FullName  *string
	Bio       *string
	AvatarURL *string
}

func (uc *UpdateSpeakerUseCase) Execute(ctx context.Context, in UpdateSpeakerInput) (*domain.Speaker, error) {
	if err := policy.CanCreateEvent(in.ActorRole); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.SpeakerID); err != nil {
		return nil, err
	}
	cur, err := uc.speakers.GetByID(ctx, in.SpeakerID)
	if err != nil {
		return nil, err
	}
	if cur == nil {
		return nil, sharedErrors.ErrNotFound
	}
	if in.FullName != nil && strings.TrimSpace(*in.FullName) == "" {
		return nil, sharedErrors.ErrValidation
	}
	fn := in.FullName
	if fn != nil {
		v := strings.TrimSpace(*fn)
		fn = &v
	}
	if err := uc.speakers.Update(ctx, in.SpeakerID, fn, in.Bio, in.AvatarURL); err != nil {
		return nil, err
	}
	return uc.speakers.GetByID(ctx, in.SpeakerID)
}

type AttachSpeakerToSessionUseCase struct {
	events   ports.EventRepository
	sessions ports.SessionRepository
	speakers ports.SpeakerRepository
}

func NewAttachSpeakerToSessionUseCase(
	events ports.EventRepository,
	sessions ports.SessionRepository,
	speakers ports.SpeakerRepository,
) *AttachSpeakerToSessionUseCase {
	return &AttachSpeakerToSessionUseCase{events: events, sessions: sessions, speakers: speakers}
}

type AttachSpeakerToSessionInput struct {
	ActorRole domain.Role
	SessionID string
	SpeakerID string
}

func (uc *AttachSpeakerToSessionUseCase) Execute(ctx context.Context, in AttachSpeakerToSessionInput) (*domain.Session, error) {
	if err := policy.CanCreateEvent(in.ActorRole); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.SessionID); err != nil {
		return nil, err
	}
	if err := validation.RequireUUID(in.SpeakerID); err != nil {
		return nil, err
	}
	sess, err := uc.sessions.GetByID(ctx, in.SessionID)
	if err != nil {
		return nil, err
	}
	if sess == nil {
		return nil, sharedErrors.ErrNotFound
	}
	ev, err := uc.events.GetByID(ctx, sess.EventID)
	if err != nil {
		return nil, err
	}
	if ev == nil {
		return nil, sharedErrors.ErrNotFound
	}
	sp, err := uc.speakers.GetByID(ctx, in.SpeakerID)
	if err != nil {
		return nil, err
	}
	if sp == nil {
		return nil, sharedErrors.ErrNotFound
	}
	if err := uc.sessions.AttachSpeaker(ctx, in.SessionID, in.SpeakerID); err != nil {
		return nil, err
	}
	return uc.sessions.GetByID(ctx, in.SessionID)
}
