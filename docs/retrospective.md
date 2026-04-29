# Retrospective

## Phase 1 — Repo Foundation & Bazel

### Key Decisions

- **Bazel 9 with Bzlmod:** Chose MODULE.bazel over the legacy WORKSPACE format for forward compatibility. Bzlmod is where Bazel's dependency management is heading, and starting with it avoids a painful migration later.
- **Rule version compatibility:** Finding Bazel 9 compatible versions of rules_rust, rules_apple, and rules_swift took trial and error. Not all version combinations work together. Landed on rules_rust 0.70.0, rules_apple 4.5.3, rules_swift 3.6.1, and apple_support 2.5.4 after testing several combinations.
- **Xcode project alongside Bazel:** Created a hand-crafted .xcodeproj so I could iterate quickly in Xcode while Bazel owns the canonical monorepo build. This trades maintenance cost for a much faster inner development loop.
- **Monorepo with Cargo workspace:** Single workspace, shared dependency versions, single lock file.

### What Was Hard

- Hand-crafting the pbxproj file. Without the xcodeproj Ruby gem (system Ruby permission issues), I wrote the project file manually. Every new Swift file needs entries in four places: PBXFileReference, PBXBuildFile, PBXGroup, and the target's sources build phase. This became the single biggest source of friction throughout the project.

## Phase 2 — Data Layer & API Handlers

### Key Decisions

- **sqlx over diesel:** Lighter macro overhead, async-native. `query_as` with runtime checking was sufficient for this scope.
- **Atomic SQL counters:** `UPDATE SET col = col + 1` eliminates race conditions at the statement level — no read-modify-write, no explicit transactions needed.
- **JSON strings for arrays:** Experience bullets and project screenshots stored as JSON strings rather than normalised tables. Acceptable tradeoff for small, fixed datasets.
- **tokio::join! fan-out:** The portfolio endpoint needs data from three tables. Concurrent queries via `tokio::join!` reduce wall-clock time.
- **Cache-aside with DashMap:** In-process, lock-free concurrent hashmap. Write-driven invalidation via prefix matching, no TTL. Appropriate for single-server deployment.
- **Theatre flag on inbox responses:** `"theatre": true` signals seeded demo data to the client, which disables the send button.
- **include_str! for seed data:** CV JSON embedded at compile time. Self-contained binary, no runtime file paths.

### What Was Hard

- axum 0.7.9 uses `:id` for path parameters, not `{id}` (axum 0.8+ syntax). This caused every parameterised endpoint to return 404 — silently, no compilation warning, just routes that never matched. Took trace-level logging to identify.

### What I Would Change

- Use sqlx query macros (`query_as!`) for compile-time type checking against the schema.

## Phase 3 — iOS Foundation

### Key Decisions

- **@Observable over ObservableObject:** iOS 26 target means I can use the modern Observation framework. Cleaner syntax, fine-grained tracking, no `@Published` boilerplate.
- **@MainActor on all ViewModels:** Required by Swift 6 strict concurrency. Without it, async methods on `@Observable` classes produce data race warnings.
- **APIClient as a plain class (not singleton):** Injected through AppState for testability — tests can substitute a client with a different base URL or mock session.
- **Zero third-party dependencies:** SwiftUI + Foundation only. URLSession, JSONDecoder, native Layout protocol. Simple dependency graph, no version compat concerns.

### What Was Hard

- Swift 6 strict concurrency. The interaction between `@Observable`, `@MainActor`, and async/await is subtle. Non-isolated async methods trigger data race warnings even when they only write to `@MainActor`-isolated properties. The solution is straightforward once you understand the model, but the compiler errors don't always point you in the right direction.

## Phase 4 — iOS Screens

### Key Decisions

- **Flat NavigationStack:** Every screen is one tap from the portfolio home. No deep nesting.
- **Optimistic UI for interested counters:** Local count increments immediately, network request fires in the background.
- **Custom FlowLayout for skills tags:** The Layout protocol lets me compute row breaks based on available width. Grid wasn't suitable for variable-width tags.
- **Tinder-style swipe on TLDR card:** DragGesture with rotation and opacity overlays. Gesture thresholds and spring animation tuned by feel.

