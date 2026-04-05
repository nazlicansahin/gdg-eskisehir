package memory

import "context"

type UnitOfWork struct{}

func NewUnitOfWork() *UnitOfWork {
	return &UnitOfWork{}
}

func (u *UnitOfWork) WithinTx(ctx context.Context, fn func(ctx context.Context) error) error {
	return fn(ctx)
}
