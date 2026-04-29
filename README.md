<div align="center">

# emulsion

**A native iOS portfolio app, backed by a Rust API server, built in a Bazel monorepo.**

*The light-sensitive layer where an image takes permanent form.*

[![Rust](https://img.shields.io/badge/Rust-1.95-CE412B?logo=rust&logoColor=white&style=flat-square)](https://www.rust-lang.org)
[![Swift](https://img.shields.io/badge/Swift-6-FA7343?logo=swift&logoColor=white&style=flat-square)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26-000000?logo=apple&logoColor=white&style=flat-square)](https://developer.apple.com/ios/)
[![axum](https://img.shields.io/badge/axum-0.7.9-7B1FA2?style=flat-square)](https://github.com/tokio-rs/axum)
[![SQLite](https://img.shields.io/badge/SQLite-WAL-003B57?logo=sqlite&logoColor=white&style=flat-square)](https://www.sqlite.org)
[![Bazel](https://img.shields.io/badge/Bazel-9.1.0-43A047?logo=bazel&logoColor=white&style=flat-square)](https://bazel.build)
[![tests](https://img.shields.io/badge/tests-44_passing-success?style=flat-square)](#testing)

<br />

<table>
<tr>
<td><img src="docs/screenshots/tldr-card.png" width="280" alt="TLDR Card" /></td>
<td><img src="docs/screenshots/inbox.png" width="280" alt="Inbox" /></td>
</tr>
</table>

</div>

---

## Why

A 24-hour take-home exercise to build a working iOS + Rust + Bazel monorepo, seeded with real CV content. The app is a usable artifact, not throwaway code — the goal is a foundation that explains itself.

## Highlights

- **End-to-end working system.** SwiftUI iOS app talks to a Rust axum service over local HTTP/JSON. Every screen hits a real backend.
- **Shared platform layer.** A `shared/emulsion-types` Rust crate defines the canonical wire types; the backend's `get_portfolio` handler returns `Json<emulsion_types::PortfolioResponse>`. Schema drift is a compile error, not a runtime surprise.
- **Latency-conscious backend.** WAL-mode SQLite tuned with `synchronous = NORMAL`, `busy_timeout = 5s`, `foreign_keys = ON`, 16 MB cache, B-tree indexes on every FK column. Release profile uses thin LTO, single codegen unit, stripped symbols.
- **Cache-aside reads.** `DashMap` lock-free in-process cache with prefix invalidation. Keys live in a typed `cache::keys` module to avoid stringly-typed mistakes.
- **Bazel builds both sides.** `bazel build //services/portfolio-api:server` and `bazel build //apps/ios:app` produce binary + IPA. `bazel test //...` runs the Rust test suite (UniFFI scaffolding gated behind a feature flag so the shared crate is sandbox-buildable).
- **Tests that go through the router.** 22 backend tests including 5 HTTP-level integration tests via `tower::ServiceExt::oneshot`. iOS ViewModels are mocked through `APIClientProtocol` (18 iOS tests). Shared types have a wire-format regression guard.
- **Agent-ready.** [`AGENTS.md`](AGENTS.md) documents conventions, file layout, and patterns for AI coding agents to navigate without reading every file first.

## Architecture

```mermaid
flowchart LR
    subgraph iOS["iOS Client (SwiftUI · iOS 26)"]
        VM["@Observable ViewModels"] --> API["APIClientProtocol"]
    end

    subgraph Backend["Rust Backend (axum 0.7.9)"]
        Router["Router + TraceLayer"] --> Handlers
        Handlers --> Repos["Repositories"]
        Handlers --> Cache["DashMap cache"]
        Repos --> SQLite[("SQLite WAL")]
    end

    Shared["shared/emulsion-types<br/>(canonical wire types)"]

    API <-->|"HTTP/JSON · localhost:8080"| Router
    Backend -. "use emulsion_types::*" .-> Shared
    iOS -. "Codable mirrors" .-> Shared
```

**Read path.** `PortfolioViewModel.load()` → `URLSession` → `GET /v1/portfolios/1` → cache check → `tokio::join!` over portfolio + experiences + skills → typed `PortfolioResponse` → SwiftUI re-render.

**Write path (project view).** `POST /v1/projects/:id/view` → atomic `UPDATE … SET col = col + 1` → `cache.invalidate_prefix("projects:")`. `GET /v1/projects/:id` is pure and cacheable; the side-effecting view increment lives on its own POST.

See [`docs/system-design.md`](docs/system-design.md) for the full design.

## Stack

| Layer | Tech | Notes |
|---|---|---|
| **iOS** | SwiftUI · iOS 26 · MVVM with `@Observable` | Zero third-party deps. `URLSession` networking. `LapseTheme` enum for visual constants. |
| **Backend** | Rust 1.95 · axum 0.7.9 · sqlx 0.8 | Single-binary tokio server. SQLite WAL. `tower-http` `TraceLayer` for per-request logs. |
| **Shared** | UniFFI 0.28 · feature-gated | Wire types defined once in Rust. UDL schema → Swift xcframework via `generate-bindings.sh`. |
| **Build** | Bazel 9.1.0 (Bzlmod) · Cargo workspace · Xcode | `rules_rust 0.70`, `rules_apple 4.5.3`, `rules_swift 3.6.1`. |
| **Aesthetic** | Polaroid/film | Warm off-whites, grain overlay, editorial serif. Code-only — no asset catalog. |

## Project structure

```
emulsion/
├── apps/ios/                  SwiftUI app · MVVM · APIClientProtocol
│   ├── Sources/               Views, ViewModels, APIClient, Models, Theme
│   ├── Tests/                 XCTest · 18 tests · MockAPIClient
│   └── PortfolioApp.xcodeproj Hand-rolled pbxproj (no SPM)
├── services/portfolio-api/    Rust axum backend · port 8080
│   ├── src/handlers/          extract → repo → map error → Json
│   ├── src/repositories/      SQL queries, atomic counter updates
│   ├── src/routes/tests.rs    HTTP integration tests via tower::ServiceExt
│   ├── migrations/            sqlx migrations (schema · counters · FK indexes)
│   └── BUILD                  bazel rust_binary + rust_test
├── shared/emulsion-types/     UniFFI Rust crate · wire types · feature-gated FFI
├── tools/seed/                Populates SQLite from embedded CV JSON
├── docs/
│   ├── system-design.md       Architecture, cache, latency, shared layer
│   ├── retrospective.md       Decisions, tradeoffs, post-script
│   └── test-plan.md           Coverage by tier
├── AGENTS.md                  Conventions for AI coding agents
└── run.sh                     macOS one-shot: prereqs → seed → build → run
```

## Quick start

### macOS — full stack

```bash
./run.sh                                     # prereqs check, seed, build, start backend
open apps/ios/PortfolioApp.xcodeproj          # ⌘R to run on iPhone 17 Pro Simulator
```

<details>
<summary><b>Bazel build (canonical monorepo build)</b></summary>

```bash
bazel build //services/portfolio-api:server   # Rust binary
bazel build //apps/ios:app                    # iOS .ipa
bazel build //shared/emulsion-types:emulsion_types
bazel test //...                              # Run all bazel-discoverable tests
```

</details>

<details>
<summary><b>Manual (Cargo + Xcode)</b></summary>

```bash
cargo run -p seed                             # creates dev.db, applies migrations, seeds CV
cargo run -p portfolio-api                    # starts on http://localhost:8080
open apps/ios/PortfolioApp.xcodeproj
```

</details>

<details>
<summary><b>Windows (backend only)</b></summary>

```
run.bat
```

iOS requires macOS + Xcode.

</details>

## API

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Liveness check |
| `GET` | `/v1/portfolios/:id` | Portfolio + experiences + skills (typed `PortfolioResponse`) |
| `POST` | `/v1/portfolios/:id/view` | Increment portfolio view count |
| `POST` | `/v1/portfolios/:id/interested` | Increment portfolio interest count |
| `GET` | `/v1/portfolios/:id/projects` | Project list |
| `GET` | `/v1/projects/:id` | Project detail (pure, cacheable) |
| `POST` | `/v1/projects/:id/view` | Increment project view count |
| `POST` | `/v1/projects/:id/interested` | Increment project interest count |
| `GET` | `/v1/portfolios/:id/qa` | Canned FAQ pairs |
| `POST` | `/v1/portfolios/:id/qa/ask` | Fuzzy-match Q&A |
| `POST` | `/v1/portfolios/:id/ama` | Submit a free-form AMA question |
| `POST` | `/v1/portfolios/:id/notes` | Leave a note |
| `GET` | `/v1/portfolios/:id/notes` | List notes (requires `X-Owner-Token`) |
| `GET` | `/v1/portfolios/:id/conversations` | Inbox conversations |
| `GET` | `/v1/conversations/:id/messages` | Conversation thread |
| `POST` | `/v1/conversations/:id/messages` | Send a message |

## Testing

| Suite | Count | How |
|---|---|---|
| Backend repo + cache | 16 | `cargo test -p portfolio-api` |
| Backend DB pragma | 1 | asserts `init_pool_with_url` applies expected pragmas |
| Backend HTTP integration | 5 | `tower::ServiceExt::oneshot` against the live router |
| Shared types | 4 | `cargo test -p emulsion-types` (incl. `match` wire-key regression guard) |
| iOS models / APIClient / ViewModels | 12 / 2 / 4 | `xcodebuild test` with `MockAPIClient: APIClientProtocol` |

```bash
cargo test --workspace
bazel test //...
xcodebuild test -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Full plan: [`docs/test-plan.md`](docs/test-plan.md).

## Performance

- **WAL + tuned pragmas** at `init_pool()` in `db.rs`: `synchronous = NORMAL`, `busy_timeout = 5s`, `foreign_keys = ON`, `temp_store = MEMORY`, 16 MB page cache.
- **B-tree indexes** on every `portfolio_id` and `conversation_id` filter column. `EXPLAIN QUERY PLAN` reports `SEARCH … USING INDEX`.
- **Concurrent fan-out.** `get_portfolio` issues 3 queries via `tokio::join!`. Wall-clock = max(3) instead of sum.
- **Atomic counters.** `UPDATE … SET col = col + 1` — no read-modify-write, no transaction needed.
- **Stripped release binary.** Thin LTO + `codegen-units = 1` + `strip = "symbols"` + `panic = "abort"` produces a ~3.8 MB binary.

## Documentation

| | |
|---|---|
| [`docs/system-design.md`](docs/system-design.md) | Architecture, data flow, cache strategy, latency considerations, known limitations |
| [`docs/retrospective.md`](docs/retrospective.md) | Phase-by-phase decisions, tradeoffs, what I'd change with more time |
| [`docs/test-plan.md`](docs/test-plan.md) | Coverage by tier, what's tested vs. deliberately not |
| [`AGENTS.md`](AGENTS.md) | Conventions for AI coding agents — naming, patterns, common tasks |
| [`CLAUDE.md`](CLAUDE.md) | Build/test commands and conventions |

## Limitations

<details>
<summary><b>Known gaps</b></summary>

- **Single-server.** No horizontal scaling. Cache is in-process, not distributed.
- **No HTTPS.** Localhost HTTP only. iOS uses an `NSAllowsLocalNetworking` ATS exception.
- **Theatre inbox.** Conversations are seeded demo data. The AMA flow does write back; conversation list is read-only.
- **Q&A "fuzzy" match.** SQL `LIKE '%query%'` — case-insensitive but not real fuzzy. FTS5 / trigram / vectors are the migration path.
- **Auth placeholder.** `X-Owner-Token` header is checked for *presence* on the notes listing, not value.
- **iOS shared-types migration not finished.** Backend uses `emulsion_types::PortfolioResponse`. iOS still uses its own Codable mirrors. The xcframework exists; the pbxproj entry is the missing step.
- **Bazel iOS test target.** Hand-rolled pbxproj makes `ios_unit_test` painful. iOS tests run via `xcodebuild test` only.

</details>

---

<div align="center">

Built by [Richard Lao](mailto:richard@seractech.co.uk) · 24-hour take-home for Lapse.

</div>
