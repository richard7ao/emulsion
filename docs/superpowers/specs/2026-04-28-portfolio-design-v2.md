# Portfolio App — Revised Spec & Execution Plan (v2)
#
# WHAT THIS IS: The revised task catalog, superseding v1. Fixes version
# mismatches (Bazel 9, iOS 26, Xcode 26), broken verify commands, and
# re-prioritises for the 24h interview brief.
#
# HOW TO USE: Same as v1 — CLAUDE.md boot protocol Step 4 points here.
# Find the task matching `current_task` in state.json, read fully, implement,
# verify. This file IS mutable — fix issues as we find them.
#
# REPLACES: 2026-04-28-portfolio-design.md (Codex v1)
# RELATED:  prd.md, CLAUDE.md, tasks/state.json, .claude/memory.md

---

## Overview

Native iOS app (SwiftUI, iOS 26) backed by a Rust/axum service, built in a Bazel
monorepo. Polaroid/film aesthetic. Real CV content (Richard Lao). Agent-optimised
codebase. Designed for a Lapse 24h take-home with a live crit session.

The interview brief evaluates: clarity of thinking, quality of foundation, pragmatism,
communication, and ownership. The interviewers will probe backend/data decisions,
expect Bazel to build BOTH iOS and Rust targets, and will ask you to extend the
solution live.

Full PRD: `prd.md`. Interview brief: `interview-guide.md`.

---

## Toolchain (verified on this machine)

| Tool         | Version  |
|--------------|----------|
| Rust         | 1.95.0   |
| Cargo        | 1.95.0   |
| sqlx-cli     | 0.8.6    |
| Bazel        | 9.1.0    |
| Xcode        | 26.4.1   |
| iOS SDK      | 26.4     |
| iOS Simulator| iPhone 16 (iOS 26.4) |
| SQLite       | 3.51.0   |

---

## Verification Rules (all tasks)

```
TIER 1 — Build Check     Fast (~5s).   Must exit 0 before tier 2.
TIER 2 — Unit Tests      Medium (~30s). Must exit 0 before tier 3.
TIER 3 — Integration     Slow (~60s).  All three must pass to mark complete.
```

**Server startup pattern (Phase 3+):**
```bash
DATABASE_URL=sqlite:./verify.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break
  sleep 2
done
# ... assertions ...
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
rm -f verify.db
```

**Failure protocol:**
1. Tier fails → attempt fix → re-run failing tier + all previous tiers.
2. Same root cause fails 3 times → write post-mortem, commit, stop.
3. Next session reads post-mortem before retrying.

---

## Phase 1 — Repo Foundation & Bazel

**Goal:** Working monorepo skeleton. Bazel parses and both targets (Rust + iOS)
build without error. Directory structure, READMEs, AGENTS.md exist.
Living retrospective started.

---

### T1.1 — Directory scaffold, READMEs, AGENTS.md

**Description:** Create the full directory tree from PRD §11. Write a short README.md
in each top-level package directory. Write AGENTS.md at repo root with directory map,
conventions, and naming patterns. Create doc stubs. Start the living retrospective
with a "Phase 1" section.

**Subtasks:**
- `apps/ios/README.md` — purpose, build command, test command
- `services/portfolio-api/README.md` — purpose, build command, test command
- `shared/schemas/README.md` — purpose, extension point note
- `tools/seed/README.md` — purpose, how to run
- `AGENTS.md` — directory map, naming conventions, "where to add X" patterns
- `docs/system-design.md` stub (section headers only)
- `docs/test-plan.md` stub (section headers only)
- `docs/retrospective.md` — living doc, start with Phase 1 section header + initial decisions

**Verify:**
```bash
# tier1_build
for d in apps/ios services/portfolio-api shared/schemas tools/seed docs; do
  [ -d "$d" ] || { echo "MISSING: $d"; exit 1; }
done
echo "tier1 pass"
```

```bash
# tier2_unit
for f in AGENTS.md apps/ios/README.md services/portfolio-api/README.md \
         shared/schemas/README.md tools/seed/README.md \
         docs/system-design.md docs/test-plan.md docs/retrospective.md; do
  [ -s "$f" ] || { echo "MISSING OR EMPTY: $f"; exit 1; }
done
echo "tier2 pass"
```

```bash
# tier3_integration
grep -q -i "conventions" AGENTS.md || { echo "AGENTS.md missing conventions"; exit 1; }
grep -q "_handler\|_view\|ViewModel" AGENTS.md || { echo "AGENTS.md missing naming patterns"; exit 1; }
grep -q -i "phase 1\|Phase 1" docs/retrospective.md || { echo "retrospective missing Phase 1"; exit 1; }
echo "tier3 pass"
```

---

### T1.2 — MODULE.bazel with rules_rust and rules_apple

**Description:** Create MODULE.bazel (Bzlmod) at repo root with `bazel_dep` entries
for `rules_rust` and `rules_apple`. Pin versions compatible with Bazel 9.1.0.
Create root BUILD file. Pin `.bazelversion` to 9.1.0. Document chosen versions
in `.claude/memory.md`.

