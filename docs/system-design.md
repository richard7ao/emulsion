# System Design

## Architecture Overview

The system is a two-tier client-server architecture: a native iOS app (SwiftUI) communicating with a Rust backend (axum) over HTTP/JSON. A shared Rust crate (`emulsion-types`) defines all domain types once, with UniFFI generating Swift bindings for type-safe cross-language sharing.

```
┌──────────────────────┐       HTTP/JSON       ┌──────────────────────┐
│     iOS Client       │ ◄──────────────────► │    Rust Backend      │
│  SwiftUI + MVVM      │    localhost:8080     │  axum 0.7.9          │
│  @Observable VMs     │                       │  SQLite (WAL mode)   │
│  URLSession async    │                       │  DashMap cache       │
│  EmulsionTheme system   │                       │  ServeDir for /static│
└──────────────────────┘                       └──────────────────────┘
         ▲                                              ▲
         │              ┌──────────────────┐            │
         └──────────────│  Shared Types    │────────────┘
            UniFFI      │  emulsion-types  │   Cargo dep
            bindings    │  (Rust + UDL)    │
                        └──────────────────┘
```

**Backend (services/portfolio-api):** Single-binary Rust server using axum 0.7.9 with tokio async runtime. SQLite via sqlx 0.8 in WAL mode for concurrent reads. DashMap 6 provides an in-memory read cache. Static assets served via tower-http ServeDir.

**iOS App (apps/ios):** SwiftUI targeting iOS 26. MVVM-lite pattern with `@Observable` ViewModels. `URLSession` for networking (no third-party dependencies). `EmulsionTheme` enum centralizes all visual constants. Tab bar at root with swipeable TLDR card and inbox.

**Monorepo:** Bazel 9.1.0 with Bzlmod manages both the Rust service and iOS app. `rules_rust 0.70.0` for Rust, `rules_apple 4.5.3` + `rules_swift 3.6.1` for iOS.

## Shared Platform Layer

`shared/emulsion-types` is a Rust crate defining the canonical wire types shared between the backend and (eventually) the iOS client.

**Wired today (backend):**
- `services/portfolio-api/src/handlers/portfolio_handler.rs::get_portfolio` returns `Json<emulsion_types::PortfolioResponse>`. The shared crate is a real Cargo dependency, not a placeholder.
- Backend row types in `services/portfolio-api/src/models/*.rs` implement `From<RowType> for emulsion_types::CanonicalType`, so a field rename in the shared crate forces a compile error on the conversion site.
- The wire format is verified by tests: `ask_response_match_serializes_as_match_keyword` ensures the iOS `match` key contract is preserved.

**Not yet wired (iOS):**
- `apps/ios/Sources/Models/Models.swift` has its own Codable structs matching the same wire format. Migrating iOS to consume the UniFFI-generated bindings (or a Swift package wrapping them) is the next step.
- `shared/emulsion-types/generate-bindings.sh` produces an xcframework but it is not yet imported in `PortfolioApp.xcodeproj`.

**Why the gap:** within the time budget, wiring one consumer end-to-end with verified wire compatibility was prioritized over wiring both consumers superficially. The iOS migration is mechanical once the xcframework is added to the project.

**JSON-string nested arrays:** `Experience.bullets`, `Skill.items`, and `Project.screenshots` are typed as `String` (containing a JSON-encoded array) in both shared types and the row schema. This is a deliberate storage choice for SQLite — flat columns instead of join tables — and is documented as such on each type. A future migration would normalize these into separate tables.

## Data Flow

### Read Path (Portfolio)
1. iOS `PortfolioViewModel.load()` calls `APIClient.getPortfolio(id: 1)`
2. URLSession sends `GET /v1/portfolios/1`
3. axum handler checks DashMap cache for key `portfolio:1`
4. Cache miss → `tokio::join!` fans out three concurrent SQLite queries (portfolio, experiences, skills)
5. Results serialized as JSON, stored in cache, returned to client
6. ViewModel updates `@Observable` properties → SwiftUI re-renders

### Write Path (Interested)
1. iOS `ProjectDetailViewModel.markInterested()` optimistically increments local count
2. `POST /v1/projects/:id/interested` sent in background
3. Handler runs atomic SQL: `UPDATE projects SET interested_count = interested_count + 1`
4. Cache invalidated via `invalidate_prefix("projects:")`
5. Returns `{"status": "ok"}`

### Write Path (Notes)
1. Client-side validation (all fields non-empty)
2. `POST /v1/portfolios/1/notes` with JSON body
3. Handler validates, inserts via repository, returns `{"id": N}` with 201
4. iOS shows confirmation card

## Cache Strategy

**Pattern:** Cache-aside with `DashMap` (in-process, lock-free concurrent hashmap). Keys are produced by the `cache::keys` module to avoid stringly-typed mistakes.

**What is cached:**
- `portfolio:{id}` — full `PortfolioResponse` (portfolio + experiences + skills fan-out). Populated on `GET /v1/portfolios/:id` cache miss.
- `projects:list:{portfolio_id}` — project list. Populated on `GET /v1/portfolios/:id/projects` cache miss.
- `projects:item:{id}` — single project. Populated on `GET /v1/projects/:id` cache miss.