### What Was Hard

- Achieving the Lapse-inspired aesthetic with code-only SwiftUI. No asset catalog, no Figma exports, no design tokens beyond the theme enum. The polaroid card effect (slight rotation seeded by index, drop shadow, warm off-white background) carries the visual identity. Getting the grain overlay to look natural took experimentation.

## Phase 5 — Shared Platform Layer (Bonus)

### What I built within the original 24h

- A `shared/emulsion-types` crate defining all 8 domain types and 5 response DTOs.
- A UniFFI UDL schema and a `generate-bindings.sh` that produces an xcframework for iOS consumption.
- Cargo dependency from `services/portfolio-api` to the shared crate.

### What I deliberately did *not* finish in 24h

- **Wiring either consumer to the shared types.** The Cargo dep was declared but the backend kept its own response shapes; iOS kept its own Codable. The shared crate compiled and round-trip-tested but no traffic flowed through it. I documented this as a known gap rather than papering over it.

### What I added in the crit-survival pass

- Backend `get_portfolio` now returns `Json<emulsion_types::PortfolioResponse>`, with `From` conversions on the row types in `models/*.rs`. The dependency is real; a field rename in the shared crate now forces a compile error on the conversion site.
- Aligned shared types to the actual wire format (`AskResponse.match` rename, JSON-string array fields documented).
- Added a serde test asserting the `match` wire key cannot regress to `match_result`.

### What remains

- iOS migration to the generated bindings. The xcframework exists; the pbxproj entry and a Swift Package wrapper are the missing steps.
- Normalising the JSON-string array columns (`bullets`, `items`, `screenshots`) into proper relational tables. The shared types reflect today's storage shape, not the destination shape.

### What was hard

- UniFFI's UDL syntax for nullable fields and sequences. Documentation is comprehensive but spread across multiple pages.
- Bazel + UniFFI: `crates_universe` builds `uniffi_testing` which uses `env!("CARGO")`, unavailable in the Bazel sandbox. The Bazel target is marked `tags = ["manual"]`; Cargo is the canonical build for that crate.

## Priorities and Tradeoffs

Given the 24-hour constraint, I prioritised:

1. **Working end-to-end system** — every screen talks to a real backend
2. **Clean architecture** — repository pattern, MVVM, clear module boundaries
3. **Bazel builds both targets** — `//services/portfolio-api:server` and `//apps/ios:app`
4. **Documentation** — system design, test plan, and this retrospective
5. **Shared platform layer (bonus)** — UniFFI types crate with generated Swift bindings

The main thing I'd cut differently in retrospect: I should have set up XCTest targets early, when the pbxproj was small, rather than deferring them. Adding test infrastructure after 15+ Swift files means a much larger pbxproj edit.

## What I Would Change With More Time

- **Swift Package Manager** instead of a hand-crafted Xcode project. SPM handles file discovery and test targets automatically — this would have eliminated the pbxproj friction that dominated Phase 1.
- **XCTest targets from the start.** Retrofitting them is harder than setting them up alongside the first view.
- **sqlx compile-time query macros** (`query_as!`) for schema validation at build time.
- **Wire shared types into both consumers** — have the iOS app import the UniFFI-generated types and the backend re-export from the shared crate, eliminating duplicate type definitions.

## What I Learned

- **Bazel 9 Bzlmod is usable but rough.** The biggest gap is version compatibility documentation — you end up testing rule combinations empirically. Once you have a working set, adding new targets is straightforward.
- **UniFFI is surprisingly production-ready.** The setup ceremony (UDL → scaffolding → bindings → xcframework) is a one-time cost. After that, adding a new shared type is three lines of Rust and a few lines of UDL.
- **Swift 6 concurrency catches real bugs but has a learning curve.** The `@Observable` + `@MainActor` + async pattern is the right model, but the compiler needs better diagnostics. I spent more time on concurrency annotations than on actual UI code.
- **Always check version-specific API docs.** The axum `:id` vs `{id}` issue cost me debugging time that reading the 0.7.9 docs would have prevented. Minor version differences can change fundamental APIs.