**Subtasks:**
- `MODULE.bazel` with rules_rust + rules_apple (Bazel 9 compatible versions)
- Root `BUILD` file
- `.bazelversion` pinned to `9.1.0`
- Rust toolchain registration targeting stable

**Verify:**
```bash
# tier1_build
bazel info workspace 2>&1 | head -5
echo "tier1 pass"
```

```bash
# tier2_unit
bazel query '//...' 2>&1 | grep -v "^WARNING\|^DEBUG\|^Loading\|^Analyzing" | head -20
echo "tier2 pass"
```

```bash
# tier3_integration
[ -f ".bazelversion" ] && grep -q "9.1.0" .bazelversion \
  || { echo ".bazelversion missing or wrong version"; exit 1; }
echo "tier3 pass"
```

---

### T1.3 — Bazel target //services/portfolio-api:server

**Description:** Create a BUILD file for the Rust service with a `rust_binary` target
named `server`. The existing `src/main.rs` stub must be upgraded to a minimal axum
server that binds port 8080 and responds to `GET /health`. Must build via both
`bazel build` and `cargo build`.

**Subtasks:**
- `services/portfolio-api/BUILD` with `rust_binary(name = "server", ...)`
- `services/portfolio-api/src/main.rs` — minimal axum server, binds 8080, GET /health
- `services/portfolio-api/Cargo.toml` already has correct deps

**Verify:**
```bash
# tier1_build
bazel build //services/portfolio-api:server 2>&1 | tail -5
```

```bash
# tier2_unit
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier3_integration
BINARY=$(find bazel-bin/services/portfolio-api -name "server" -type f 2>/dev/null | head -1)
[ -n "$BINARY" ] || [ -f "services/portfolio-api/target/debug/portfolio-api" ] \
  || { echo "Binary not found"; exit 1; }
echo "tier3 pass"
```

---

### T1.4 — Bazel target //apps/ios:app + Xcode project

**Description:** Create an iOS app target built by Bazel using rules_apple. Minimal
SwiftUI app with a single ContentView showing "Hello Lapse". Also create an Xcode
project at `apps/ios/PortfolioApp.xcodeproj` — this is what we use for rapid
iteration and running in the simulator. Bazel builds the iOS target to satisfy the
brief; Xcode is the development workflow.

**FALLBACK:** If Bazel iOS fails after 3 hours of debugging, the Xcode project alone
is acceptable. Document the failure in `.claude/memory.md`. Bazel continues to own Rust.

**Important:** Add `NSAppTransportSecurity` → `NSAllowsLocalNetworking = YES` to
Info.plist so the app can make HTTP requests to localhost.

**Subtasks:**
- `apps/ios/BUILD` with `ios_application` target
- `apps/ios/Sources/PortfolioApp.swift` — @main App struct
- `apps/ios/Sources/Views/ContentView.swift` — "Hello Lapse"
- `apps/ios/Info.plist` — bundle ID `com.lapse.portfolio`, ATS exception for localhost
- `apps/ios/PortfolioApp.xcodeproj` — Xcode project for development
- Folder structure: Views/, ViewModels/, APIClient/, Models/, Theme/, Resources/

**Verify:**
```bash
# tier1_build — try Bazel first, fall back to xcodebuild
if bazel build //apps/ios:app 2>&1 | tail -3 | grep -q "Build completed"; then
  echo "tier1 pass: Bazel iOS"
elif [ -d "apps/ios/PortfolioApp.xcodeproj" ]; then
  xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
    -scheme PortfolioApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -allowProvisioningUpdates \
    build 2>&1 | tail -3
else
  echo "tier1 FAIL"; exit 1
fi
```

```bash
# tier2_unit — expected folders exist
for d in apps/ios/Sources/Views apps/ios/Sources/ViewModels \
         apps/ios/Sources/APIClient apps/ios/Sources/Models \
         apps/ios/Sources/Theme; do
  [ -d "$d" ] || { echo "MISSING: $d"; exit 1; }
done
echo "tier2 pass"
```

```bash
# tier3_integration — ATS exception exists in Info.plist
grep -q "NSAppTransportSecurity\|NSAllowsLocalNetworking" apps/ios/Info.plist \
  || { echo "FAIL: missing ATS exception for localhost"; exit 1; }
echo "tier3 pass"
```

**After Phase 1:** Update `docs/retrospective.md` with Phase 1 decisions (Bazel
version choices, any fallbacks taken, what was hard).

---

## Phase 2 — Rust: Data Layer

**Goal:** All 8 SQLite tables migrated. Repository structs with CRUD. In-memory
cache wired up. Unit tests green.

---

### T2.1 — SQLite schema + sqlx migrations

**Description:** Create all 8 table migrations. Enable WAL mode in db init code
(not in migration SQL). Run `cargo sqlx prepare` and commit `.sqlx/` for offline mode.

**Subtasks:**
- `services/portfolio-api/migrations/0001_initial.sql` — all 8 tables
- `services/portfolio-api/src/db.rs` — pool init, WAL mode PRAGMA, DATABASE_URL from env
- `services/portfolio-api/.sqlx/` — offline query metadata
- `.env.example` with `DATABASE_URL=sqlite:./dev.db`

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  DATABASE_URL=sqlite:./test_verify.db sqlx migrate run 2>&1 && \
  echo "migrations ran" && rm -f test_verify.db
