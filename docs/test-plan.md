# Test Plan

## Test Coverage by Tier

### Tier 1 — Build Verification
- `cargo build -p portfolio-api` — Rust backend compiles
- `cargo build -p seed` — Seed binary compiles
- `xcodebuild build` — iOS app compiles (all views, models, APIClient)
- `bazel build //services/portfolio-api:server` — Bazel Rust target builds
- `bazel build //apps/ios:PortfolioApp` — Bazel iOS target builds

### Tier 2 — Unit Tests
- **Cache (3 tests):** get/set, invalidate, invalidate_prefix
- **Portfolio repo (1 test):** find_by_id returns seeded portfolio
- **Experience repo (1 test):** find_by_portfolio_id returns experiences
- **Skills repo (1 test):** find_by_portfolio_id returns skills
- **Projects repo (3 tests):** find_by_portfolio_id, increment_view_count (atomic), increment_interested_count (atomic)
- **Q&A repo (2 tests):** find_canned_by_portfolio_id, fuzzy_match returns matching pair
- **Notes repo (2 tests):** create and find_by_portfolio_id
- **Conversations repo (2 tests):** find_by_portfolio_id, find_messages_by_conversation_id

All repo tests use in-memory SQLite (`sqlite::memory:`) with `sqlx::migrate!()` for isolated, repeatable test environments.

### Tier 3 — Integration / Verification
- **E2E smoke test:** Start live server with seeded DB, hit all endpoints (portfolio, projects, Q&A, ask, notes, conversations, messages, health, static), verify HTTP 200 and correct JSON shapes
- **Static file serving:** Verify `/static/hero.svg` and `/static/projects/*.svg` return 200
- **Route syntax:** All parameterized routes use axum 0.7.9 `:id` syntax (not `{id}`)
- **iOS code checks:** Grep-based verification that views use correct patterns (pager style, rotation seeding, fallback UI, validation, demo badge, disabled send)

## What Is Tested

| Layer | Coverage | Method |
|-------|----------|--------|
| Rust repositories | All 7 repos, 15 tests | `cargo test` with in-memory SQLite |
| Cache | 3 tests | `cargo test` |
| API endpoints | All 9 routes | E2E curl against live server |
| Static serving | hero.svg + project SVGs | E2E curl HTTP status check |
| iOS build | Full app with all views | `xcodebuild build` |
| iOS patterns | Theme, pager, fallback, validation | Grep-based source checks |

## What Is Not Tested (and Why)

| Gap | Reason |
|-----|--------|
| iOS unit tests (XCTest) | Time constraint. ViewModels are testable but setting up XCTest targets in a hand-crafted pbxproj adds complexity. Views are verified by successful build + visual inspection. |
| API handler unit tests | Handlers are thin (extract → repo → map error → Json). Repository tests cover the logic. E2E tests cover the routing. |
| Concurrent access | Single-user demo. SQLite WAL mode and atomic SQL ensure correctness, but no load testing performed. |
| Error response shapes | Only happy-path JSON shapes verified. Error codes (400, 401, 404, 500) tested informally during development. |
| UI visual regression | No snapshot tests. Visual correctness verified by running in Simulator during development. |
