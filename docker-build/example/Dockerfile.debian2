FROM golang:1.12
RUN adduser --disabled-password --gecos appuser appuser
COPY . /src/
RUN cd /src \
 && go build -o app . \
 && cd / \
 && cp /src/app /app \
 && chown appuser /app \
 && chmod 755 /app \
 && rm -r /go/pkg /root/.cache/go-build /src
USER appuser
CMD [ "/app" ]