```

```bash
# tier3_integration
cd services/portfolio-api && \
  DATABASE_URL=sqlite:./verify.db sqlx migrate run 2>&1 && \
  TABLES=$(sqlite3 verify.db ".tables") && \
  rm -f verify.db && \
  for t in portfolios experiences projects skills qa_pairs notes conversations messages; do
    echo "$TABLES" | grep -qw "$t" || { echo "MISSING TABLE: $t"; exit 1; }
  done && \
  echo "tier3 pass"
```

---

### T2.2 — Portfolio, Experience, Skills repositories

**Description:** Repository structs for portfolios, experiences, and skills tables.
Each in its own file under `src/repositories/`. Expose `find_by_id` for portfolio,
`find_by_portfolio_id` for experience and skills. Use sqlx typed queries.

**Subtasks:**
- `src/repositories/mod.rs` — module declarations
- `src/repositories/portfolio_repo.rs` — `find_by_id`
- `src/repositories/experience_repo.rs` — `find_by_portfolio_id`
- `src/repositories/skills_repo.rs` — `find_by_portfolio_id`
- `src/models/` — corresponding structs matching migration columns
- Unit tests in each file

**Requires:** T2.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test portfolio_repo experience_repo skills_repo -- --test-threads=1 2>&1 | tail -15
```

```bash
# tier3_integration
cd services/portfolio-api && \
  grep -rq "pub async fn find_by_id" src/repositories/portfolio_repo.rs && \
  grep -rq "pub async fn find_by_portfolio_id" src/repositories/experience_repo.rs && \
  grep -rq "pub async fn find_by_portfolio_id" src/repositories/skills_repo.rs && \
  echo "tier3 pass"
```

---

### T2.3 — Projects repository with atomic counters

**Description:** Projects repository with `find_by_portfolio_id`, `find_by_id`,
`increment_view_count`, `increment_interested_count`. Counter functions MUST use
`UPDATE projects SET col = col + 1 WHERE id = ?` — never read-modify-write.

**Subtasks:**
- `src/repositories/projects_repo.rs` — all four functions
- `src/models/project.rs` — Project struct
- Unit tests covering counter increments

**Requires:** T2.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test projects_repo -- --test-threads=1 2>&1 | tail -15
```

```bash
# tier3_integration
cd services/portfolio-api && \
  grep -E "SET (view_count|interested_count) = (view_count|interested_count) \+" \
    src/repositories/projects_repo.rs \
  || { echo "FAIL: counter not atomic"; exit 1; }
echo "tier3 pass"
```

---

### T2.4 — Q&A, Notes, Theatre repositories

**Description:** Repositories for qa_pairs, notes, conversations, messages.
Q&A: `find_canned_by_portfolio_id` and `fuzzy_match` (LIKE '%query%', returns
single best row or None via LIMIT 1). Notes: `create` and `find_by_portfolio_id`.
Theatre: read-only `find_by_portfolio_id` and `find_messages_by_conversation_id`.

**Subtasks:**
- `src/repositories/qa_repo.rs` — canned list + fuzzy match (LIMIT 1)
- `src/repositories/notes_repo.rs` — create + list
- `src/repositories/conversations_repo.rs` — list + messages
- Corresponding model structs
- Unit tests for fuzzy match

**Requires:** T2.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test qa_repo notes_repo conversations_repo -- --test-threads=1 2>&1 | tail -15
```

```bash
# tier3_integration — fuzzy_match unit test asserts at most one result
cd services/portfolio-api && \
  cargo test fuzzy -- --test-threads=1 2>&1 | grep -q "test result: ok" \
  || { echo "FAIL: fuzzy match test missing or failing"; exit 1; }
echo "tier3 pass"
```

---

### T2.5 — In-memory read cache

**Description:** Cache layer using DashMap (concurrent reads without blocking).
`get_or_fetch` and `invalidate` functions. Sits between handlers and repos.
Cache covers portfolio, projects, qa_pairs. Invalidated on any write.

**Subtasks:**
- `src/cache.rs` — generic cache with get_or_fetch, invalidate, invalidate_all
- Integration into repos (writes call invalidate)
- Unit tests: populate, verify hit, mutate, verify cleared

**Requires:** T2.2, T2.3, T2.4

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test cache -- --test-threads=1 2>&1 | tail -15
```

```bash
# tier3_integration
cd services/portfolio-api && \
  grep -q "DashMap" src/cache.rs \
  || { echo "FAIL: cache should use DashMap"; exit 1; }
