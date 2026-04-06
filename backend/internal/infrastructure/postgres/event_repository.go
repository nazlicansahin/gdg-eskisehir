package postgres

import (
	"context"
	"errors"
	"strconv"
	"time"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
	"github.com/gdg-eskisehir/events/backend/internal/domain"
	"github.com/jackc/pgx/v5"
)

type EventRepository struct {
	db *DB
}

func NewEventRepository(db *DB) *EventRepository {
	return &EventRepository{db: db}
}

func scanEvent(row pgx.Row) (*domain.Event, error) {
	var ev domain.Event
	var status string
	if err := row.Scan(
		&ev.ID,
		&ev.Title,
		&ev.Description,
		&status,
		&ev.Capacity,
		&ev.StartsAt,
		&ev.EndsAt,
		&ev.CreatedAt,
		&ev.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	ev.Status = domain.EventStatus(status)
	return &ev, nil
}

func (r *EventRepository) GetByID(ctx context.Context, eventID string) (*domain.Event, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id::text, title, COALESCE(description, ''), status, capacity, starts_at, ends_at, created_at, updated_at
		FROM events
		WHERE id = $1::uuid
	`, eventID)
	return scanEvent(row)
}

func (r *EventRepository) GetRegistrationCount(ctx context.Context, eventID string) (int, error) {
	row := r.db.QueryRow(ctx, `
		SELECT COUNT(*)::int
		FROM registrations
		WHERE event_id = $1::uuid AND status = 'active'
	`, eventID)

	var count int
	if err := row.Scan(&count); err != nil {
		return 0, err
	}
	return count, nil
}

func (r *EventRepository) List(ctx context.Context, filter ports.EventListFilter) ([]*domain.Event, error) {
	q := `
		SELECT id::text, title, COALESCE(description, ''), status, capacity, starts_at, ends_at, created_at, updated_at
		FROM events
		WHERE 1=1
	`
	args := []any{}
	if filter.PublishedOnly {
		q += ` AND status = 'published'`
	}
	if filter.Status != nil {
		args = append(args, string(*filter.Status))
		q += ` AND status = $` + strconv.Itoa(len(args))
	}
	q += ` ORDER BY starts_at ASC`

	rows, err := r.db.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*domain.Event
	for rows.Next() {
		var ev domain.Event
		var status string
		if err := rows.Scan(
			&ev.ID,
			&ev.Title,
			&ev.Description,
			&status,
			&ev.Capacity,
			&ev.StartsAt,
			&ev.EndsAt,
			&ev.CreatedAt,
			&ev.UpdatedAt,
		); err != nil {
			return nil, err
		}
		ev.Status = domain.EventStatus(status)
		out = append(out, &ev)
	}
	return out, rows.Err()
}

func (r *EventRepository) Insert(ctx context.Context, e *domain.Event) error {
	row := r.db.QueryRow(ctx, `
		INSERT INTO events (title, description, status, capacity, starts_at, ends_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id::text, created_at, updated_at
	`, e.Title, nullIfEmpty(e.Description), string(e.Status), e.Capacity, e.StartsAt, e.EndsAt)
	return row.Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func nullIfEmpty(s string) any {
	if s == "" {
		return nil
	}
	return s
}

func (r *EventRepository) Update(
	ctx context.Context,
	id string,
	title, description *string,
	capacity *int,
	startsAt, endsAt *time.Time,
) error {
	return r.db.Exec(ctx, `
		UPDATE events SET
			title = COALESCE($2, title),
			description = COALESCE($3, description),
			capacity = COALESCE($4, capacity),
			starts_at = COALESCE($5, starts_at),
			ends_at = COALESCE($6, ends_at),
			updated_at = now()
		WHERE id = $1::uuid
	`, id, title, description, capacity, startsAt, endsAt)
}

func (r *EventRepository) SetStatus(ctx context.Context, id string, status domain.EventStatus) error {
	return r.db.Exec(ctx, `
		UPDATE events SET status = $2, updated_at = now() WHERE id = $1::uuid
	`, id, string(status))
}

var _ ports.EventRepository = (*EventRepository)(nil)
