FROM golang:1.23-alpine AS builder

WORKDIR /src

RUN apk add --no-cache ca-certificates tzdata

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/server ./cmd/server

FROM alpine:3.20

WORKDIR /src

RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /out/server /src/server
COPY --from=builder /src/schema /src/schema

EXPOSE 8080

ENTRYPOINT ["/src/server"]
