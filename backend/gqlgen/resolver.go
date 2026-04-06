package gqlgen

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/gqlgen/model"
	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/checkin"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/event"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/registration"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/schedule"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/session"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/speaker"
	appuser "github.com/gdg-eskisehir/events/backend/internal/application/usecase/user"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	graphqlctx "github.com/gdg-eskisehir/events/backend/internal/interface/graphql"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
	"github.com/vektah/gqlparser/v2/gqlerror"
)

// Resolver wires application use cases into GraphQL.
type Resolver struct {
	Users         ports.UserRepository
	Registrations ports.RegistrationRepository
	Sessions      ports.SessionRepository
	Speakers      ports.SpeakerRepository

	Register          *registration.RegisterForEventUseCase
	Ticket            *registration.GetMyTicketUseCase
	CheckInQR         *checkin.CheckInByQRUseCase
	CheckManual       *checkin.CheckInManualUseCase
	ListPublic        *event.ListPublicEventsUseCase
	GetPublic         *event.GetPublicEventUseCase
	AdminListEvents   *event.AdminListEventsUseCase
	AdminGetEvent     *event.AdminGetEventUseCase
	CreateEventExec   *event.CreateEventUseCase
	UpdateEventExec   *event.UpdateEventUseCase
	PublishEventExec  *event.PublishEventUseCase
	CancelEventExec   *event.CancelEventUseCase
	ListSchedule      *schedule.ListEventScheduleUseCase
	ListSpeakers      *speaker.ListSpeakersUseCase
	GetSpeaker        *speaker.GetSpeakerUseCase
	CreateSessionExec *session.CreateSessionUseCase
	UpdateSessionExec *session.UpdateSessionUseCase
	CreateSpeakerExec *speaker.CreateSpeakerUseCase
	UpdateSpeakerUC   *speaker.UpdateSpeakerUseCase
	AttachSpeaker     *speaker.AttachSpeakerToSessionUseCase
	UpdateProfile     *appuser.UpdateMyProfileUseCase
	AssignRole        *appuser.AssignUserRoleUseCase
	AdminUsersExec    *appuser.AdminListUsersUseCase
	MyRegs            *registration.ListMyRegistrationsUseCase
	AdminRegs         *registration.AdminListRegistrationsUseCase
	CancelReg         *registration.CancelRegistrationUseCase
}

func gqlAPIError(err error) error {
	if err == nil {
		return nil
	}
	code := sharedErrors.ToGraphQLCode(err)
	e := gqlerror.Errorf("%v", err)
	e.Extensions = map[string]any{"code": code}
	return e
}

func domainEventStatus(filter *model.EventFilterInput) *domain.EventStatus {
	if filter == nil || filter.Status == nil {
		return nil
	}
	st := domain.EventStatus(*filter.Status)
	return &st
}

func toModelUser(u *domain.User) *model.User {
	if u == nil {
		return nil
	}
	return &model.User{
		ID:          u.ID,
		Email:       u.Email,
		DisplayName: u.DisplayName,
		Role:        model.Role(u.Role),
	}
}

func toModelTicket(r *domain.Registration) *model.RegistrationTicket {
	if r == nil {
		return nil
	}
	return &model.RegistrationTicket{
		ID:          r.ID,
		EventID:     r.EventID,
		UserID:      r.UserID,
		Status:      model.RegistrationStatus(r.Status),
		QRCodeValue: r.QRCodeValue,
		CheckedInAt: r.CheckedInAt,
	}
}

func toModelEvent(e *domain.Event) *model.Event {
	if e == nil {
		return nil
	}
	var desc *string
	if e.Description != "" {
		d := e.Description
		desc = &d
	}
	return &model.Event{
		ID:          e.ID,
		Title:       e.Title,
		Description: desc,
		Status:      model.EventStatus(e.Status),
		Capacity:    e.Capacity,
		StartsAt:    e.StartsAt,
		EndsAt:      e.EndsAt,
	}
}

func toModelSpeaker(s *domain.Speaker) *model.Speaker {
	if s == nil {
		return nil
	}
	out := &model.Speaker{
		ID:       s.ID,
		FullName: s.FullName,
	}
	if s.Bio != "" {
		b := s.Bio
		out.Bio = &b
	}
	if s.AvatarURL != "" {
		a := s.AvatarURL
		out.AvatarURL = &a
	}
	return out
}

