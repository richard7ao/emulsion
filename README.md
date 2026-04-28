# emulsion

**TLDR:** A native iOS portfolio app backed by a Rust API, built in a Bazel monorepo. Polaroid/film aesthetic. The engineering choices are the point — monorepo layout, Rust backend, Bazel build, agent-friendly structure.

## What it is

Richard Lao's personal portfolio, delivered as a working end-to-end system:

- **iOS** — SwiftUI, iOS 17+, polaroid-card layout, no third-party deps
- **Rust** — Axum + SQLite, async, in-memory read cache, local HTTP
- **Bazel** — single build graph across iOS and Rust

## Structure

```
apps/ios/              SwiftUI app
services/portfolio-api/ Rust API server
tools/seed/            DB seeder (CV content → SQLite)
shared/schemas/        Shared type definitions (extension point)
```

## Run

```bash
cargo run -p seed              # seed the database
cargo run -p portfolio-api     # start the server
open apps/ios/Emulsion.xcodeproj
```

See [prd.md](prd.md) for full product spec.
