package postgres

import (
	"context"

	"github.com/gdg-eskisehir/events/backend/internal/application/ports"
)

type UnitOfWork struct {
	db *DB
}

func NewUnitOfWork(db *DB) *UnitOfWork {
	return &UnitOfWork{db: db}
}

func (u *UnitOfWork) WithinTx(ctx context.Context, fn func(ctx context.Context) error) error {
	tx, err := u.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	ctx = WithTx(ctx, tx)
	if err := fn(ctx); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

var _ ports.UnitOfWork = (*UnitOfWork)(nil)
