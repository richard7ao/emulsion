# System Design

## Architecture Overview

The system is a two-tier client-server architecture: a native iOS app (SwiftUI) communicating with a Rust backend (axum) over HTTP/JSON.

```
┌──────────────────────┐       HTTP/JSON       ┌──────────────────────┐
│     iOS Client       │ ◄──────────────────► │    Rust Backend      │
│  SwiftUI + MVVM      │    localhost:8080     │  axum 0.7.9          │
│  @Observable VMs     │                       │  SQLite (WAL mode)   │
│  URLSession async    │                       │  DashMap cache       │
│  LapseTheme system   │                       │  ServeDir for /static│
└──────────────────────┘                       └──────────────────────┘
```

**Backend (services/portfolio-api):** Single-binary Rust server using axum 0.7.9 with tokio async runtime. SQLite via sqlx 0.8 in WAL mode for concurrent reads. DashMap 6 provides an in-memory read cache. Static assets served via tower-http ServeDir.

**iOS App (apps/ios):** SwiftUI targeting iOS 26. MVVM-lite pattern with `@Observable` ViewModels. `URLSession` for networking (no third-party dependencies). `LapseTheme` enum centralizes all visual constants. Tab bar at root with swipeable TLDR card and inbox.

**Monorepo:** Bazel 9.1.0 with Bzlmod manages both the Rust service and iOS app. `rules_rust 0.70.0` for Rust, `rules_apple 4.5.3` + `rules_swift 3.6.1` for iOS.

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

**Pattern:** Cache-aside with DashMap (in-process, lock-free concurrent hashmap).

- **Reads:** Check cache first. On miss, query SQLite, store result, return.
- **Writes:** Execute write, then invalidate related cache entries via `invalidate_prefix`.
- **Scope:** Portfolio fan-out response cached (most expensive query — 3 joins). Project lists invalidated on view/interested increments.
- **No TTL:** Cache lives for process lifetime. Invalidation is write-driven, not time-driven. Acceptable for single-server, single-user deployment.

**Why not Redis/external cache:** Single server process, single user. DashMap is zero-latency, zero-ops. A cache miss costs ~1ms (local SQLite), so even without caching, latency is negligible.

## Latency Considerations

- **SQLite WAL mode:** Allows concurrent readers without blocking writers. Eliminates lock contention for the read-heavy portfolio endpoint.
- **Fan-out with tokio::join!:** Portfolio, experiences, and skills queries run concurrently. Wall-clock time is max(query times) rather than sum.
- **Atomic counters:** `UPDATE SET col = col + 1` avoids read-modify-write race conditions and eliminates the need for transactions.
- **Static file serving:** SVG placeholders served from memory-mapped files by tower-http. No database round-trip.

## Considered But Not Built

| Feature | Why Not |
|---------|---------|
| Full-text search for Q&A | SQLite FTS5 would be better than LIKE queries, but fuzzy LIKE matching works for 6 canned prompts. Not worth the complexity for demo scope. |
| WebSocket for real-time inbox | Inbox is theatre (read-only seeded data). No write path means no real-time updates to push. |
| Image upload for projects | Placeholder SVGs demonstrate the static serving pattern. Real image handling would need S3/CDN, resize pipeline, content moderation. |
| Authentication beyond X-Owner-Token | Notes listing uses a header token as a placeholder. Real auth (JWT, OAuth) is out of scope for a demo portfolio. |
| Server-side pagination | Dataset is small (2 projects, 6 Q&As, 3 conversations). Pagination adds complexity without value at this scale. |
| Shared Rust layer (UniFFI) | Phase 8 stretch goal. Would allow iOS to share types with the backend. Not implemented due to time constraints. |

## Known Limitations

- **Single-server deployment:** No horizontal scaling. Cache is in-process, not distributed.
- **No HTTPS:** Localhost HTTP only. iOS uses `NSAllowsLocalNetworking` ATS exception.
- **No pagination:** All endpoints return full result sets. Would need cursor-based pagination at scale.
- **Theatre inbox:** Conversations are seeded demo data. Users can send messages and ask questions via the AMA flow.
- **Q&A fuzzy match:** Uses SQL LIKE which is case-insensitive but not fuzzy. Better alternatives: FTS5, trigram similarity, or vector embeddings.
