package postgres

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type txCtxKey struct{}

func WithTx(ctx context.Context, tx pgx.Tx) context.Context {
	return context.WithValue(ctx, txCtxKey{}, tx)
}

func TxFromContext(ctx context.Context) (pgx.Tx, bool) {
	tx, ok := ctx.Value(txCtxKey{}).(pgx.Tx)
	return tx, ok
}

// DB routes queries to an active transaction when present in context.
type DB struct {
	Pool *pgxpool.Pool
}

func (db *DB) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	if tx, ok := TxFromContext(ctx); ok {
		return tx.QueryRow(ctx, sql, args...)
	}
	return db.Pool.QueryRow(ctx, sql, args...)
}

func (db *DB) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	if tx, ok := TxFromContext(ctx); ok {
		return tx.Query(ctx, sql, args...)
	}
	return db.Pool.Query(ctx, sql, args...)
}

func (db *DB) Exec(ctx context.Context, sql string, args ...any) error {
	var err error
	if tx, ok := TxFromContext(ctx); ok {
		_, err = tx.Exec(ctx, sql, args...)
	} else {
		_, err = db.Pool.Exec(ctx, sql, args...)
	}
	return err
}