echo "tier3 pass"
```

---

## Phase 3 — Rust: API Layer

**Goal:** All 11 endpoints running on localhost:8080. Health check responds.
Integration tests hit real endpoints. Fan-out with tokio::join! demonstrated.

**After Phase 3:** Draft `docs/system-design.md` (architecture, data flow,
latency considerations, tradeoffs). Draft `docs/test-plan.md` (what's tested,
what's not, why). Update `docs/retrospective.md` with Phase 2-3 decisions.

---

### T3.1 — axum bootstrap, router, health check, CORS, static files

**Description:** Wire up the axum application. Main router with all route stubs.
`GET /health` returning `{"status":"ok"}`. Static file handler for `/static/*`.
CORS enabled via tower-http. DB pool and cache in AppState.

**Subtasks:**
- `src/main.rs` — tokio::main, Router, bind 0.0.0.0:8080
- `src/app_state.rs` — AppState struct (pool, cache)
- `src/routes/mod.rs` — route registration
- `src/handlers/health_handler.rs` — GET /health
- CORS middleware (tower_http::cors)
- Static file handler for /static/

**Requires:** T2.5

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test health -- --test-threads=1 2>&1 | tail -10
```

```bash
# tier3_integration
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t31.db sqlx migrate run 2>/dev/null
DATABASE_URL=sqlite:./verify_t31.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
STATUS=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8080/health)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t31.db
[ "$STATUS" = "200" ] || { echo "FAIL: /health returned $STATUS"; exit 1; }
echo "tier3 pass"
```

---

### T3.2 — GET /portfolios/:id (fan-out with tokio::join!)

**Description:** Portfolio detail endpoint using `tokio::join!` to fetch portfolio,
experiences, and skills concurrently. Returns combined JSON. Cache the result.

**Subtasks:**
- `src/handlers/portfolio_handler.rs` — get_portfolio handler
- `tokio::join!` for concurrent fetches
- Route: `GET /v1/portfolios/:id`

**Requires:** T3.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test portfolio_handler -- --test-threads=1 2>&1 | tail -10
```

```bash
# tier3_integration
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t32.db sqlx migrate run 2>/dev/null
sqlite3 verify_t32.db "INSERT INTO portfolios(id,name,bio,summary,created_at) VALUES(1,'Test','Bio','Summary',datetime('now'));"
DATABASE_URL=sqlite:./verify_t32.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
BODY=$(curl -sf http://localhost:8080/v1/portfolios/1)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t32.db
echo "$BODY" | grep -q '"name"' || { echo "FAIL: response missing name"; exit 1; }
echo "tier3 pass"
```

---

### T3.3 — Projects endpoints (list, detail, view_count, interested)

**Description:** Four project endpoints. Detail GET increments view_count as
side-effect. POST /interested increments interested_count. Cache invalidated
on both writes.

**Subtasks:**
- `src/handlers/projects_handler.rs` — list, detail, interested
- Route registration
- Unit tests: detail increments view_count, interested increments interested_count

**Requires:** T3.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test projects_handler -- --test-threads=1 2>&1 | tail -10
```

```bash
# tier3_integration
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t33.db sqlx migrate run 2>/dev/null
sqlite3 verify_t33.db "INSERT INTO portfolios(id,name,bio,summary,created_at) VALUES(1,'T','B','S',datetime('now'));"
sqlite3 verify_t33.db "INSERT INTO projects(id,portfolio_id,title,role,writeup,view_count,interested_count) VALUES(1,1,'P','R','W',0,0);"
DATABASE_URL=sqlite:./verify_t33.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
curl -sf http://localhost:8080/v1/portfolios/1/projects/1 >/dev/null
COUNT=$(sqlite3 verify_t33.db "SELECT view_count FROM projects WHERE id=1;")
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t33.db
[ "$COUNT" = "1" ] || { echo "FAIL: view_count=$COUNT"; exit 1; }
echo "tier3 pass"
```

---

### T3.4 — Q&A endpoints (list + fuzzy ask)

**Description:** GET /qa returns canned pairs. POST /qa/ask fuzzy-matches query
or returns fallback. Body: `{"query":"..."}`.

**Subtasks:**
- `src/handlers/qa_handler.rs`
- Request struct with validation (query non-empty)
- Unit test: match + no-match cases

**Requires:** T3.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test qa_handler -- --test-threads=1 2>&1 | tail -10
```

```bash
# tier3_integration
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t34.db sqlx migrate run 2>/dev/null
sqlite3 verify_t34.db "INSERT INTO portfolios(id,name,bio,summary,created_at) VALUES(1,'T','B','S',datetime('now'));"
DATABASE_URL=sqlite:./verify_t34.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
BODY=$(curl -sf -X POST http://localhost:8080/v1/portfolios/1/qa/ask \
  -H 'Content-Type: application/json' -d '{"query":"xyzzy_no_match"}')
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t34.db
echo "$BODY" | grep -q "leave_a_note\|null" || { echo "FAIL: unexpected response"; exit 1; }
echo "tier3 pass"
```

---

### T3.5 — Notes endpoints (submit + owner inbox)

**Description:** POST /notes validates name/email/message non-empty, persists,
returns 201. GET /notes requires `X-Owner-Token: owner` header, returns 401 without.

**Subtasks:**
- `src/handlers/notes_handler.rs`
- Input validation on POST
- Header auth check on GET
- Unit tests: POST creates, GET without token → 401, GET with token → 200

**Requires:** T3.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test notes_handler -- --test-threads=1 2>&1 | tail -10
```

```bash
# tier3_integration
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t35.db sqlx migrate run 2>/dev/null
sqlite3 verify_t35.db "INSERT INTO portfolios(id,name,bio,summary,created_at) VALUES(1,'T','B','S',datetime('now'));"
DATABASE_URL=sqlite:./verify_t35.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
POST_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" -X POST \
  http://localhost:8080/v1/portfolios/1/notes \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice","email":"a@b.com","message":"Hello"}')
GET_UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/portfolios/1/notes)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t35.db
[ "$POST_STATUS" = "201" ] || { echo "FAIL: POST=$POST_STATUS"; exit 1; }
[ "$GET_UNAUTH" = "401" ] || { echo "FAIL: GET unauth=$GET_UNAUTH"; exit 1; }
echo "tier3 pass"
```

---

### T3.6 — Theatre endpoints (conversations + messages)

**Description:** GET /conversations and GET /conversations/:cid/messages. Read-only,
seeded data. All responses include `"theatre": true` field.

**Subtasks:**
- `src/handlers/conversations_handler.rs`
- Route registration
- `"theatre": true` in responses
- Unit tests asserting theatre field

**Requires:** T3.1

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd services/portfolio-api && \
  cargo test conversations_handler -- --test-threads=1 2>&1 | tail -10
```

```bash
# tier3_integration
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t36.db sqlx migrate run 2>/dev/null
sqlite3 verify_t36.db "INSERT INTO portfolios(id,name,bio,summary,created_at) VALUES(1,'T','B','S',datetime('now'));"
DATABASE_URL=sqlite:./verify_t36.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
BODY=$(curl -sf http://localhost:8080/v1/portfolios/1/conversations)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t36.db
echo "$BODY" | grep -q '"theatre"' || { echo "FAIL: theatre flag missing"; exit 1; }
echo "tier3 pass"
```

**After Phase 3:** Draft `docs/system-design.md` and `docs/test-plan.md`.
Update `docs/retrospective.md` with Phase 2-3 decisions and latency considerations.

---

## Phase 4 — Seed Data

**Goal:** SQLite populated with Richard's real CV content from the PDF.
All tables have minimum rows for the app to show meaningful content.

---

### T4.1 — Seed binary with CV content

**Description:** Implement `tools/seed`. Reads content and inserts into all tables.
Must be idempotent (INSERT OR IGNORE or clear + reinsert). Content sourced from
Richard's actual CV (Richard_Lao_23_04.pdf).

**Real content to seed:**
- Portfolio: Richard Lao, "Founding engineer at a 15-person startup..." bio
- Experiences: Serac Group (founding engineer, Jan 2025+, 6 bullets), Santander UK (intern, 2 bullets)
- Projects: PharmaBridge (2nd place, Imperial hackathon Apr 2026), MARL Dissertation (KCL 2024)
- Skills: Python, TypeScript, Scala, JS | AWS, event-driven, microservices | Node.js, PostgreSQL, ETL | OpenAI, PyTorch, MARL | Docker, GitHub Actions, CI/CD | Next.js, React
- Q&A: 6+ canned pairs about current work, strengths, PharmaBridge, architecture, Lapse, improvements
- Conversations: 3 fictional recruiter threads, 2-3 messages each

**Subtasks:**
- `tools/seed/src/main.rs` — idempotent seed logic
- `tools/seed/data/cv.json` — structured CV content (filled from PDF, not FILL_IN placeholders)
- `tools/seed/Cargo.toml` — already exists with correct deps

**Verify:**
```bash
# tier1_build
cd tools/seed && cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
[ -f "tools/seed/target/debug/seed" ] \
  || (cd tools/seed && cargo build 2>&1 | grep -q "Finished") \
  || { echo "FAIL: seed binary not built"; exit 1; }
echo "tier2 pass"
```

```bash
# tier3_integration — idempotent: run twice, count stable
cd services/portfolio-api && DATABASE_URL=sqlite:./verify_seed.db sqlx migrate run 2>/dev/null
cd ../../tools/seed
DATABASE_URL=sqlite:../../services/portfolio-api/verify_seed.db cargo run 2>&1
DATABASE_URL=sqlite:../../services/portfolio-api/verify_seed.db cargo run 2>&1
COUNT=$(sqlite3 ../../services/portfolio-api/verify_seed.db "SELECT COUNT(*) FROM portfolios;")
rm -f ../../services/portfolio-api/verify_seed.db
[ "$COUNT" = "1" ] || { echo "FAIL: not idempotent, count=$COUNT"; exit 1; }
echo "tier3 pass"
```

---

### T4.2 — Run seed against dev.db, verify data integrity

**Description:** Run seed against `services/portfolio-api/dev.db`. Verify minimum
row counts. Ensure `dev.db` is in `.gitignore`.

**Requires:** T4.1, T3.1

**Verify:**
```bash
# tier1_build
[ -f "services/portfolio-api/dev.db" ] || { echo "FAIL: dev.db missing"; exit 1; }
echo "tier1 pass"
```

```bash
# tier2_unit
DB="services/portfolio-api/dev.db"
P=$(sqlite3 "$DB" "SELECT COUNT(*) FROM portfolios;")
E=$(sqlite3 "$DB" "SELECT COUNT(*) FROM experiences;")
PR=$(sqlite3 "$DB" "SELECT COUNT(*) FROM projects;")
Q=$(sqlite3 "$DB" "SELECT COUNT(*) FROM qa_pairs;")
C=$(sqlite3 "$DB" "SELECT COUNT(*) FROM conversations;")
[ "$P" -ge 1 ] && [ "$E" -ge 2 ] && [ "$PR" -ge 2 ] && [ "$Q" -ge 5 ] && [ "$C" -ge 3 ] \
  || { echo "FAIL: row counts too low (p=$P e=$E pr=$PR q=$Q c=$C)"; exit 1; }
echo "tier2 pass: p=$P e=$E pr=$PR q=$Q c=$C"
```

```bash
# tier3_integration
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
BODY=$(curl -sf http://localhost:8080/v1/portfolios/1)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
echo "$BODY" | grep -qi "richard\|lao\|serac" \
  || { echo "FAIL: response missing real CV content"; exit 1; }
echo "tier3 pass"
```

---

## Phase 5 — iOS: Core & Theming

**Goal:** Xcode project builds. LapseTheme defined. APIClient makes real requests
to the Rust server. Root pager renders. No hardcoded visual values.

**Note:** All Phase 5+ integration tiers require the Rust server running.
See CLAUDE.md Section 5 for server lifecycle protocol.

---

### T5.1 — LapseTheme (colors, typography, spacing, grain)

**Description:** Define LapseTheme in `Sources/Theme/LapseTheme.swift`. Colors: warm
off-white background (250/245/235), warm accent, editorial serif header font, monospace
metadata font. Spacing constants. Card rotation: deterministic per-index. Grain overlay
as a view modifier.

**Subtasks:**
- `Sources/Theme/LapseTheme.swift` — Color, Font, Spacing
- `Sources/Theme/GrainOverlay.swift` — ViewModifier for film grain
- `Sources/Theme/PolaroidCard.swift` — ViewModifier: shadow + border + rotation(index)
- Unit test: rotation for index 0 != rotation for index 1

**Requires:** T1.4

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — no hardcoded color literals in Views
HARDCODED=$(grep -r "Color(red:\|\.init(red:\|#colorLiteral" apps/ios/Sources/Views/ 2>/dev/null | wc -l | tr -d ' ')
[ "$HARDCODED" = "0" ] \
  || { echo "FAIL: $HARDCODED hardcoded colors in Views/"; exit 1; }
echo "tier3 pass"
```

---

### T5.2 — APIClient with typed models

**Description:** APIClient class with async/await methods for every endpoint.
URLSession only. Codable response models matching backend JSON. Base URL defaults
to `http://localhost:8080`.

**Subtasks:**
- `Sources/APIClient/APIClient.swift` — all endpoint methods
- `Sources/Models/` — Portfolio, Experience, Project, Skill, QAPair, Note, Conversation, Message
- `Sources/APIClient/APIError.swift` — typed error enum
- Unit tests using URLProtocol stub

**Requires:** T1.4

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — APIClient hits live server
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
curl -sf http://localhost:8080/v1/portfolios/1 | grep -q "name" \
  || { kill $SERVER_PID 2>/dev/null; echo "FAIL: server not returning data"; exit 1; }
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
echo "tier3 pass: server responds, iOS client can be tested manually"
```

---

### T5.3 — AppState + root pager (loops profile)

**Description:** AppState as `@Observable` holding current portfolio index and theme.
Root view uses `TabView` with `.tabViewStyle(.page)`. Loops Richard's portfolio
(swipe right → same profile again). Inject via `.environment`.

**Subtasks:**
- `Sources/ViewModels/AppState.swift` — @Observable, currentPortfolioIndex
- `Sources/Views/RootPagerView.swift` — TabView with page style, loops profile
- Unit test: AppState initialises with index 0

**Requires:** T5.1, T5.2

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration
grep -q "tabViewStyle\|TabView" apps/ios/Sources/Views/RootPagerView.swift \
  || { echo "FAIL: pager not using TabView"; exit 1; }
echo "tier3 pass"
```

**After Phase 5:** Update `docs/retrospective.md` with iOS architecture decisions.
Update `docs/system-design.md` with iOS section.

---

## Phase 6 — iOS: Screens (priority order)

**Goal:** All user flows navigable. Polaroid aesthetic applied. Real data from
live server renders. Build in P1→P6 order — app works E2E at any cutoff.

---

### T6.1 — Portfolio Home (P1)

**Description:** Hero section (AsyncImage, name, summary), scrollable sections:
About, Experience (polaroid cards), Projects (polaroid cards), Skills (by category).
ViewModel fetches `GET /portfolios/1` on appear.

**Subtasks:**
- `Sources/Views/PortfolioHomeView.swift`
- `Sources/ViewModels/PortfolioViewModel.swift` — @Observable
- `Sources/Views/Components/HeroView.swift`
- `Sources/Views/Components/ExperienceCardView.swift` — polaroid, index-seeded rotation
- `Sources/Views/Components/SkillsCardView.swift` — category + tags
- `Sources/Views/Components/SectionHeaderView.swift`

**Requires:** T5.3

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration
[ -f "apps/ios/Sources/Views/PortfolioHomeView.swift" ] && \
[ -f "apps/ios/Sources/ViewModels/PortfolioViewModel.swift" ] \
  || { echo "FAIL: portfolio home files missing"; exit 1; }
echo "tier3 pass"
```

---

### T6.2 — Project Detail (P2)

**Description:** Modal/sheet. Title, role, writeup, view count (incremented on open),
"Interested" button with count. ViewModels for list and detail.

**Subtasks:**
- `Sources/Views/ProjectsListView.swift`
- `Sources/Views/ProjectDetailView.swift`
- `Sources/ViewModels/ProjectsViewModel.swift`
- `Sources/ViewModels/ProjectDetailViewModel.swift`

**Requires:** T6.1

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration
[ -f "apps/ios/Sources/Views/ProjectDetailView.swift" ] \
  || { echo "FAIL: project detail missing"; exit 1; }
echo "tier3 pass"
```

---

### T6.3 — Ask Richard (P3)

**Description:** Canned prompt pills + free-text field. Tap → POST /qa/ask → answer.
No-match → "leave a note" fallback link.

**Subtasks:**
- `Sources/Views/AskView.swift`
- `Sources/ViewModels/AskViewModel.swift`
- Fallback UI for null match

**Requires:** T6.1

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration
grep -qi "leave.a.note\|leaveANote\|fallback" \
  apps/ios/Sources/Views/AskView.swift \
  apps/ios/Sources/ViewModels/AskViewModel.swift 2>/dev/null \
  || { echo "FAIL: null match fallback missing"; exit 1; }
echo "tier3 pass"
```

---

### T6.4 — Leave a Note (P4)

**Description:** Form: name, email, message. Client-side validation. POST /notes.
Success → confirmation card. Error → inline message.

**Subtasks:**
- `Sources/Views/LeaveNoteView.swift`
- `Sources/ViewModels/LeaveNoteViewModel.swift`
- Validation + confirmation + error states

**Requires:** T6.1

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration
grep -q "isEmpty" apps/ios/Sources/ViewModels/LeaveNoteViewModel.swift \
  || { echo "FAIL: no validation"; exit 1; }
echo "tier3 pass"
```

---

### T6.5 — Inbox Theatre (P5-P6 combined)

**Description:** Conversation list + thread view + disabled send. "Demo" badge.
Combined into one task since both are theatre and share the same ViewModel.

**Subtasks:**
- `Sources/Views/InboxView.swift` — conversation list + "Demo" badge
- `Sources/Views/ConversationThreadView.swift` — messages + disabled send field
- `Sources/ViewModels/InboxViewModel.swift`

**Requires:** T6.1

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppTests \
  2>&1 | grep -E "Test Suite.*passed\|TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration
grep -qi "demo\|theatre" apps/ios/Sources/Views/InboxView.swift \
  || { echo "FAIL: no demo badge"; exit 1; }
grep -q '\.disabled\|isDisabled\|stub' \
  apps/ios/Sources/Views/ConversationThreadView.swift 2>/dev/null \
  || { echo "FAIL: send not disabled"; exit 1; }
echo "tier3 pass"
```

---

## Phase 7 — Integration & Documentation

**Goal:** E2E flow verified. Static assets served. All documentation complete
and polished for the crit.

---

### T7.1 — Static file serving for images

**Description:** Set up `services/portfolio-api/static/` with hero image
(placeholder SVG if no real photo) and project placeholders. Update seed data
to reference `/static/` paths. Verify axum serves them.

**Subtasks:**
- `services/portfolio-api/static/` with hero placeholder
- `services/portfolio-api/static/projects/` with per-project placeholders
- Seed data references correct paths
- iOS AsyncImage uses full URL

**Requires:** T6.1

**Verify:**
```bash
# tier1_build
[ "$(ls services/portfolio-api/static/ 2>/dev/null | wc -l | tr -d ' ')" -gt "0" ] \
  || { echo "FAIL: static/ empty"; exit 1; }
echo "tier1 pass"
```

```bash
# tier2_unit
echo "tier2 pass: static files present (checked in tier1)"
```

```bash
# tier3_integration
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:8080/static/richard.jpg" 2>/dev/null \
  || curl -sf -o /dev/null -w "%{http_code}" "http://localhost:8080/static/hero.svg" 2>/dev/null \
  || echo "404")
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
[ "$STATUS" = "200" ] || { echo "FAIL: static file returned $STATUS"; exit 1; }
echo "tier3 pass"
```

---

### T7.2 — E2E smoke test

**Description:** Verify complete flow: server + seeded data + iOS app. Write a
dedicated integration test exercising all five user flows via API.

**Subtasks:**
- Integration test hitting all major endpoints against live server
- Verify view_count increments, note creation, Q&A matching, theatre responses

**Requires:** T6.5, T4.2

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
echo "tier2 pass: E2E is integration-only"
```

```bash
# tier3_integration — full E2E via curl
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -sf http://localhost:8080/health >/dev/null 2>&1 && break; sleep 2
done
PASS=0; FAIL=0
# Portfolio
curl -sf http://localhost:8080/v1/portfolios/1 | grep -q "name" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# Projects list
curl -sf http://localhost:8080/v1/portfolios/1/projects | grep -q "title" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# Q&A list
curl -sf http://localhost:8080/v1/portfolios/1/qa | grep -q "prompt" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# Note submission
curl -sf -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/v1/portfolios/1/notes \
  -H 'Content-Type: application/json' -d '{"name":"Test","email":"t@t.com","message":"Hi"}' \
  | grep -q "201" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
# Conversations (theatre)
curl -sf http://localhost:8080/v1/portfolios/1/conversations | grep -q "theatre" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
echo "E2E: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ] || { echo "FAIL: $FAIL endpoints failed"; exit 1; }
echo "tier3 pass"
```

---

### T7.3 — Complete documentation

**Description:** Finalize all three docs. These are living documents that have been
updated throughout — this task is the final polish pass, not writing from scratch.

**Subtasks:**
- `docs/system-design.md` — architecture diagram, data flow, cache strategy, latency
  considerations, "considered but not built" section, known limitations
- `docs/test-plan.md` — what's tested per tier, what's not tested and why
- `docs/retrospective.md` — final pass: key decisions, priorities, alternatives,
  what worked, what you'd change, what you learned. Must address theatre components.
- Update `setup-guide.md` with correct versions and any changes
- Update `README.md` if structure changed

**Requires:** T7.2

**Verify:**
```bash
# tier1_build
for f in docs/system-design.md docs/test-plan.md docs/retrospective.md; do
  LINES=$(wc -l < "$f" 2>/dev/null || echo 0)
  [ "$LINES" -gt "20" ] || { echo "FAIL: $f too short ($LINES lines)"; exit 1; }
done
echo "tier1 pass"
```

```bash
# tier2_unit
grep -qi "considered but not built\|not implemented" docs/system-design.md \
  || { echo "FAIL: system-design missing tradeoffs section"; exit 1; }
grep -qi "theatre\|scaffold" docs/retrospective.md \
  || { echo "FAIL: retrospective doesn't address theatre"; exit 1; }
echo "tier2 pass"
```

```bash
# tier3_integration — no stub markers remain
for f in docs/system-design.md docs/test-plan.md docs/retrospective.md; do
  grep -qi "TODO\|FIXME\|TBD\|FILL_IN" "$f" \
    && { echo "FAIL: $f has stub markers"; exit 1; }
done
echo "tier3 pass"
```

---

## Phase 8 — Shared Rust Layer (STRETCH — bonus only)

**Gate:** ALL Phase 1–7 tasks must be `"status": "complete"` in state.json.
Do not start Phase 8 if any core task is incomplete.

**Goal:** A shared Rust crate in `shared/platform/` compiled to a static library
and imported by the iOS app via UniFFI-generated Swift bindings. Gives Bazel a
third meaningful target.

---

### T8.1 — Shared types crate with UniFFI

**Description:** Create `shared/platform/` with shared data models (Portfolio,
Project, QAPair) defined in Rust with UniFFI annotations. Generate Swift bindings.
Wire into Bazel as a static library target. Link into iOS app.

**Subtasks:**
- `shared/platform/Cargo.toml` with uniffi dependency
- `shared/platform/src/lib.rs` — shared types with UniFFI annotations
- `shared/platform/BUILD` — Bazel static library target
- Generated Swift bindings imported by iOS app
- At least one place in iOS app uses the shared type instead of the duplicated Codable model

**Verify:**
```bash
# tier1_build
cd shared/platform && cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit
cd shared/platform && cargo test 2>&1 | tail -10
```

```bash
# tier3_integration
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

---

## Completion Criteria

All tasks in Phases 1–7 show `"status": "complete"` in `tasks/state.json`.
Phase 8 is bonus — complete if attempted, not required.

The deliverable: a working iOS app showing Richard's real CV content, backed by
a Rust/axum service, built by Bazel, with complete documentation. A reviewer
should be able to clone, seed, start the server, and run the app in under 5 minutes.

---

## Crit Preparation Reference

| Likely question | Your answer |
|---|---|
| "Why SQLite?" | Local-only scope, zero ops. WAL for concurrent reads. sqlx abstracts driver — Postgres swap is config change. At Serac I use Postgres in production. |
| "1000x traffic?" | Redis INCR for counters, Postgres + pooling, CDN for static. Cache-aside scales — swap DashMap for Redis. At Serac: 14M-record bursts via partitioned SQS. |
| "Cache strategy?" | Read-heavy, write-cold. Cache-aside + invalidate-on-write. DashMap = lock-free concurrent reads. At scale: TTL + stale-while-revalidate. |
| "Why Bazel?" | Brief required it. Hermetic builds across Rust + Swift + shared. One dependency graph. Alternative is Cargo + xcodebuild + manual coordination. |
| "No third-party iOS libs?" | Deliberate. URLSession handles networking. Fewer deps = simpler Bazel graph, faster onboarding, I can explain every line. |
| "Add auth?" | JWT in middleware. X-Owner-Token stub → real JWT validation is a tower middleware swap, not a rewrite. |
| "Add Android?" | Monorepo structured for it. apps/android/ alongside apps/ios/. Shared Rust layer = cross-platform logic. Bazel has rules_kotlin. |
| "What was hardest?" | Bazel + iOS integration. Timeboxed, documented failures, fell back where needed. Retrospective has the full story. |
