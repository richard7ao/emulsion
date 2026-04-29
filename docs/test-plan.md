# Test Plan

## Test Coverage by Tier

### Tier 1 — Build Verification
- `cargo build -p portfolio-api` — Rust backend compiles
- `cargo build -p seed` — Seed binary compiles
- `xcodebuild build` — iOS app compiles (all views, models, APIClient)
- `bazel build //services/portfolio-api:server` — Bazel Rust target builds
- `bazel build //apps/ios:app` — iOS app builds via Bazel
- `bazel build //shared/emulsion-types:emulsion_types` — Shared types build via Bazel (manual tag; requires crate_universe patch)

### Tier 2 — Unit Tests
- **Cache (3 tests):** get/set, invalidate, invalidate_prefix
- **Portfolio repo (4 tests):** find_by_id (found/not found), increment_view_count, increment_interested_count
- **Experience repo (2 tests):** find_by_portfolio_id (empty/populated)
- **Skills repo (1 test):** find_by_portfolio_id returns skills
- **Projects repo (2 tests):** increment_view_count (atomic), increment_interested_count (atomic)
- **Q&A repo (2 tests):** fuzzy_match (found/not found)
- **Notes repo (1 test):** create and find_by_portfolio_id
- **Conversations repo (1 test):** find_by_portfolio_id with messages
- **DB pragma (1 test):** `init_pool_with_url` applies busy_timeout, foreign_keys, synchronous
- **HTTP integration (5 tests):** /health, 404 portfolio, full portfolio response, 400 empty note, 401 missing owner token
- **Shared types (4 tests):** portfolio_roundtrip, portfolio_response_contains_nested, ask_response_match_serializes_as_match_keyword, ask_response_with_none_match
- **iOS models (12 tests):** Portfolio/Experience/Project/PortfolioResponse/AskResponse/ConversationsResponse decoding, parseJSONArray (valid/empty/invalid), formatTimestamp (valid/invalid)
- **iOS APIClient (2 tests):** default baseURL, custom baseURL
- **iOS ViewModels (4 tests):** PortfolioViewModel initial state, load happy path, load error path, ProjectDetailViewModel markInterested increment

All Rust repo tests use in-memory SQLite (`sqlite::memory:`) with `sqlx::migrate!()` for isolated, repeatable test environments. iOS tests run via `xcodebuild test` on the Simulator using a `MockAPIClient` conforming to `APIClientProtocol`.

### Tier 3 — Integration / Verification
- **HTTP integration suite:** `tower::ServiceExt::oneshot` against the actual axum router covers happy and unhappy paths (5 tests in `routes/tests.rs`).
- **E2E smoke test:** Start live server with seeded DB, hit all endpoints, verify HTTP 200 and correct JSON shapes.
- **Static file serving:** `/static/hero.png`, `/static/marl.png`, etc. return 200.
- **Route syntax:** All parameterized routes use axum 0.7.9 `:id` syntax (not `{id}`).

## What Is Tested

| Layer | Coverage | Method |
|-------|----------|--------|
| Rust repositories | All 7 repos, 13 tests | `cargo test` with in-memory SQLite |
| Cache | 3 tests | `cargo test` |
| DB pragmas | 1 test | `cargo test` (pool-level pragma assertions) |
| HTTP integration | 5 tests | `tower::ServiceExt::oneshot` |
| Shared types | 4 tests | `cargo test -p emulsion-types` |
| API endpoints | All routes | HTTP integration + E2E curl |
| Static serving | hero/project PNGs | E2E curl HTTP status check |
| iOS models | 12 tests | `xcodebuild test` |
| iOS APIClient | 2 tests | `xcodebuild test` |
| iOS ViewModels | 4 tests | `xcodebuild test` with `MockAPIClient` |
| iOS build | Full app with all views | `xcodebuild build` |

## What Is Not Tested (and Why)

| Gap | Reason |
|-----|--------|
| iOS UI snapshot tests | Visual correctness verified by running in Simulator. Snapshot tests would catch regressions but add maintenance overhead. |
| Concurrent access | Single-user demo. SQLite WAL mode and atomic SQL ensure correctness, but no load testing performed. |
| iOS ViewModels for Ask/Inbox/LeaveNote | Only `PortfolioViewModel` and `ProjectDetailViewModel` have happy/error/markInterested coverage. Adding parity for the others is mechanical with `MockAPIClient`. |
| End-to-end iOS↔backend test | Requires a Simulator run with the live server. Covered manually via `./run.sh`. |
