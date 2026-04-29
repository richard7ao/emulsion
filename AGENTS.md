# Agent Conventions

This repo is structured so AI coding agents can orient quickly, find the right files, and follow established patterns. Consistent naming, flat module structure, and explicit conventions make it possible for an agent to contribute without reading every file first.

## Directory Map

| Path | Purpose |
|------|---------|
| `apps/ios/` | SwiftUI iOS app (iOS 26, MVVM, @Observable) |
| `services/portfolio-api/` | Rust axum backend (port 8080, SQLite) |
| `shared/emulsion-types/` | UniFFI shared types — Rust definitions + generated Swift bindings |
| `tools/seed/` | Rust binary to populate SQLite from CV data |
| `docs/` | System design, test plan, retrospective |

## Naming Conventions

| Pattern | Where | Example |
|---------|-------|---------|
| `*_handler.rs` | `services/portfolio-api/src/handlers/` | `portfolio_handler.rs` |
| `*_repo.rs` | `services/portfolio-api/src/repositories/` | `portfolio_repo.rs` |
| `*View.swift` | `apps/ios/Sources/Views/` | `PortfolioHomeView.swift` |
| `*ViewModel.swift` | `apps/ios/Sources/ViewModels/` | `PortfolioViewModel.swift` |

## Patterns

- All Rust handlers: extract AppState → call repo → map error → return Json
- All SwiftUI views: View → ViewModel (@Observable) → APIClient call
- Counter updates: atomic SQL `UPDATE SET col = col + 1` (never read-modify-write)
- Colors/fonts/spacing: always via LapseTheme (never hardcoded in Views)
- Polaroid card rotation: seeded by item index (never random)

## Build & Test

```bash
# Build
cargo build --workspace              # All Rust crates
bazel build //services/portfolio-api:server
bazel build //apps/ios:app
bazel build //shared/emulsion-types:emulsion_types

# Test
cargo test --workspace               # All Rust tests (26 total)
cargo test -p portfolio-api           # Backend only (22 tests)
cargo test -p emulsion-types          # Shared types (4 tests)
```

## Common Tasks

### Add a new API endpoint

1. Create handler function in `services/portfolio-api/src/handlers/<entity>_handler.rs`
2. Create repository function in `services/portfolio-api/src/repositories/<entity>_repo.rs`
3. Add route in `services/portfolio-api/src/routes/mod.rs`
4. Add test in the repository file (`#[cfg(test)]` module)

### Add a new iOS screen

1. Create `<Name>View.swift` in `apps/ios/Sources/Views/`
2. Create `<Name>ViewModel.swift` in `apps/ios/Sources/ViewModels/`
3. Add PBXFileReference, PBXBuildFile, and PBXGroup entries in `project.pbxproj`

### Add a new shared type

1. Add Rust struct to `shared/emulsion-types/src/lib.rs` with `#[derive(Serialize, Deserialize)]`
2. Add UDL definition to `shared/emulsion-types/src/emulsion_types.udl`
3. Run `./shared/emulsion-types/generate-bindings.sh` to regenerate Swift bindings
4. Update iOS `Models.swift` if the app consumes the type via HTTP
5. Update backend model file if the type maps to a database table

### Run full verification

```bash
cargo test --workspace                   # Rust tests pass
bazel build //services/portfolio-api:server //apps/ios:app //shared/emulsion-types:emulsion_types  # Bazel builds
xcodebuild build -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp -destination 'platform=iOS Simulator,name=iPhone 16'  # Xcode builds
```
