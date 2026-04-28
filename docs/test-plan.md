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
- **Shared types (3 tests):** portfolio_roundtrip, portfolio_response_contains_nested, ask_response_with_none_match
- **iOS models (12 tests):** Portfolio/Experience/Project/PortfolioResponse/AskResponse/ConversationsResponse decoding, parseJSONArray (valid/empty/invalid), formatTimestamp (valid/invalid)
- **iOS APIClient (2 tests):** default baseURL, custom baseURL
- **iOS ViewModel (1 test):** PortfolioViewModel initial state

All Rust repo tests use in-memory SQLite (`sqlite::memory:`) with `sqlx::migrate!()` for isolated, repeatable test environments. iOS tests run via `xcodebuild test` on the Simulator.

### Tier 3 — Integration / Verification
- **E2E smoke test:** Start live server with seeded DB, hit all endpoints (portfolio, projects, Q&A, ask, notes, conversations, messages, health, static), verify HTTP 200 and correct JSON shapes
- **Static file serving:** Verify `/static/hero.svg` and `/static/projects/*.svg` return 200
- **Route syntax:** All parameterized routes use axum 0.7.9 `:id` syntax (not `{id}`)
- **iOS code checks:** Grep-based verification that views use correct patterns (pager style, rotation seeding, fallback UI, validation, demo badge, disabled send)

## What Is Tested

| Layer | Coverage | Method |
|-------|----------|--------|
| Rust repositories | All 7 repos, 13 tests | `cargo test` with in-memory SQLite |
| Cache | 3 tests | `cargo test` |
| Shared types | 3 tests | `cargo test -p emulsion-types` |
| API endpoints | All 9 routes | E2E curl against live server |
| Static serving | hero.svg + project SVGs | E2E curl HTTP status check |
| iOS models | 12 tests | `xcodebuild test` |
| iOS APIClient | 2 tests | `xcodebuild test` |
| iOS ViewModel | 1 test | `xcodebuild test` |
| iOS build | Full app with all views | `xcodebuild build` |
| iOS patterns | Theme, pager, fallback, validation | Grep-based source checks |

## What Is Not Tested (and Why)

| Gap | Reason |
|-----|--------|
| iOS ViewModel network paths | ViewModels tested for initial state only. Network-dependent paths (load, submit) require a mock server or protocol-based APIClient. |
| API handler unit tests | Handlers are thin (extract → repo → map error → Json). Repository tests cover the logic. E2E tests cover the routing. |
| Concurrent access | Single-user demo. SQLite WAL mode and atomic SQL ensure correctness, but no load testing performed. |
| Error response shapes | Only happy-path JSON shapes verified. Error codes (400, 401, 404, 500) tested informally during development. |
| UI visual regression | No snapshot tests. Visual correctness verified by running in Simulator during development. |
