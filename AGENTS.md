# Agent Conventions

## Directory Map

| Path | Purpose |
|------|---------|
| `apps/ios/` | SwiftUI iOS app (iOS 26, MVVM, @Observable) |
| `services/portfolio-api/` | Rust axum backend (port 8080, SQLite) |
| `shared/schemas/` | Shared type definitions (extension point) |
| `tools/seed/` | Rust binary to populate SQLite from CV data |
| `docs/` | System design, test plan, retrospective |
| `tasks/state.json` | Build progress tracker |

## Naming Conventions

| Pattern | Where | Example |
|---------|-------|---------|
| `*_handler.rs` | `services/portfolio-api/src/handlers/` | `portfolio_handler.rs` |
| `*_repo.rs` | `services/portfolio-api/src/repositories/` | `portfolio_repo.rs` |
| `*View.swift` | `apps/ios/Sources/Views/` | `PortfolioHomeView.swift` |
| `*ViewModel.swift` | `apps/ios/Sources/ViewModels/` | `PortfolioViewModel.swift` |

## Where to Add Things

- **New API endpoint:** handler in `src/handlers/`, repo in `src/repositories/`, route in `src/routes/mod.rs`
- **New iOS screen:** View in `Sources/Views/`, ViewModel in `Sources/ViewModels/`
- **New data model:** Rust struct in `src/models/`, Swift Codable in `Sources/Models/`
- **New Bazel target:** BUILD file in the package directory

## Conventions

- All Rust handlers: extract AppState -> call repo -> map error -> return Json
- All SwiftUI views: View -> ViewModel (@Observable) -> APIClient call
- Counter updates: atomic SQL `UPDATE SET col = col + 1` (never read-modify-write)
- Colors/fonts/spacing: always via LapseTheme (never hardcoded in Views)
- Polaroid card rotation: seeded by item index (never random)
