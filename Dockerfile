FROM golang:1.26-bookworm AS build
WORKDIR /src
COPY emulator/go.mod emulator/go.sum ./
RUN go mod download
COPY emulator/ ./
RUN CGO_ENABLED=0 go build -trimpath -o /out/masterserver ./cmd/masterserver && \
    CGO_ENABLED=0 go build -trimpath -o /out/loginserver ./cmd/loginserver && \
    CGO_ENABLED=0 go build -trimpath -o /out/gameserver ./cmd/gameserver && \
    CGO_ENABLED=0 go build -trimpath -o /out/localaccount ./cmd/localaccount

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends python3 ca-certificates && \
    rm -rf /var/lib/apt/lists/* && useradd --uid 10001 --create-home cabal
WORKDIR /app
COPY --from=build /out/ /app/bin/
COPY emulator/cfg/ /app/templates/
COPY emulator/data/ /app/data/
COPY emulator/script/ /app/script/
COPY docker/entrypoint.py docker/healthcheck.py /app/
RUN mkdir /app/cfg /app/log && chown -R cabal:cabal /app/cfg /app/log
USER cabal
ENTRYPOINT ["python3", "/app/entrypoint.py"]
