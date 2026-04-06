package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/registration"
	"github.com/gdg-eskisehir/events/backend/internal/interface/graphql"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type RegistrationHandlers struct {
	Register *registration.RegisterForEventUseCase
	Ticket   *registration.GetMyTicketUseCase
}

func (h *RegistrationHandlers) RegisterForEvent(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	eventID := r.PathValue("eventID")
	if err := pathUUID("eventId", eventID); err != nil {
		writeAPIError(w, err)
		return
	}
	actor, err := graphql.ActorFromContext(r.Context())
	if err != nil {
		writeAPIError(w, err)
		return
	}
	out, err := h.Register.Execute(r.Context(), registration.RegisterForEventInput{
		ActorUserID: actor.UserID,
		EventID:     eventID,
	})
	if err != nil {
		writeAPIError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{
		"registrationId": out.RegistrationID,
		"eventId":        out.EventID,
		"userId":         out.UserID,
		"status":         out.Status,
		"qrCodeValue":    out.QRCodeValue,
	})
}

func (h *RegistrationHandlers) MyTicket(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	eventID := r.PathValue("eventID")
	if err := pathUUID("eventId", eventID); err != nil {
		writeAPIError(w, err)
		return
	}
	actor, err := graphql.ActorFromContext(r.Context())
	if err != nil {
		writeAPIError(w, err)
		return
	}
	out, err := h.Ticket.Execute(r.Context(), registration.GetMyTicketInput{
		ActorUserID: actor.UserID,
		EventID:     eventID,
	})
	if err != nil {
		writeAPIError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"registrationId": out.RegistrationID,
		"eventId":        out.EventID,
		"userId":         out.UserID,
		"status":         out.Status,
		"qrCodeValue":    out.QRCodeValue,
	})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func writeAPIError(w http.ResponseWriter, err error) {
	code := sharedErrors.ToGraphQLCode(err)
	status := http.StatusInternalServerError
	switch code {
	case sharedErrors.CodeUnauthenticated:
		status = http.StatusUnauthorized
	case sharedErrors.CodeForbidden:
		status = http.StatusForbidden
	case sharedErrors.CodeNotFound:
		status = http.StatusNotFound
	case sharedErrors.CodeValidationFailed:
		status = http.StatusBadRequest
	case sharedErrors.CodeConflict, sharedErrors.CodeCapacityReached, sharedErrors.CodeAlreadyCheckedIn:
		status = http.StatusConflict
	default:
		status = http.StatusInternalServerError
	}
	writeJSON(w, status, map[string]any{
		"error": map[string]any{
			"code":    code,
			"message": err.Error(),
		},
	})
}