---

## Post-script: crit-survival pass

After completing the original 24h build I did a focused review against the brief and made a second pass focused on closing the gap between what the docs claimed and what the code did.

**Backend substance:**
- FK indexes on every `portfolio_id` and `conversation_id` filter column (`migrations/0003_indexes.sql`). `EXPLAIN QUERY PLAN` now reports `SEARCH … USING INDEX` instead of `SCAN`.
- SQLite pragmas tuned at `init_pool()`: `synchronous = NORMAL`, `busy_timeout = 5s`, `foreign_keys = ON`, in-memory temp store, 16 MB page cache.
- Release profile: `lto = "thin"`, `codegen-units = 1`, `strip = "symbols"`, `panic = "abort"`.
- `GET /v1/projects/:id` made pure (cacheable); view increment moved to `POST /v1/projects/:id/view`.
- `tower_http::trace::TraceLayer` for per-request method/path/status/latency logs.
- `cache::keys` module replaces stringly-typed cache key format strings.

**Shared types wired:**
- Backend `get_portfolio` returns `Json<emulsion_types::PortfolioResponse>`. `From` conversions on row types make schema drift a compile error.
- Shared types aligned to the real wire format (`#[serde(rename = "match")]` on `AskResponse.match_result`; JSON-string arrays documented).

**Test depth:**
- `APIClient` extracted to `APIClientProtocol`; ViewModels now accept `any APIClientProtocol`.
- `MockAPIClient` + happy-path, error-path, and `markInterested` increment tests for ViewModels (4 ViewModel tests, 18 iOS tests total).
- 5 backend HTTP-level integration tests via `tower::ServiceExt::oneshot`: health, 404, 401, 400 validation, full portfolio response (22 backend tests total).
- `init_pool_with_url()` helper avoids global env mutation in the pragma test.

**iOS quality:**
- `Project.interestedCount` made `var`; `markInterested` mutates in place instead of rebuilding the struct field-by-field.

**What I would still want with another day:**
- Wire the UniFFI xcframework into `PortfolioApp.xcodeproj` so iOS consumes shared Swift types.
- Normalise `bullets` / `items` / `screenshots` into relational tables and drop the JSON-string-on-the-wire pattern.
- A Bazel `swift_test` target for iOS so `bazel test //...` is meaningful.
- An end-to-end CI workflow (GitHub Actions) running both build systems on PR.

---

## Post-script: crit-survival v2

After a harsh spec review against the brief, six issues were fixed:

1. **Error handling overhaul.** Every handler now returns `AppError` instead of bare `StatusCode`. Database errors are logged via `tracing::error!`; "not found" returns 404 (not 500). All error responses are structured JSON (`{"error": "message"}`). `From<sqlx::Error>` maps `RowNotFound` to 404 automatically.
2. **AMA race condition fixed.** `UNIQUE(portfolio_id, participant_name)` constraint (`migrations/0004_ama_unique.sql`) + `INSERT OR IGNORE` eliminates the check-then-act window in `find_or_create_ama`. New idempotency test proves it.
3. **Configurable port.** Server reads `PORT` env var (default 8080). Bind failures produce a clear panic message instead of an opaque unwrap trace.
4. **Health check pings DB.** `GET /health` runs `SELECT 1` against the pool — readiness probes can detect database unavailability. Returns `{"status": "ok", "db": "ok"}`.
5. **Q&A matching improved.** Tokenized keyword search across both prompt and answer text, ranked by hit count. Short words (< 3 chars) filtered out. No longer limited to a single `LIKE '%x%'` on the prompt column alone.
6. **Benchmark script.** `scripts/benchmark.sh` runs 20 requests per endpoint and reports p50/p99 latency, backing up the "low latency" claim with real measurements.

Test count: 27 backend + 4 shared = 31 Rust tests (up from 22 + 4 = 26). iOS unchanged at 18. Total: 49.
