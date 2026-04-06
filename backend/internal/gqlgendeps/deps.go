// Package gqlgendeps holds blank imports so gqlgen stays in go.mod (go mod tidy).
package gqlgendeps

import (
	_ "github.com/99designs/gqlgen/graphql"
	_ "github.com/99designs/gqlgen/graphql/handler"
	_ "github.com/99designs/gqlgen/graphql/playground"
)