func (r *Resolver) sessionModel(ctx context.Context, s *domain.Session) (*model.Session, error) {
	if s == nil {
		return nil, nil
	}
	var desc *string
	if s.Description != "" {
		d := s.Description
		desc = &d
	}
	var room *string
	if s.Room != "" {
		rm := s.Room
		room = &rm
	}
	ids, err := r.Sessions.ListSpeakerIDsForSession(ctx, s.ID)
	if err != nil {
		return nil, err
	}
	mSpeakers := make([]*model.Speaker, 0, len(ids))
	for _, sid := range ids {
		sp, err := r.Speakers.GetByID(ctx, sid)
		if err != nil {
			return nil, err
		}
		if sp != nil {
			mSpeakers = append(mSpeakers, toModelSpeaker(sp))
		}
	}
	return &model.Session{
		ID:          s.ID,
		EventID:     s.EventID,
		Title:       s.Title,
		Description: desc,
		StartsAt:    s.StartsAt,
		EndsAt:      s.EndsAt,
		Room:        room,
		Speakers:    mSpeakers,
	}, nil
}

func (r *mutationResolver) RegisterForEvent(ctx context.Context, eventID string) (*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out, err := r.Register.Execute(ctx, registration.RegisterForEventInput{
		ActorUserID: actor.UserID,
		EventID:     eventID,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return &model.RegistrationTicket{
		ID:          out.RegistrationID,
		EventID:     out.EventID,
		UserID:      out.UserID,
		Status:      model.RegistrationStatus(out.Status),
		QRCodeValue: out.QRCodeValue,
	}, nil
}

func (r *mutationResolver) UpdateMyProfile(ctx context.Context, input model.UpdateMyProfileInput) (*model.User, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	u, err := r.UpdateProfile.Execute(ctx, appuser.UpdateMyProfileInput{
		ActorUserID: actor.UserID,
		DisplayName: input.DisplayName,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelUser(u), nil
}

func (r *mutationResolver) CreateEvent(ctx context.Context, input model.CreateEventInput) (*model.Event, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	desc := ""
	if input.Description != nil {
		desc = *input.Description
	}
	e, err := r.CreateEventExec.Execute(ctx, event.CreateEventInput{
		ActorRole:   actor.Role,
		Title:       input.Title,
		Description: desc,
		Capacity:    input.Capacity,
		StartsAt:    input.StartsAt,
		EndsAt:      input.EndsAt,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelEvent(e), nil
}

func (r *mutationResolver) UpdateEvent(ctx context.Context, input model.UpdateEventInput) (*model.Event, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	e, err := r.UpdateEventExec.Execute(ctx, event.UpdateEventInput{
		ActorRole:   actor.Role,
		EventID:     input.ID,
		Title:       input.Title,
		Description: input.Description,
		Capacity:    input.Capacity,
		StartsAt:    input.StartsAt,
		EndsAt:      input.EndsAt,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelEvent(e), nil
}

func (r *mutationResolver) PublishEvent(ctx context.Context, eventID string) (*model.Event, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	e, err := r.PublishEventExec.Execute(ctx, event.PublishEventInput{ActorRole: actor.Role, EventID: eventID})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelEvent(e), nil
}

func (r *mutationResolver) CancelEvent(ctx context.Context, eventID string, reason string) (*model.Event, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	e, err := r.CancelEventExec.Execute(ctx, event.CancelEventInput{
		ActorRole: actor.Role,
		EventID:   eventID,
		Reason:    reason,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelEvent(e), nil
}

func (r *mutationResolver) CreateSession(ctx context.Context, input model.CreateSessionInput) (*model.Session, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	desc := ""
	if input.Description != nil {
		desc = *input.Description
	}
	room := ""
	if input.Room != nil {
		room = *input.Room
	}
	s, err := r.CreateSessionExec.Execute(ctx, session.CreateSessionInput{
		ActorRole:   actor.Role,
		EventID:     input.EventID,
		Title:       input.Title,
		Description: desc,
		StartsAt:    input.StartsAt,
		EndsAt:      input.EndsAt,
		Room:        room,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return r.sessionModel(ctx, s)
}

func (r *mutationResolver) UpdateSession(ctx context.Context, input model.UpdateSessionInput) (*model.Session, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	s, err := r.UpdateSessionExec.Execute(ctx, session.UpdateSessionInput{
		ActorRole:   actor.Role,
		SessionID:   input.ID,
		Title:       input.Title,
		Description: input.Description,
		Room:        input.Room,
		StartsAt:    input.StartsAt,
		EndsAt:      input.EndsAt,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return r.sessionModel(ctx, s)
}

func (r *mutationResolver) CreateSpeaker(ctx context.Context, input model.CreateSpeakerInput) (*model.Speaker, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	bio := ""
	if input.Bio != nil {
		bio = *input.Bio
	}
	avatar := ""
	if input.AvatarURL != nil {
		avatar = *input.AvatarURL
	}
	s, err := r.CreateSpeakerExec.Execute(ctx, speaker.CreateSpeakerInput{
		ActorRole: actor.Role,
		FullName:  input.FullName,
		Bio:       bio,
		AvatarURL: avatar,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelSpeaker(s), nil
}

func (r *mutationResolver) UpdateSpeaker(ctx context.Context, input model.UpdateSpeakerInput) (*model.Speaker, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	s, err := r.UpdateSpeakerUC.Execute(ctx, speaker.UpdateSpeakerInput{
		ActorRole: actor.Role,
		SpeakerID: input.ID,
		FullName:  input.FullName,
		Bio:       input.Bio,
		AvatarURL: input.AvatarURL,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelSpeaker(s), nil
}

func (r *mutationResolver) AttachSpeakerToSession(ctx context.Context, sessionID string, speakerID string) (*model.Session, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	s, err := r.AttachSpeaker.Execute(ctx, speaker.AttachSpeakerToSessionInput{
		ActorRole: actor.Role,
		SessionID: sessionID,
		SpeakerID: speakerID,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return r.sessionModel(ctx, s)
}

func (r *mutationResolver) CheckInByQR(ctx context.Context, eventID string, qrCode string) (*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out, err := r.CheckInQR.Execute(ctx, checkin.CheckInByQRInput{
		ActorUserID: actor.UserID,
		ActorRole:   actor.Role,
		EventID:     eventID,
		QRCode:      qrCode,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	reg, err := r.Registrations.GetRegistrationByID(ctx, out.RegistrationID)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelTicket(reg), nil
}

func (r *mutationResolver) ManualCheckIn(ctx context.Context, registrationID string) (*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out, err := r.CheckManual.Execute(ctx, checkin.CheckInManualInput{
		ActorUserID:    actor.UserID,
		ActorRole:      actor.Role,
		RegistrationID: registrationID,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	reg, err := r.Registrations.GetRegistrationByID(ctx, out.RegistrationID)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelTicket(reg), nil
}

func (r *mutationResolver) CancelRegistration(ctx context.Context, registrationID string, reason string) (*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	reg, err := r.CancelReg.Execute(ctx, registration.CancelRegistrationInput{
		ActorRole:      actor.Role,
		RegistrationID: registrationID,
		Reason:         reason,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelTicket(reg), nil
}

func (r *mutationResolver) AssignUserRole(ctx context.Context, userID string, role model.Role) (*model.User, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	u, err := r.AssignRole.Execute(ctx, appuser.AssignUserRoleInput{
		ActorRole: actor.Role,
		UserID:    userID,
		Role:      domain.Role(role),
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelUser(u), nil
}

func (r *queryResolver) Me(ctx context.Context) (*model.User, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	u, err := r.Users.GetByID(ctx, actor.UserID)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelUser(u), nil
}

func (r *queryResolver) Events(ctx context.Context, filter *model.EventFilterInput) ([]*model.Event, error) {
	evs, err := r.ListPublic.Execute(ctx, event.ListPublicEventsInput{Status: domainEventStatus(filter)})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.Event, 0, len(evs))
	for _, e := range evs {
		out = append(out, toModelEvent(e))
	}
	return out, nil
}

func (r *queryResolver) Event(ctx context.Context, id string) (*model.Event, error) {
	e, err := r.GetPublic.Execute(ctx, id)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelEvent(e), nil
}

func (r *queryResolver) EventSchedule(ctx context.Context, eventID string) ([]*model.Session, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	reqPub := actor.Role != domain.RoleOrganizer && actor.Role != domain.RoleSuperAdmin
	rows, err := r.ListSchedule.Execute(ctx, schedule.ListEventScheduleInput{
		ActorRole:        actor.Role,
		EventID:          eventID,
		RequirePublished: reqPub,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.Session, 0, len(rows))
	for _, row := range rows {
		m, err := r.sessionModelWithSpeakers(row.Session, row.Speakers)
		if err != nil {
			return nil, gqlAPIError(err)
		}
		out = append(out, m)
	}
	return out, nil
}

func (r *queryResolver) sessionModelWithSpeakers(s *domain.Session, speakers []*domain.Speaker) (*model.Session, error) {
	if s == nil {
		return nil, nil
	}
	var desc *string
	if s.Description != "" {
		d := s.Description
		desc = &d
	}
	var room *string
	if s.Room != "" {
		rm := s.Room
		room = &rm
	}
	mSpeakers := make([]*model.Speaker, 0, len(speakers))
	for _, sp := range speakers {
		mSpeakers = append(mSpeakers, toModelSpeaker(sp))
	}
	return &model.Session{
		ID:          s.ID,
		EventID:     s.EventID,
		Title:       s.Title,
		Description: desc,
		StartsAt:    s.StartsAt,
		EndsAt:      s.EndsAt,
		Room:        room,
		Speakers:    mSpeakers,
	}, nil
}

func (r *queryResolver) Speakers(ctx context.Context, filter *model.SpeakerFilterInput) ([]*model.Speaker, error) {
	var q *string
	if filter != nil {
		q = filter.Query
	}
	speakers, err := r.ListSpeakers.Execute(ctx, q)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.Speaker, 0, len(speakers))
	for _, s := range speakers {
		out = append(out, toModelSpeaker(s))
	}
	return out, nil
}

func (r *queryResolver) Speaker(ctx context.Context, id string) (*model.Speaker, error) {
	s, err := r.GetSpeaker.Execute(ctx, id)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelSpeaker(s), nil
}

func (r *queryResolver) MyRegistrations(ctx context.Context) ([]*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	regs, err := r.MyRegs.Execute(ctx, actor.UserID)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.RegistrationTicket, 0, len(regs))
	for _, reg := range regs {
		out = append(out, toModelTicket(reg))
	}
	return out, nil
}

func (r *queryResolver) MyTicket(ctx context.Context, eventID string) (*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out, err := r.Ticket.Execute(ctx, registration.GetMyTicketInput{
		ActorUserID: actor.UserID,
		EventID:     eventID,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	reg, err := r.Registrations.GetRegistrationByID(ctx, out.RegistrationID)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelTicket(reg), nil
}

func (r *queryResolver) AdminEvents(ctx context.Context, filter *model.EventFilterInput) ([]*model.Event, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	evs, err := r.AdminListEvents.Execute(ctx, event.AdminListEventsInput{
		ActorRole: actor.Role,
		Status:    domainEventStatus(filter),
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.Event, 0, len(evs))
	for _, e := range evs {
		out = append(out, toModelEvent(e))
	}
	return out, nil
}

func (r *queryResolver) AdminEvent(ctx context.Context, id string) (*model.Event, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	e, err := r.AdminGetEvent.Execute(ctx, event.AdminGetEventInput{ActorRole: actor.Role, EventID: id})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	return toModelEvent(e), nil
}

func (r *queryResolver) AdminRegistrations(ctx context.Context, eventID string) ([]*model.RegistrationTicket, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	regs, err := r.AdminRegs.Execute(ctx, registration.AdminListRegistrationsInput{
		ActorRole: actor.Role,
		EventID:   eventID,
	})
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.RegistrationTicket, 0, len(regs))
	for _, reg := range regs {
		out = append(out, toModelTicket(reg))
	}
	return out, nil
}

func (r *queryResolver) AdminUsers(ctx context.Context) ([]*model.User, error) {
	actor, err := graphqlctx.ActorFromContext(ctx)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	users, err := r.AdminUsersExec.Execute(ctx, actor.Role)
	if err != nil {
		return nil, gqlAPIError(err)
	}
	out := make([]*model.User, 0, len(users))
	for _, u := range users {
		out = append(out, toModelUser(u))
	}
	return out, nil
}

func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
