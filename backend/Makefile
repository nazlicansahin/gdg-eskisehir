.PHONY: generate generate-all test

LOCAL_GO := ../.tools/go/bin/go
GO := $(if $(wildcard $(LOCAL_GO)),$(LOCAL_GO),go)

generate:
	@echo "Run gqlgen generation here (configure when gqlgen is wired)."

generate-all: generate
	@echo "Run SDK generation pipeline here (dart/swift)."

test:
	$(GO) test ./...
