# syntax=docker/dockerfile:experimental

FROM --platform=$BUILDPLATFORM golang:1.12-alpine as dev
RUN apk add --no-cache git ca-certificates
RUN adduser -D appuser
WORKDIR /src
COPY . /src/
CMD CGO_ENABLED=0 go build -o app . && ./app

FROM --platform=$BUILDPLATFORM dev as build
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=cache,id=gomod,target=/go/pkg/mod/cache \
    --mount=type=cache,id=goroot,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags '-w -extldflags -static' -o app .
USER appuser
CMD [ "./app" ]

FROM scratch as release
# COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /src/app /app
COPY . /src/
USER appuser
CMD [ "/app" ]

FROM --platform=$BUILDPLATFORM debian as debug
COPY --from=build /src/app /app
CMD [ "/app" ]

FROM scratch as artifact
COPY --from=build /src/app /app

FROM release
