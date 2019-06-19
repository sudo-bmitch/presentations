FROM golang:1.12-alpine as dev
RUN apk add --no-cache git ca-certificates
RUN adduser -D appuser
WORKDIR /src
COPY . /src/
CMD CGO_ENABLED=0 go build -o app . && ./app

FROM dev as build
RUN CGO_ENABLED=0 go build -o app .
USER appuser
CMD [ "./app" ]

FROM scratch as release
# COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /src/app /app
USER appuser
CMD [ "/app" ]

FROM debian as debug
COPY --from=build /src/app /app
CMD [ "/app" ]

FROM release
