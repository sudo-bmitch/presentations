FROM golang:1.12-alpine as build
RUN apk add --no-cache git ca-certificates
RUN adduser -D appuser
WORKDIR /src
COPY . /src/
RUN go build -o app .
USER appuser
CMD [ "/src/app" ]

FROM scratch as release
COPY --from=build /src/app /app
USER appuser
CMD [ "/app" ]

