# Emulsion

## Build

```bash
# Full stack (macOS)
./run.sh

# Backend only
cargo run -p portfolio-api

# Seed database (creates DB + runs migrations automatically)
cargo run -p seed

# iOS (Xcode)
open apps/ios/PortfolioApp.xcodeproj  # Cmd+R for Simulator

# Bazel
bazel build //services/portfolio-api:server
bazel build //apps/ios:app
bazel build //shared/emulsion-types:emulsion_types
```

## Test

```bash
cargo test                    # All Rust tests (31: 27 backend + 4 shared types)
cargo test -p portfolio-api   # Backend only
cargo test -p emulsion-types  # Shared types only
```

## Architecture

- `apps/ios/` — SwiftUI, MVVM with @Observable, URLSession networking
- `services/portfolio-api/` — Rust axum 0.7.9, SQLite WAL, DashMap cache
- `shared/emulsion-types/` — UniFFI 0.28, domain types defined in Rust, Swift bindings generated
- `tools/seed/` — Populates SQLite from embedded CV JSON

## Conventions

- Handlers: extract AppState → call repo → return `Result<Json<T>, AppError>` (see `src/error.rs`)
- Views: View → ViewModel (@Observable) → APIClient call
- Counters: atomic SQL `UPDATE SET col = col + 1` (never read-modify-write)
- Theme: all colors/fonts via LapseTheme (never hardcoded)
- Naming: `*_handler.rs`, `*_repo.rs`, `*View.swift`, `*ViewModel.swift`

## Adding Things

- **New API endpoint:** handler in `src/handlers/`, repo in `src/repositories/`, route in `src/routes/mod.rs`
- **New iOS screen:** View in `Sources/Views/`, ViewModel in `Sources/ViewModels/`
- **New data model:** Rust struct in `shared/emulsion-types/src/lib.rs` + UDL, re-generate bindings
- **New Bazel target:** BUILD file in the package directory
