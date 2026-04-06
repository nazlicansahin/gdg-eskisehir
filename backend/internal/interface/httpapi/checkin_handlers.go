package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/gdg-eskisehir/events/backend/internal/application/usecase/checkin"
	"github.com/gdg-eskisehir/events/backend/internal/interface/graphql"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
)

type CheckinHandlers struct {
	QR     *checkin.CheckInByQRUseCase
	Manual *checkin.CheckInManualUseCase
}

type checkInQRBody struct {
	QRCode string `json:"qrCode"`
}

func (h *CheckinHandlers) CheckInByQR(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	eventID := r.PathValue("eventID")
	if err := pathUUID("eventId", eventID); err != nil {
		writeAPIError(w, err)
		return
	}
	var body checkInQRBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.QRCode == "" {
		writeAPIError(w, sharedErrors.ErrValidation)
		return
	}
	actor, err := graphql.ActorFromContext(r.Context())
	if err != nil {
		writeAPIError(w, err)
		return
	}
	out, err := h.QR.Execute(r.Context(), checkin.CheckInByQRInput{
		ActorUserID: actor.UserID,
		ActorRole:   actor.Role,
		EventID:     eventID,
		QRCode:      body.QRCode,
	})
	if err != nil {
		writeAPIError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"registrationId": out.RegistrationID,
		"eventId":        out.EventID,
		"status":         out.Status,
	})
}

func (h *CheckinHandlers) CheckInManual(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	registrationID := r.PathValue("registrationID")
	if err := pathUUID("registrationId", registrationID); err != nil {
		writeAPIError(w, err)
		return
	}
	actor, err := graphql.ActorFromContext(r.Context())
	if err != nil {
		writeAPIError(w, err)
		return
	}
	out, err := h.Manual.Execute(r.Context(), checkin.CheckInManualInput{
		ActorUserID:    actor.UserID,
		ActorRole:      actor.Role,
		RegistrationID: registrationID,
	})
	if err != nil {
		writeAPIError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"registrationId": out.RegistrationID,
		"eventId":        out.EventID,
		"status":         out.Status,
	})
}
