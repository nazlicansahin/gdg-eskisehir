package graphql

import "github.com/gdg-eskisehir/events/backend/internal/domain"

type RegistrationTicket struct {
	ID          string
	EventID     string
	UserID      string
	Status      domain.RegistrationStatus
	QRCodeValue string
}

func toTicket(
	registrationID, eventID, userID, qrCode string,
	status domain.RegistrationStatus,
) *RegistrationTicket {
	return &RegistrationTicket{
		ID:          registrationID,
		EventID:     eventID,
		UserID:      userID,
		Status:      status,
		QRCodeValue: qrCode,
	}
}
