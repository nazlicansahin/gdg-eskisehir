package postgres

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type AnnouncementRepository struct {
	db *DB
}

func NewAnnouncementRepository(db *DB) *AnnouncementRepository {
	return &AnnouncementRepository{db: db}
}

func (r *AnnouncementRepository) Create(ctx context.Context, a *domain.Announcement) error {
	return r.db.Pool.QueryRow(ctx, `
		INSERT INTO announcements (event_id, title, body, created_by)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`, a.EventID, a.Title, a.Body, a.CreatedBy).Scan(&a.ID, &a.CreatedAt)
}

func (r *AnnouncementRepository) ListByEventID(ctx context.Context, eventID string) ([]*domain.Announcement, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, event_id, title, body, created_by, created_at
		FROM announcements WHERE event_id = $1
		ORDER BY created_at DESC
	`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanAnnouncements(rows)
}

func (r *AnnouncementRepository) ListGeneral(ctx context.Context) ([]*domain.Announcement, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, event_id, title, body, created_by, created_at
		FROM announcements WHERE event_id IS NULL
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanAnnouncements(rows)
}

func (r *AnnouncementRepository) ListAll(ctx context.Context) ([]*domain.Announcement, error) {
	rows, err := r.db.Pool.Query(ctx, `
		SELECT id, event_id, title, body, created_by, created_at
		FROM announcements
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanAnnouncements(rows)
}

type scannable interface {
	Scan(dest ...any) error
	Next() bool
}

func scanAnnouncements(rows scannable) ([]*domain.Announcement, error) {
	var out []*domain.Announcement
	for rows.Next() {
		var a domain.Announcement
		var eid pgtype.UUID
		if err := rows.Scan(&a.ID, &eid, &a.Title, &a.Body, &a.CreatedBy, &a.CreatedAt); err != nil {
			return nil, err
		}
		if eid.Valid {
			u, err := uuid.FromBytes(eid.Bytes[:])
			if err != nil {
				return nil, err
			}
			s := u.String()
			a.EventID = &s
		}
		out = append(out, &a)
	}
	return out, nil
}
