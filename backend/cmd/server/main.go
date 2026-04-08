package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/gdg-eskisehir/events/backend/gqlgen"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/checkin"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/event"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/notification"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/registration"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/schedule"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/session"
	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/speaker"
	appuser "github.com/gdg-eskisehir/events/backend/internal/application/usecase/user"
	"github.com/gdg-eskisehir/events/backend/internal/config"
	"github.com/gdg-eskisehir/events/backend/internal/gqlserver"
	cryptosvc "github.com/gdg-eskisehir/events/backend/internal/infrastructure/crypto"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/fcm"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/firebaseauth"
	"github.com/gdg-eskisehir/events/backend/internal/infrastructure/postgres"
	"github.com/gdg-eskisehir/events/backend/internal/interface/graphql"
	"github.com/gdg-eskisehir/events/backend/internal/interface/httpapi"
)

func main() {
	ctx := context.Background()

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	pool, err := postgres.NewPool(ctx, cfg.PostgresDSN)
	if err != nil {
		log.Fatalf("postgres: %v", err)
	}
	defer pool.Close()

	db := &postgres.DB{Pool: pool}
	userRepo := postgres.NewUserRepository(db)
	eventRepo := postgres.NewEventRepository(db)
	regRepo := postgres.NewRegistrationRepository(db)
	sessionRepo := postgres.NewSessionRepository(db)
	speakerRepo := postgres.NewSpeakerRepository(db)
	uow := postgres.NewUnitOfWork(db)
	qr := cryptosvc.NewQRCodeService()

	registerUC := registration.NewRegisterForEventUseCase(uow, eventRepo, regRepo, qr)
	ticketUC := registration.NewGetMyTicketUseCase(regRepo)
	checkInQR := checkin.NewCheckInByQRUseCase(uow, regRepo)
	checkInManual := checkin.NewCheckInManualUseCase(uow, regRepo)

	listPublic := event.NewListPublicEventsUseCase(eventRepo)
	getPublic := event.NewGetPublicEventUseCase(eventRepo)
	adminListEv := event.NewAdminListEventsUseCase(eventRepo)
	adminGetEv := event.NewAdminGetEventUseCase(eventRepo)
	createEv := event.NewCreateEventUseCase(eventRepo)
	updateEv := event.NewUpdateEventUseCase(eventRepo)
	publishEv := event.NewPublishEventUseCase(eventRepo)
	cancelEv := event.NewCancelEventUseCase(eventRepo)
	listSchedule := schedule.NewListEventScheduleUseCase(eventRepo, sessionRepo, speakerRepo)
	listSpeakers := speaker.NewListSpeakersUseCase(speakerRepo)
	getSpeaker := speaker.NewGetSpeakerUseCase(speakerRepo)
	createSess := session.NewCreateSessionUseCase(eventRepo, sessionRepo)
	updateSess := session.NewUpdateSessionUseCase(sessionRepo)
	createSpk := speaker.NewCreateSpeakerUseCase(speakerRepo)
	updateSpk := speaker.NewUpdateSpeakerUseCase(speakerRepo)
	attachSpk := speaker.NewAttachSpeakerToSessionUseCase(eventRepo, sessionRepo, speakerRepo)
	updateProfile := appuser.NewUpdateMyProfileUseCase(userRepo)
	grantRole := appuser.NewGrantUserRoleUseCase(userRepo)
	revokeRole := appuser.NewRevokeUserRoleUseCase(userRepo)
	adminUsers := appuser.NewAdminListUsersUseCase(userRepo)
	myRegs := registration.NewListMyRegistrationsUseCase(regRepo)
	adminRegs := registration.NewAdminListRegistrationsUseCase(regRepo)
	cancelReg := registration.NewCancelRegistrationUseCase(regRepo)

	verifier, err := firebaseauth.NewVerifier(ctx, cfg.FirebaseProjectID, cfg.FirebaseServiceAccountJSONB64)
	if err != nil {
		log.Fatalf("firebase: %v", err)
	}

	deviceTokenRepo := postgres.NewDeviceTokenRepository(db)
	pushSender, err := fcm.NewSender(ctx, cfg.FirebaseProjectID, cfg.FirebaseServiceAccountJSONB64)
	if err != nil {
		log.Fatalf("fcm sender: %v", err)
	}
	notifier := notification.NewService(deviceTokenRepo, pushSender)

	reg := &httpapi.RegistrationHandlers{
		Register: registerUC,
		Ticket:   ticketUC,
	}
	ch := &httpapi.CheckinHandlers{
		QR:     checkInQR,
		Manual: checkInManual,
	}

	schema, err := gqlserver.LoadSchema()
	if err != nil {
		log.Fatalf("graphql schema: %v", err)
	}

	gqlSrv := handler.NewDefaultServer(gqlgen.NewExecutableSchema(gqlgen.Config{
		Schema: schema,
		Resolvers: &gqlgen.Resolver{
			Users:             userRepo,
			Registrations:     regRepo,
			Sessions:          sessionRepo,
			Speakers:          speakerRepo,
			Register:          registerUC,
			Ticket:            ticketUC,
			CheckInQR:         checkInQR,
			CheckManual:       checkInManual,
			ListPublic:        listPublic,
			GetPublic:         getPublic,
			AdminListEvents:   adminListEv,
			AdminGetEvent:     adminGetEv,
			CreateEventExec:   createEv,
			UpdateEventExec:   updateEv,
			PublishEventExec:  publishEv,
			CancelEventExec:   cancelEv,
			ListSchedule:      listSchedule,
			ListSpeakers:      listSpeakers,
			GetSpeaker:        getSpeaker,
			CreateSessionExec: createSess,
			UpdateSessionExec: updateSess,
			CreateSpeakerExec: createSpk,
			UpdateSpeakerUC:   updateSpk,
			AttachSpeaker:     attachSpk,
			UpdateProfile:     updateProfile,
			GrantRole:         grantRole,
			RevokeRole:        revokeRole,
			AdminUsersExec:    adminUsers,
			MyRegs:            myRegs,
			AdminRegs:         adminRegs,
			CancelReg:         cancelReg,
			Notifier:          notifier,
		},
	}))

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.Handle("/playground", playground.Handler("GraphQL playground", "/graphql"))
	mux.Handle("/graphql", graphql.ActorMiddleware(verifier, userRepo, gqlSrv))

	api := http.NewServeMux()
	api.HandleFunc("POST /events/{eventID}/register", reg.RegisterForEvent)
	api.HandleFunc("GET /events/{eventID}/ticket", reg.MyTicket)
	api.HandleFunc("POST /events/{eventID}/checkin/qr", ch.CheckInByQR)
	api.HandleFunc("POST /registrations/{registrationID}/checkin/manual", ch.CheckInManual)

	mux.Handle("/v1/", http.StripPrefix("/v1", graphql.ActorMiddleware(verifier, userRepo, api)))

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	notifScheduler := notification.NewScheduler(notifier, eventRepo, sessionRepo, regRepo)
	notifScheduler.Start()

	go func() {
		log.Printf("listening on %s", cfg.HTTPAddr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	notifScheduler.Stop()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdownCtx)
}
