# Portfolio API

Rust axum backend serving the portfolio data over HTTP/JSON on port 8080.

## Build

```bash
# Cargo (development)
cargo build -p portfolio-api

# Bazel
bazel build //services/portfolio-api:server
```

## Run

```bash
DATABASE_URL=sqlite:./dev.db cargo run -p portfolio-api
curl http://localhost:8080/health
```

## Test

```bash
cargo test -p portfolio-api -- --test-threads=1
```
