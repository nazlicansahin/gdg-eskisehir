package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	sharedErrors "github.com/gdg-eskisehir/events/backend/shared/errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type RegistrationRepository struct {
	db *DB
}

func NewRegistrationRepository(db *DB) *RegistrationRepository {
	return &RegistrationRepository{db: db}
}

func (r *RegistrationRepository) scanRegistration(row pgx.Row) (*domain.Registration, error) {
	var reg domain.Registration
	var status string
	var checkedInAt, cancelledAt *time.Time
	var cancelReason *string

	if err := row.Scan(
		&reg.ID,
		&reg.EventID,
		&reg.UserID,
		&status,
		&reg.QRCodeValue,
		&checkedInAt,
		&cancelReason,
		&cancelledAt,
		&reg.CreatedAt,
		&reg.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	reg.Status = domain.RegistrationStatus(status)
	reg.CheckedInAt = checkedInAt
	reg.CancelledAt = cancelledAt
	reg.CancelReason = cancelReason
	return &reg, nil
}

func (r *RegistrationRepository) GetRegistrationByID(ctx context.Context, id string) (*domain.Registration, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, event_id::text, user_id::text, status, qr_code_value, checked_in_at, cancelled_reason, cancelled_at, created_at, updated_at
		FROM registrations
		WHERE id = $1::uuid
	`, id)
	return r.scanRegistration(row)
}

func (r *RegistrationRepository) GetByEventAndUser(
	ctx context.Context,
	eventID, userID string,
) (*domain.Registration, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, event_id::text, user_id::text, status, qr_code_value, checked_in_at, cancelled_reason, cancelled_at, created_at, updated_at
		FROM registrations
		WHERE event_id = $1::uuid AND user_id = $2::uuid
	`, eventID, userID)
	return r.scanRegistration(row)
}

func (r *RegistrationRepository) GetByEventAndQRCode(
	ctx context.Context,
	eventID, qrCode string,
) (*domain.Registration, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, event_id::text, user_id::text, status, qr_code_value, checked_in_at, cancelled_reason, cancelled_at, created_at, updated_at
		FROM registrations
		WHERE event_id = $1::uuid AND qr_code_value = $2
	`, eventID, qrCode)
	return r.scanRegistration(row)
}

func (r *RegistrationRepository) Create(ctx context.Context, registration *domain.Registration) error {
	row := r.db.QueryRow(ctx, `
		INSERT INTO registrations (event_id, user_id, status, qr_code_value)
		VALUES ($1::uuid, $2::uuid, $3, $4)
		RETURNING id::text, created_at, updated_at
	`, registration.EventID, registration.UserID, string(registration.Status), registration.QRCodeValue)

	if err := row.Scan(&registration.ID, &registration.CreatedAt, &registration.UpdatedAt); err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			return sharedErrors.ErrAlreadyRegistered
		}
		return err
	}
	return nil
}

func (r *RegistrationRepository) CompleteCheckIn(
	ctx context.Context,
	registrationID, eventID, checkedInByUserID, method string,
) error {
	row := r.db.QueryRow(ctx, `
		UPDATE registrations
		SET checked_in_at = now(), updated_at = now()
		WHERE id = $1::uuid AND event_id = $2::uuid AND status = 'active' AND checked_in_at IS NULL
		RETURNING id::text
	`, registrationID, eventID)

	var id string
	if err := row.Scan(&id); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			reg, errGet := r.GetRegistrationByID(ctx, registrationID)
			if errGet != nil {
				return errGet
			}
			if reg == nil {
				return sharedErrors.ErrNotFound
			}
			if reg.EventID != eventID {
				return sharedErrors.ErrInvalidQRCode
			}
			if reg.Status == domain.RegistrationStatusCancelled {
				return sharedErrors.ErrRegistrationCancelled
			}
			if reg.CheckedInAt != nil {
				return sharedErrors.ErrAlreadyCheckedIn
			}
			return sharedErrors.ErrNotFound
		}
		return err
	}

	return r.db.Exec(ctx, `
		INSERT INTO checkins (registration_id, event_id, method, checked_in_by)
		VALUES ($1::uuid, $2::uuid, $3, $4::uuid)
	`, registrationID, eventID, method, checkedInByUserID)
}

func (r *RegistrationRepository) ListByUserID(ctx context.Context, userID string) ([]*domain.Registration, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id::text, event_id::text, user_id::text, status, qr_code_value, checked_in_at, cancelled_reason, cancelled_at, created_at, updated_at
		FROM registrations
		WHERE user_id = $1::uuid
		ORDER BY created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return r.scanRegistrationRows(rows)
}

func (r *RegistrationRepository) ListByEventID(ctx context.Context, eventID string) ([]*domain.Registration, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id::text, event_id::text, user_id::text, status, qr_code_value, checked_in_at, cancelled_reason, cancelled_at, created_at, updated_at
		FROM registrations
		WHERE event_id = $1::uuid
		ORDER BY created_at ASC
	`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return r.scanRegistrationRows(rows)
}

func (r *RegistrationRepository) scanRegistrationRows(rows pgx.Rows) ([]*domain.Registration, error) {
	var out []*domain.Registration
	for rows.Next() {
		reg, err := r.scanRegistration(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, reg)
	}
	return out, rows.Err()
}

func (r *RegistrationRepository) Cancel(ctx context.Context, registrationID, reason string) error {
	row := r.db.QueryRow(ctx, `
		UPDATE registrations
		SET status = 'cancelled', cancelled_reason = $2, cancelled_at = now(), updated_at = now()
		WHERE id = $1::uuid AND status = 'active'
		RETURNING id::text
	`, registrationID, reason)
	var id string
	if err := row.Scan(&id); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			reg, errGet := r.GetRegistrationByID(ctx, registrationID)
			if errGet != nil {
				return errGet
			}
			if reg == nil {
				return sharedErrors.ErrNotFound
			}
			if reg.Status == domain.RegistrationStatusCancelled {
				return sharedErrors.ErrConflict
			}
			return sharedErrors.ErrNotFound
		}
		return err
	}
	return nil
}

var _ ports.RegistrationRepository = (*RegistrationRepository)(nil)
