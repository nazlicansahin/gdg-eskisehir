package gqlserver

import (
	"os"
	"path/filepath"
	"runtime"

	"github.com/vektah/gqlparser/v2"
	"github.com/vektah/gqlparser/v2/ast"
)

// LoadSchema loads schema/graphql/schema.graphqls relative to the backend module root.
func LoadSchema() (*ast.Schema, error) {
	_, thisFile, _, _ := runtime.Caller(0)
	// internal/gqlserver/schema.go -> backend root is two levels up from internal/gqlserver
	backendRoot := filepath.Join(filepath.Dir(thisFile), "..", "..")
	path := filepath.Join(backendRoot, "schema", "graphql", "schema.graphqls")
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return gqlparser.LoadSchema(&ast.Source{Name: "schema.graphqls", Input: string(b)})
}
