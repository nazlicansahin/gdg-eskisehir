.PHONY: generate generate-all test run

LOCAL_GO := ../.tools/go/bin/go
GO := $(if $(wildcard $(LOCAL_GO)),$(LOCAL_GO),go)

generate:
	PATH="$(CURDIR)/../.tools/go/bin:$$PATH" GOSUMDB=off go run github.com/99designs/gqlgen@v0.17.49 generate

generate-all: generate
	@echo "Run SDK generation pipeline here (dart/swift)."

test:
	$(GO) test ./...

run:
	$(GO) run ./cmd/server
