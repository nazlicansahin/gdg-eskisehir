package speaker

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/validation"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type ListSpeakersUseCase struct {
	speakers ports.SpeakerRepository
}

func NewListSpeakersUseCase(speakers ports.SpeakerRepository) *ListSpeakersUseCase {
	return &ListSpeakersUseCase{speakers: speakers}
}

func (uc *ListSpeakersUseCase) Execute(ctx context.Context, query *string) ([]*domain.Speaker, error) {
	return uc.speakers.List(ctx, query)
}

type GetSpeakerUseCase struct {
	speakers ports.SpeakerRepository
}

func NewGetSpeakerUseCase(speakers ports.SpeakerRepository) *GetSpeakerUseCase {
	return &GetSpeakerUseCase{speakers: speakers}
}

func (uc *GetSpeakerUseCase) Execute(ctx context.Context, id string) (*domain.Speaker, error) {
	if err := validation.RequireUUID(id); err != nil {
		return nil, err
	}
	s, err := uc.speakers.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if s == nil {
		return nil, sharedErrors.ErrNotFound
	}
	return s, nil
}
