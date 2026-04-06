package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/jackc/pgx/v5"
)

type SessionRepository struct {
	db *DB
}

func NewSessionRepository(db *DB) *SessionRepository {
	return &SessionRepository{db: db}
}

func (r *SessionRepository) GetByID(ctx context.Context, id string) (*domain.Session, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, event_id::text, title, COALESCE(description, ''), COALESCE(room, ''), sort_order,
			starts_at, ends_at, created_at, updated_at
		FROM sessions
		WHERE id = $1::uuid
	`, id)
	return scanSession(row)
}

func scanSession(row pgx.Row) (*domain.Session, error) {
	var s domain.Session
	if err := row.Scan(
		&s.ID,
		&s.EventID,
		&s.Title,
		&s.Description,
		&s.Room,
		&s.SortOrder,
		&s.StartsAt,
		&s.EndsAt,
		&s.CreatedAt,
		&s.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return &s, nil
}

func (r *SessionRepository) ListByEventID(ctx context.Context, eventID string) ([]*domain.Session, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id::text, event_id::text, title, COALESCE(description, ''), COALESCE(room, ''), sort_order,
			starts_at, ends_at, created_at, updated_at
		FROM sessions
		WHERE event_id = $1::uuid
		ORDER BY sort_order ASC, starts_at ASC
	`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*domain.Session
	for rows.Next() {
		var s domain.Session
		if err := rows.Scan(
			&s.ID,
			&s.EventID,
			&s.Title,
			&s.Description,
			&s.Room,
			&s.SortOrder,
			&s.StartsAt,
			&s.EndsAt,
			&s.CreatedAt,
			&s.UpdatedAt,
		); err != nil {
			return nil, err
		}
		out = append(out, &s)
	}
	return out, rows.Err()
}

func (r *SessionRepository) Create(ctx context.Context, s *domain.Session) error {
	row := r.db.QueryRow(ctx, `
		INSERT INTO sessions (event_id, title, description, room, starts_at, ends_at, sort_order)
		VALUES ($1::uuid, $2, $3, $4, $5, $6, $7)
		RETURNING id::text, created_at, updated_at
	`, s.EventID, s.Title, nullIfEmpty(s.Description), nullString(s.Room), s.StartsAt, s.EndsAt, s.SortOrder)
	return row.Scan(&s.ID, &s.CreatedAt, &s.UpdatedAt)
}

func nullString(s string) any {
	if s == "" {
		return nil
	}
	return s
}

func (r *SessionRepository) Update(
	ctx context.Context,
	id string,
	title, description, room *string,
	startsAt, endsAt *time.Time,
) error {
	return r.db.Exec(ctx, `
		UPDATE sessions SET
			title = COALESCE($2, title),
			description = COALESCE($3, description),
			room = COALESCE($4, room),
			starts_at = COALESCE($5, starts_at),
			ends_at = COALESCE($6, ends_at),
			updated_at = now()
		WHERE id = $1::uuid
	`, id, title, description, room, startsAt, endsAt)
}

func (r *SessionRepository) ListSpeakerIDsForSession(ctx context.Context, sessionID string) ([]string, error) {
	rows, err := r.db.Query(ctx, `
		SELECT speaker_id::text
		FROM session_speakers
		WHERE session_id = $1::uuid
		ORDER BY speaker_id
	`, sessionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func (r *SessionRepository) AttachSpeaker(ctx context.Context, sessionID, speakerID string) error {
	return r.db.Exec(ctx, `
		INSERT INTO session_speakers (session_id, speaker_id)
		VALUES ($1::uuid, $2::uuid)
		ON CONFLICT DO NOTHING
	`, sessionID, speakerID)
}

var _ ports.SessionRepository = (*SessionRepository)(nil)