**Invalidation:**
- `POST /v1/portfolios/:id/{view,interested}` invalidates `portfolio:{id}`.
- `POST /v1/projects/:id/{view,interested}` invalidates the entire `projects:` prefix (both list and item).

**No TTL:** cache lives for process lifetime. Invalidation is write-driven.

**Scope discipline:** writes are kept on `POST` endpoints. `GET /v1/projects/:id` is now pure (the prior side-effecting view increment moved to `POST /v1/projects/:id/view`), so the cache entry stays valid until an explicit invalidation.

**Why not Redis:** single server, single user. DashMap is zero-latency, zero-ops, and a cache miss costs ~1 ms (local SQLite). At this scale, the cache exists more to demonstrate the pattern than to reduce wall-clock time.

## Error Handling

Handlers return `AppError`, an enum that maps to the correct HTTP status and logs internal errors:

| Variant | HTTP Status | Behavior |
|---------|-------------|----------|
| `NotFound` | 404 | Returned when `find_by_id` yields `None` or `sqlx::Error::RowNotFound` |
| `BadRequest(msg)` | 400 | Returned on validation failure (empty name, empty message) |
| `Unauthorized` | 401 | Returned when `X-Owner-Token` header is absent |
| `Internal(msg)` | 500 | Logged via `tracing::error!`, generic message returned to client |

`sqlx::Error` converts automatically via `From<sqlx::Error>`: `RowNotFound` becomes 404, everything else becomes 500 with the error logged. All error responses are JSON: `{"error": "message"}`.

## Q&A Matching

`POST /v1/portfolios/:id/qa/ask` uses SQLite FTS5 with the porter tokenizer for full-text search. The query is tokenized into keywords (words >= 3 characters), each quoted and joined with `OR`, then matched against the `qa_pairs_fts` virtual table. Results are ranked by BM25 relevance.

**Porter stemming** handles morphological variants: "builds" matches "Building", "works" matches "working". This eliminates the prior limitation where exact keyword overlap was required.

**Schema:** `qa_pairs_fts` is a content-sync FTS5 table backed by `qa_pairs`. Triggers on INSERT/DELETE keep the index in sync automatically — no manual FTS population needed.

## Latency Considerations

- **SQLite tuning:** WAL journal mode for concurrent readers, `synchronous = NORMAL` (durable across power loss except the last fsync), `busy_timeout = 5s`, `temp_store = MEMORY`, 16 MB page cache, FK constraints enabled. Set at `init_pool()` in `db.rs`.
- **FK indexes:** every `portfolio_id` and `conversation_id` filter column has a B-tree index (`migrations/0003_indexes.sql`). `EXPLAIN QUERY PLAN SELECT * FROM experiences WHERE portfolio_id = 1` reports `SEARCH … USING INDEX`.
- **Fan-out with `tokio::join!`:** `get_portfolio` issues three queries concurrently (portfolio, experiences, skills). Wall-clock = max instead of sum.
- **Atomic counters:** `UPDATE … SET col = col + 1` avoids read-modify-write race conditions and removes the need for transactions.
- **Release profile:** `lto = "thin"`, `codegen-units = 1`, `strip = "symbols"`, `panic = "abort"`. Smaller, faster binary.
- **Static file serving:** `tower-http::ServeDir` for SVG/PNG. No DB round-trip.
- **Request tracing:** `tower_http::trace::TraceLayer` logs method, path, status, and latency for every request. With `RUST_LOG=tower_http=debug`, per-request timing is visible in stdout.
- **Health check:** `GET /health` runs `SELECT 1` against the connection pool. Returns `{"status": "ok", "db": "ok"}` (200) or 500 if the database is unreachable. Suitable for liveness/readiness probes.
- **Configurable port:** Server reads `PORT` env var (default 8080). Bind failures produce a clear error.
- **Benchmark script:** `scripts/benchmark.sh` runs 20 requests per endpoint and reports p50/p99 latency.

## Considered But Not Built

| Feature | Why Not |
|---------|---------|
| WebSocket for real-time inbox | Inbox is theatre (read-only seeded data). No write path means no real-time updates to push. |
| Image upload for projects | Placeholder SVGs demonstrate the static serving pattern. Real image handling would need S3/CDN, resize pipeline, content moderation. |
| Authentication beyond X-Owner-Token | Notes listing uses a header token as a placeholder. Real auth (JWT, OAuth) is out of scope for a demo portfolio. |
| Server-side pagination | Dataset is small (2 projects, 6 Q&As, 3 conversations). Pagination adds complexity without value at this scale. |
| Direct FFI calls (replacing HTTP) | UniFFI shared types are built (Phase 8), but the iOS app still communicates over HTTP/JSON. Migrating to direct FFI calls would eliminate the network layer for on-device use. |

## Known Limitations

- **Single-server deployment:** No horizontal scaling. Cache is in-process, not distributed.
- **No pagination:** All endpoints return full result sets. Would need cursor-based pagination at scale.
- **Theatre inbox:** Seeded conversations start as theatre (`is_theatre = 1`). Sending a message or creating an AMA conversation transitions the flag to `is_theatre = 0`. The API returns per-conversation theatre state; the top-level `theatre` flag is `false` if any conversation has user-written content.
