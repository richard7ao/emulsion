# Portfolio App — Unified Spec & Execution Plan
#
# WHAT THIS IS: The authoritative task catalog for the autonomous build agent.
# Defines every phase, task, subtask, and three-tier verification command.
# This file is READ-ONLY after initial commit — never modify it mid-build.
#
# HOW TO USE: The CLAUDE.md boot protocol (Step 4) points here. Find the task
# matching `current_task` in state.json, read it fully, then implement and verify.
# The agent works through tasks in the order listed. Do not skip or reorder.
#
# RELATED: prd.md (product requirements), CLAUDE.md (agent operating manual),
#          tasks/state.json (runtime progress), .claude/memory.md (session knowledge)

---

## Overview

This spec covers two things in one document: **what to build** (iOS portfolio app + Rust
backend + Bazel monorepo, as specified in prd.md) and **how an agent verifies each step**
(three-tier deterministic gates per task). It is the sole source of truth for task ordering
and exit criteria.

Product summary: Native iOS app (SwiftUI, iOS 17+) backed by a Rust/axum service, built
in a Bazel monorepo. Polaroid/film aesthetic. Real CV content. Agent-optimised structure.
Full PRD: `prd.md`.

---

## Verification Rules (applies to every task below)

```
TIER 1 — Build Check     Fast (~5s).   Must exit 0 before tier 2 runs.
TIER 2 — Unit Tests      Medium (~30s). Must exit 0 before tier 3 runs.
TIER 3 — Integration     Slow (~60s).  All three must pass to mark task complete.
```

Any tier exiting non-zero = task failed. Write post-mortem, commit, stop.
No exceptions, no subjective overrides.

---

## Phase 1 — Repo Foundation & Bazel

**Goal:** Working monorepo skeleton. Both Bazel targets build without error. Directory
structure matches PRD §11. READMEs and AGENTS.md exist and are non-empty.

---

### T1.1 — Directory scaffold, READMEs, AGENTS.md

**Description:** Create the full directory tree from PRD §11. Write a short README.md in
each top-level package directory. Write AGENTS.md at repo root with directory map,
conventions ("where to add X"), and naming patterns (`*_handler.rs`, `*View.swift`,
`*ViewModel.swift`). Write docs/system-design.md, docs/test-plan.md, docs/retrospective.md
as stubs with section headers only.

**Subtasks:**
- `apps/ios/README.md` — purpose, build command, test command
- `services/portfolio-api/README.md` — purpose, build command, test command
- `shared/schemas/README.md` — purpose, extension point note
- `tools/seed/README.md` — purpose, how to run
- `AGENTS.md` — directory map, naming conventions, "where to add X" patterns
- `docs/system-design.md` stub
- `docs/test-plan.md` stub
- `docs/retrospective.md` stub

**Verify:**
```bash
# tier1_build — directory structure exists
for d in apps/ios services/portfolio-api shared/schemas tools/seed docs; do
  [ -d "$d" ] || { echo "MISSING: $d"; exit 1; }
done
echo "tier1 pass: all directories present"
```

```bash
# tier2_unit — all required files exist and are non-empty
for f in AGENTS.md apps/ios/README.md services/portfolio-api/README.md \
         shared/schemas/README.md tools/seed/README.md \
         docs/system-design.md docs/test-plan.md docs/retrospective.md; do
  [ -s "$f" ] || { echo "MISSING OR EMPTY: $f"; exit 1; }
done
echo "tier2 pass: all scaffold files present and non-empty"
```

```bash
# tier3_integration — AGENTS.md has required sections
grep -q "conventions\|Conventions" AGENTS.md || { echo "AGENTS.md missing conventions section"; exit 1; }
grep -q "_handler\|_view\|ViewModel" AGENTS.md || { echo "AGENTS.md missing naming patterns"; exit 1; }
echo "tier3 pass: AGENTS.md has conventions and naming patterns"
```

---

### T1.2 — WORKSPACE/MODULE.bazel with rules_rust and rules_apple

**Description:** Create MODULE.bazel (Bzlmod) at repo root with `bazel_dep` entries for
`rules_rust` and `rules_apple`. Pin versions explicitly. Create a minimal `BUILD` file at
repo root. Rust toolchain registration should target stable. Document chosen versions in
`.claude/memory.md` under Decisions.

**Subtasks:**
- `MODULE.bazel` with rules_rust (latest stable), rules_apple (3.x — see Gotchas after T1.4)
- Root `BUILD` file (can be empty with a comment)
- `.bazelversion` pinned to current stable Bazel

**Verify:**
```bash
# tier1_build — bazel can parse the workspace
bazel info workspace 2>&1 | grep -v "^WARNING" | grep -v "^DEBUG" | head -5
echo "tier1 pass: bazel workspace parsed"
```

```bash
# tier2_unit — bazel query resolves with no errors
bazel query '//...' 2>&1 | grep -v "^WARNING\|^DEBUG\|^Loading\|^Analyzing" | head -20
echo "tier2 pass: bazel query succeeded"
```

```bash
# tier3_integration — .bazelversion exists and is pinned
[ -f ".bazelversion" ] && grep -E "^[0-9]+\.[0-9]+" .bazelversion \
  || { echo "MISSING or malformed .bazelversion"; exit 1; }
echo "tier3 pass: .bazelversion pinned"
```

---

### T1.3 — Bazel target //services/portfolio-api:server

**Description:** Create a minimal Rust binary at `services/portfolio-api/src/main.rs` that
compiles (can be a "hello world" axum server — full implementation comes in Phase 3). Wire it
up in `services/portfolio-api/BUILD` with a `rust_binary` target named `server`. The target
must build cleanly via `bazel build //services/portfolio-api:server`.

**Subtasks:**
- `services/portfolio-api/Cargo.toml` with axum, tokio, sqlx dependencies
- `services/portfolio-api/src/main.rs` (stub: start tokio runtime, bind port 8080)
- `services/portfolio-api/BUILD` with `rust_binary(name = "server", ...)`

**Verify:**
```bash
# tier1_build
bazel build //services/portfolio-api:server 2>&1 | grep -E "Build (completed|FAILED)"
```

```bash
# tier2_unit — cargo build also passes (used for faster iteration in later phases)
cd services/portfolio-api && cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier3_integration — binary exists and is executable
[ -f "bazel-bin/services/portfolio-api/server" ] \
  || [ -f "services/portfolio-api/target/debug/portfolio-api" ] \
  || { echo "Binary not found"; exit 1; }
echo "tier3 pass: server binary exists"
```

---

### T1.4 — Bazel target //apps/ios:app

**Description:** Wire up an iOS app Bazel target using rules_apple. Create a minimal SwiftUI
app (single ContentView with "Hello Lapse" text). The target must build for iOS Simulator.

**FALLBACK:** If this target fails to build after 3 hours of debugging, create an Xcode
project at `apps/ios/PortfolioApp.xcodeproj` instead. Write the failure to `.claude/memory.md`
under Gotchas. All Phase 5/6/7 verify commands use `xcodebuild` regardless of this outcome.
Bazel continues to own the Rust service.

**Subtasks:**
- `apps/ios/BUILD` with `ios_application` target (name = "app")
- `apps/ios/Sources/App.swift` and `apps/ios/Sources/ContentView.swift` stubs
- `apps/ios/Info.plist`

**Verify:**
```bash
# tier1_build — attempt Bazel first, fall back to xcodebuild
if bazel build //apps/ios:app --apple_platform_type=ios_simulator 2>&1 \
   | grep -q "Build completed"; then
  echo "tier1 pass: Bazel iOS build succeeded"
elif [ -d "apps/ios/PortfolioApp.xcodeproj" ]; then
  xcodebuild -scheme PortfolioApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
else
  echo "tier1 FAIL: neither Bazel nor Xcode project found"; exit 1
fi
```

```bash
# tier2_unit — scheme resolves in xcodebuild (covers both Bazel-generated and native xcodeproj)
xcodebuild -list -project apps/ios/PortfolioApp.xcodeproj 2>/dev/null \
  | grep -q "PortfolioApp" \
  || bazel query //apps/ios:app 2>&1 | grep -q "//apps/ios:app" \
  || { echo "tier2 FAIL: iOS target not resolvable"; exit 1; }
echo "tier2 pass: iOS target resolvable"
```

```bash
# tier3_integration — app compiles for simulator without error
xcodebuild -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -allowProvisioningUpdates \
  build 2>&1 | tail -3 | grep -q "SUCCEEDED" \
  || { echo "tier3 FAIL: simulator build failed"; exit 1; }
echo "tier3 pass: app builds for simulator"
```

---

## Phase 2 — Rust: Data Layer

**Goal:** All 8 SQLite tables migrated and queryable. Repository structs for every table with
full CRUD where appropriate. In-memory cache wired up. All unit tests green.

---

### T2.1 — SQLite schema + sqlx migrations

**Description:** Create all 8 migrations from PRD §6. Use sqlx migrate with numbered files in
`services/portfolio-api/migrations/`. Tables: portfolios, experiences, projects, skills,
qa_pairs, notes, conversations, messages. Enable WAL mode in the db initialisation code
(not in migrations — see CLAUDE.md constraints). Run `cargo sqlx prepare` and commit the
`.sqlx/` directory for offline mode.

**Subtasks:**
- `services/portfolio-api/migrations/0001_initial.sql` — all 8 tables
- `services/portfolio-api/src/db.rs` — pool init, WAL mode pragma, `DATABASE_URL` from env
- `services/portfolio-api/.sqlx/` — offline query metadata (run `cargo sqlx prepare`)
- `SQLX_OFFLINE=true` added to any `.env.example`

**Verify:**
```bash
# tier1_build
cd services/portfolio-api && cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit — migrations run cleanly against a fresh test DB
cd services/portfolio-api && \
  DATABASE_URL=sqlite:./test_verify.db cargo sqlx migrate run 2>&1 && \
  echo "migrations ran" && rm -f test_verify.db
```

```bash
# tier3_integration — all 8 tables present after migration
cd services/portfolio-api && \
  DATABASE_URL=sqlite:./verify.db cargo sqlx migrate run 2>&1 && \
  TABLES=$(sqlite3 verify.db ".tables") && \
  rm -f verify.db && \
  for t in portfolios experiences projects skills qa_pairs notes conversations messages; do
    echo "$TABLES" | grep -qw "$t" || { echo "MISSING TABLE: $t"; exit 1; }
  done && \
  echo "tier3 pass: all 8 tables present"
```

---

### T2.2 — Portfolio, Experience, Skills repositories

**Description:** Implement repository structs and query functions for the portfolios,
experiences, and skills tables. Each repository is its own file in
`services/portfolio-api/src/repositories/`. Expose `find_by_id` for portfolio;
`find_by_portfolio_id` for experience and skills. Use sqlx typed queries.

**Subtasks:**
- `src/repositories/portfolio_repo.rs` — `find_by_id(pool, id) -> Result<Portfolio>`
- `src/repositories/experience_repo.rs` — `find_by_portfolio_id(pool, id) -> Result<Vec<Experience>>`
- `src/repositories/skills_repo.rs` — `find_by_portfolio_id(pool, id) -> Result<Vec<Skill>>`
- `src/models/` — corresponding model structs matching migration columns
- Unit tests in each file using `#[sqlx::test]` with a test fixture

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
# tier3_integration — module files exist and export the expected functions
cd services/portfolio-api && \
  grep -r "pub fn find_by_id\|pub async fn find_by_id" src/repositories/portfolio_repo.rs \
  || { echo "find_by_id not found in portfolio_repo"; exit 1; }
grep -r "pub fn find_by_portfolio_id\|pub async fn find_by_portfolio_id" \
  src/repositories/experience_repo.rs src/repositories/skills_repo.rs \
  || { echo "find_by_portfolio_id missing"; exit 1; }
echo "tier3 pass: repository function signatures present"
```

---

### T2.3 — Projects repository with atomic counters

**Description:** Implement the projects repository. `find_by_portfolio_id`, `find_by_id`,
`increment_view_count`, `increment_interested_count`. Counter functions MUST use
`UPDATE projects SET col = col + 1 WHERE id = ?` — never read-modify-write.

**Subtasks:**
- `src/repositories/projects_repo.rs` with all four functions
- `src/models/project.rs` — Project struct
- Unit tests covering both counter increment functions (verify count goes up by 1)

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
# tier3_integration — atomic UPDATE pattern enforced (no read-modify-write)
cd services/portfolio-api && \
  grep -E "SET (view_count|interested_count) = (view_count|interested_count) \+" \
    src/repositories/projects_repo.rs \
  || { echo "FAIL: counter increment is not atomic SQL"; exit 1; }
echo "tier3 pass: atomic counter pattern confirmed"
```

---

### T2.4 — Q&A, Notes, Theatre repositories

**Description:** Implement repositories for qa_pairs, notes, conversations, and messages.
Q&A needs `find_canned_by_portfolio_id` and `fuzzy_match(pool, portfolio_id, query)` — fuzzy
match uses `LIKE '%query%'` on the prompt column, returns the best single row or None.
Notes needs `create` and `find_by_portfolio_id`. Theatre (conversations + messages) needs
read-only `find_by_portfolio_id` and `find_by_conversation_id`.

**Subtasks:**
- `src/repositories/qa_repo.rs` — canned list + fuzzy match
- `src/repositories/notes_repo.rs` — create + list
- `src/repositories/conversations_repo.rs` — list + messages by conversation
- Corresponding model structs
- Unit tests for fuzzy match (should return closest match, not all matches)

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
# tier3_integration — fuzzy match returns at most one result
cd services/portfolio-api && \
  grep -E "LIMIT 1\|\.first()\|\.next()" src/repositories/qa_repo.rs \
  || { echo "FAIL: fuzzy_match may return multiple rows"; exit 1; }
echo "tier3 pass: fuzzy match bounded to single result"
```

---

### T2.5 — In-memory read cache

**Description:** Implement a cache layer over the repositories for portfolio, projects, and
qa_pairs. Use `Arc<RwLock<HashMap<u64, CachedValue>>>` (or dashmap if preferred — document
choice in memory.md). Cache is populated on first read and invalidated on any write. Expose
`get_or_fetch` and `invalidate` functions. The cache sits between handlers and repos.

**Subtasks:**
- `src/cache.rs` — generic cache struct with get_or_fetch, invalidate, invalidate_all
- Integration into portfolio, projects, qa repos (writes call invalidate)
- Unit tests: populate cache, verify hit, mutate via repo, verify cache is cleared

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
# tier3_integration — cache module uses RwLock or dashmap (not Mutex — would block reads)
cd services/portfolio-api && \
  grep -E "RwLock|DashMap" src/cache.rs \
  || { echo "FAIL: cache uses blocking Mutex — must use RwLock or DashMap"; exit 1; }
echo "tier3 pass: cache uses non-blocking read primitive"
```

---

## Phase 3 — Rust: API Layer

**Goal:** All 10 endpoints from PRD §7 running on localhost:8080. Health check responds.
Integration tests hit real endpoints. Fan-out with tokio::join! demonstrated in portfolio endpoint.

---

### T3.1 — axum bootstrap, router, health check, static files

**Description:** Wire up the axum application. Create the main router with all route stubs
returning 501. Add a `GET /health` returning `{"status":"ok"}`. Add a static file handler
for `GET /static/*path` serving from `./static/` on the filesystem. Initialise the DB pool
and cache in `AppState`. Start with tokio::main.

**Subtasks:**
- `src/main.rs` — tokio::main, axum Router, bind 0.0.0.0:8080
- `src/app_state.rs` — AppState struct (pool, cache)
- `src/routes/mod.rs` — route registration
- `src/handlers/health_handler.rs` — GET /health
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
# tier3_integration — server starts and health endpoint responds
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t31.db cargo sqlx migrate run 2>/dev/null
DATABASE_URL=sqlite:./verify_t31.db cargo run &
SERVER_PID=$!
sleep 3
STATUS=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8080/health)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t31.db
[ "$STATUS" = "200" ] || { echo "FAIL: /health returned $STATUS"; exit 1; }
echo "tier3 pass: health endpoint returns 200"
```

---

### T3.2 — GET /portfolios/:id (fan-out with tokio::join!)

**Description:** Implement the portfolio detail endpoint. Must use `tokio::join!` to fetch
portfolio bio, experiences, and skills in parallel — even though SQLite is single-writer,
this demonstrates the concurrency pattern. Returns a single JSON response combining all three.
Cache the result via the cache layer.

**Subtasks:**
- `src/handlers/portfolio_handler.rs` — get_portfolio handler
- `tokio::join!(portfolio_repo::find_by_id, experience_repo::find_by_portfolio_id, skills_repo::find_by_portfolio_id)`
- Mapped to `GET /v1/portfolios/:id`
- Integration test: seed one row, hit endpoint, assert all three sections present in response

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
# tier3_integration — endpoint returns JSON with expected top-level keys
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t32.db cargo sqlx migrate run 2>/dev/null
sqlite3 verify_t32.db "INSERT INTO portfolios(id,name,bio,summary) VALUES(1,'Test','Bio','Summary');"
DATABASE_URL=sqlite:./verify_t32.db cargo run &
SERVER_PID=$!; sleep 3
BODY=$(curl -sf http://localhost:8080/v1/portfolios/1)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t32.db
echo "$BODY" | grep -q '"name"' || { echo "FAIL: response missing 'name'"; exit 1; }
echo "tier3 pass: portfolio endpoint returns JSON with name field"
```

---

### T3.3 — Projects endpoints (list, detail, view_count, interested)

**Description:** Implement four project endpoints:
`GET /v1/portfolios/:id/projects` — list all projects.
`GET /v1/portfolios/:id/projects/:pid` — detail; side-effect: increment view_count.
`POST /v1/portfolios/:id/projects/:pid/interested` — increment interested_count, return updated count.
Cache invalidated on both counter increments.

**Subtasks:**
- `src/handlers/projects_handler.rs` with all four handler functions
- Route registration in routes/mod.rs
- Unit tests: detail endpoint increments view_count; interested increments interested_count

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
# tier3_integration — view_count increments on detail GET
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t33.db cargo sqlx migrate run 2>/dev/null
sqlite3 verify_t33.db "INSERT INTO portfolios(id,name,bio,summary) VALUES(1,'T','B','S');"
sqlite3 verify_t33.db "INSERT INTO projects(id,portfolio_id,title,role,writeup,view_count,interested_count) VALUES(1,1,'P','R','W',0,0);"
DATABASE_URL=sqlite:./verify_t33.db cargo run &
SERVER_PID=$!; sleep 3
curl -sf http://localhost:8080/v1/portfolios/1/projects/1 >/dev/null
COUNT=$(sqlite3 verify_t33.db "SELECT view_count FROM projects WHERE id=1;")
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t33.db
[ "$COUNT" = "1" ] || { echo "FAIL: view_count is $COUNT, expected 1"; exit 1; }
echo "tier3 pass: view_count incremented to 1"
```

---

### T3.4 — Q&A endpoints (list + fuzzy ask)

**Description:**
`GET /v1/portfolios/:id/qa` — return all canned Q&A pairs.
`POST /v1/portfolios/:id/qa/ask` — body: `{"query": "..."}`. Runs fuzzy match. Returns
matched Q&A pair or `{"match": null, "fallback": "leave_a_note"}` if no match.

**Subtasks:**
- `src/handlers/qa_handler.rs`
- Request struct for ask body with validation (query must be non-empty)
- Unit test: ask with a query that matches a canned prompt, assert answer returned

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
# tier3_integration — ask with no match returns fallback, not 500
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t34.db cargo sqlx migrate run 2>/dev/null
sqlite3 verify_t34.db "INSERT INTO portfolios(id,name,bio,summary) VALUES(1,'T','B','S');"
DATABASE_URL=sqlite:./verify_t34.db cargo run &
SERVER_PID=$!; sleep 3
BODY=$(curl -sf -X POST http://localhost:8080/v1/portfolios/1/qa/ask \
  -H 'Content-Type: application/json' -d '{"query":"xyzzy_no_match"}')
STATUS=$?
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t34.db
[ $STATUS -eq 0 ] || { echo "FAIL: ask endpoint returned non-200"; exit 1; }
echo "$BODY" | grep -q "leave_a_note\|null" || { echo "FAIL: unexpected response body"; exit 1; }
echo "tier3 pass: unmatched ask returns fallback"
```

---

### T3.5 — Notes endpoints (submit + owner inbox)

**Description:**
`POST /v1/portfolios/:id/notes` — body: `{name, email, message}`. Validate all three fields
non-empty. Persist to notes table. Return 201.
`GET /v1/portfolios/:id/notes` — header auth stub: check `X-Owner-Token: owner` (hardcoded
for demo). Return 401 if missing. Return all notes for the portfolio.

**Subtasks:**
- `src/handlers/notes_handler.rs`
- Input validation on POST (name, email, message required)
- Header check on GET (X-Owner-Token)
- Unit tests: POST creates note; GET without token returns 401; GET with token returns notes

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
# tier3_integration — POST creates note; GET without token returns 401
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t35.db cargo sqlx migrate run 2>/dev/null
sqlite3 verify_t35.db "INSERT INTO portfolios(id,name,bio,summary) VALUES(1,'T','B','S');"
DATABASE_URL=sqlite:./verify_t35.db cargo run &
SERVER_PID=$!; sleep 3
POST_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" -X POST \
  http://localhost:8080/v1/portfolios/1/notes \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice","email":"a@b.com","message":"Hello"}')
GET_UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/portfolios/1/notes)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t35.db
[ "$POST_STATUS" = "201" ] || { echo "FAIL: POST notes returned $POST_STATUS"; exit 1; }
[ "$GET_UNAUTH" = "401" ] || { echo "FAIL: GET notes without token returned $GET_UNAUTH"; exit 1; }
echo "tier3 pass: notes POST=201, GET unauthenticated=401"
```

---

### T3.6 — Theatre endpoints (conversations + messages)

**Description:**
`GET /v1/portfolios/:id/conversations` — returns seeded conversations (read-only, no writes).
`GET /v1/portfolios/:id/conversations/:cid/messages` — returns seeded messages.
These endpoints exist to support the Inbox theatre screen. Data is seeded only, never written
via API. Add a visible `"theatre": true` field to all responses from these endpoints.

**Subtasks:**
- `src/handlers/conversations_handler.rs`
- Route registration
- `"theatre": true` in all response bodies
- Unit tests asserting `theatre` field presence

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
# tier3_integration — conversations endpoint responds and includes theatre flag
cd services/portfolio-api
DATABASE_URL=sqlite:./verify_t36.db cargo sqlx migrate run 2>/dev/null
sqlite3 verify_t36.db "INSERT INTO portfolios(id,name,bio,summary) VALUES(1,'T','B','S');"
DATABASE_URL=sqlite:./verify_t36.db cargo run &
SERVER_PID=$!; sleep 3
BODY=$(curl -sf http://localhost:8080/v1/portfolios/1/conversations)
STATUS=$?
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null; rm -f verify_t36.db
[ $STATUS -eq 0 ] || { echo "FAIL: conversations endpoint returned error"; exit 1; }
echo "$BODY" | grep -q '"theatre"' || { echo "FAIL: theatre flag missing from response"; exit 1; }
echo "tier3 pass: conversations returns with theatre flag"
```

---

## Phase 4 — Seed Data

**Goal:** SQLite populated with Richard's real CV content. All tables have at least the
minimum rows for the app to show meaningful content.

---

### T4.1 — Seed binary with CV content

**Description:** Implement the `tools/seed` Rust binary. It reads CV content from
`tools/seed/data/cv.json` (or inline Rust structs — document choice) and inserts into all
tables. Must be idempotent: running twice does not duplicate rows (use INSERT OR IGNORE or
clear + reinsert). Content: portfolio bio from Richard's CV summary, 3+ experiences,
2+ projects (PharmaBridge, MARL dissertation), skills by category, 5+ canned Q&A pairs,
3+ seeded conversations with 2+ messages each.

**Subtasks:**
- `tools/seed/src/main.rs` — idempotent seed logic
- `tools/seed/data/` — CV content (JSON or inline)
- Content: real data from prd.md (Richard Lao, Serac Tech, etc.)
- `tools/seed/Cargo.toml` sharing workspace deps

**Verify:**
```bash
# tier1_build
cd tools/seed && cargo build 2>&1 | grep -E "^error|Finished"
```

```bash
# tier2_unit — binary exists
[ -f "tools/seed/target/debug/seed" ] \
  || cargo build --manifest-path tools/seed/Cargo.toml 2>&1 | grep -q "Finished" \
  || { echo "FAIL: seed binary not built"; exit 1; }
echo "tier2 pass: seed binary built"
```

```bash
# tier3_integration — seed is idempotent (run twice, count stays same)
cd tools/seed
DATABASE_URL=sqlite:../../services/portfolio-api/verify_seed.db \
  cargo sqlx migrate run --source ../../services/portfolio-api/migrations 2>/dev/null
DATABASE_URL=sqlite:../../services/portfolio-api/verify_seed.db cargo run
DATABASE_URL=sqlite:../../services/portfolio-api/verify_seed.db cargo run
COUNT=$(sqlite3 ../../services/portfolio-api/verify_seed.db "SELECT COUNT(*) FROM portfolios;")
rm -f ../../services/portfolio-api/verify_seed.db
[ "$COUNT" -ge "1" ] || { echo "FAIL: portfolios table empty after seed"; exit 1; }
[ "$COUNT" -le "2" ] || { echo "FAIL: seed not idempotent, count=$COUNT"; exit 1; }
echo "tier3 pass: seed is idempotent, portfolio count=$COUNT"
```

---

### T4.2 — Run seed against dev.db, verify data integrity

**Description:** Run the seed binary against the primary dev database at
`services/portfolio-api/dev.db`. Verify row counts meet minimums for the app to function.
This database is what the server uses during local development.

**Subtasks:**
- Run `tools/seed` against `services/portfolio-api/dev.db`
- Verify minimum row counts
- Add `dev.db` to `.gitignore` (binary artefact, not source)

**Requires:** T4.1, T3.1

**Verify:**
```bash
# tier1_build — dev.db exists after seed
[ -f "services/portfolio-api/dev.db" ] || { echo "FAIL: dev.db missing"; exit 1; }
echo "tier1 pass: dev.db present"
```

```bash
# tier2_unit — minimum row counts
DB="services/portfolio-api/dev.db"
for check in \
  "SELECT COUNT(*) FROM portfolios WHERE COUNT >= 1" \
  "SELECT COUNT(*) >= 3 FROM experiences" \
  "SELECT COUNT(*) >= 2 FROM projects" \
  "SELECT COUNT(*) >= 5 FROM qa_pairs" \
  "SELECT COUNT(*) >= 3 FROM conversations"; do
  true  # checked in tier3
done
sqlite3 "$DB" "SELECT COUNT(*) FROM portfolios;" | xargs test 0 -lt \
  || { echo "FAIL: portfolios empty"; exit 1; }
sqlite3 "$DB" "SELECT COUNT(*) FROM qa_pairs;" | xargs -I{} sh -c '[ {} -ge 5 ]' \
  || { echo "FAIL: fewer than 5 qa_pairs"; exit 1; }
echo "tier2 pass: row counts meet minimums"
```

```bash
# tier3_integration — server starts with seeded db and portfolio endpoint returns real content
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!; sleep 3
BODY=$(curl -sf http://localhost:8080/v1/portfolios/1)
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
echo "$BODY" | grep -qi "richard\|lao\|serac" \
  || { echo "FAIL: portfolio response doesn't contain real CV content"; exit 1; }
echo "tier3 pass: seeded portfolio returns real content"
```

---

## Phase 5 — iOS: Core & Theming

**Goal:** Xcode project (or Bazel-built) builds cleanly. LapseTheme defined. APIClient makes
real requests to the Rust server. Root pager renders. No hardcoded values anywhere.

**Note:** All Phase 5+ verify tiers assume the Rust server can be started. CLAUDE.md Section 5
defines the server lifecycle protocol.

---

### T5.1 — Xcode project scaffold and folder structure

**Description:** Create the iOS app project with a clean folder structure matching MVVM-lite.
Folders: `Views/`, `ViewModels/`, `APIClient/`, `Models/`, `Theme/`, `Resources/`.
App target: iOS 17+. Bundle ID: `com.lapse.portfolio`. Scheme: `PortfolioApp`.
Entry point: `PortfolioApp.swift` with `@main App` struct.

**Subtasks:**
- `apps/ios/PortfolioApp.xcodeproj` (or Bazel equivalent) with two test targets:
  `PortfolioAppTests` (unit tests) and `PortfolioAppIntegrationTests` (live-server tests)
- Folder structure with placeholder files
- `apps/ios/Sources/PortfolioApp.swift` — @main App struct
- `apps/ios/Sources/Views/ContentView.swift` — placeholder "Hello Lapse"

**Requires:** T4.2

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -allowProvisioningUpdates \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit — expected folders exist
for d in apps/ios/Sources/Views apps/ios/Sources/ViewModels \
          apps/ios/Sources/APIClient apps/ios/Sources/Models \
          apps/ios/Sources/Theme; do
  [ -d "$d" ] || { echo "MISSING FOLDER: $d"; exit 1; }
done
echo "tier2 pass: all source folders present"
```

```bash
# tier3_integration — app boots in simulator without immediate crash
xcrun simctl boot "iPhone 16" 2>/dev/null || true
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -allowProvisioningUpdates \
  test 2>&1 | grep -E "TEST (SUCCEEDED|FAILED)" \
  || echo "tier3 pass: build succeeded (no tests yet, that is expected)"
```

---

### T5.2 — LapseTheme (colors, typography, spacing, grain)

**Description:** Define `LapseTheme` as a struct/enum in `Sources/Theme/LapseTheme.swift`.
Colors: warm off-white background (250/245/235), warm accent, editorial serif header font
(New York or system serif), monospace metadata font. Spacing constants. Card rotation:
deterministic per-index (never random on redraw). Grain overlay: a subtle view modifier using
`.overlay` with noise pattern and `.blendMode(.overlay)`.

**Subtasks:**
- `Sources/Theme/LapseTheme.swift` — Color, Font, Spacing enums/structs
- `Sources/Theme/GrainOverlay.swift` — ViewModifier for film grain
- `Sources/Theme/PolaroidCard.swift` — ViewModifier: shadow + border + rotation(index)
- Unit test: `.rotation(index: 0)` != `.rotation(index: 1)` (cards differ per index)

**Requires:** T5.1

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
  -only-testing:PortfolioAppTests/ThemeTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — no hardcoded color literals in View files
HARDCODED=$(grep -r "Color(red:\|\.init(red:\|#colorLiteral" apps/ios/Sources/Views/ 2>/dev/null | wc -l)
[ "$HARDCODED" -eq "0" ] \
  || { echo "FAIL: $HARDCODED hardcoded color literals found in Views/"; exit 1; }
echo "tier3 pass: no hardcoded colors in Views"
```

---

### T5.3 — APIClient with typed models

**Description:** Implement `APIClient` as a class/struct with async/await methods matching
every endpoint from Phase 3. Use `URLSession` only — no third-party networking. Define
`Codable` response models in `Sources/Models/` matching the backend JSON exactly.
Base URL configured via `Info.plist` key `APIBaseURL` defaulting to `http://localhost:8080`.

**Subtasks:**
- `Sources/APIClient/APIClient.swift` — all endpoint methods
- `Sources/Models/` — Portfolio, Experience, Project, Skill, QAPair, Note, Conversation, Message
- `Sources/APIClient/APIError.swift` — typed error enum
- Unit tests using URLProtocol stub: one test per endpoint method

**Requires:** T5.1

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
  -only-testing:PortfolioAppTests/APIClientTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — APIClient hits live server and decodes portfolio response
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!; sleep 3
# Run a dedicated integration test that calls the live server
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppIntegrationTests/LiveAPITests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
RESULT=$?
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
exit $RESULT
```

---

### T5.4 — AppState + root HorizontalPager

**Description:** Implement `AppState` as an `ObservableObject` holding the current portfolio
index and theme. Wrap the root view in a `TabView` with `tabViewStyle(.page)` (horizontal
pager). Show Richard's portfolio on page 0. Swipe right reveals a placeholder "next portfolio"
card with a "+" visual — demonstrates the extension point. Inject `AppState` via `.environmentObject`.

**Subtasks:**
- `Sources/ViewModels/AppState.swift` — ObservableObject with currentPortfolioIndex
- `Sources/Views/RootPagerView.swift` — TabView with page style, two pages
- `Sources/Views/PlaceholderPortfolioView.swift` — "next portfolio" extension point card
- Unit test: AppState initialises with index 0

**Requires:** T5.2, T5.3

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
  -only-testing:PortfolioAppTests/AppStateTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — RootPagerView file exists and uses TabView .page style
grep -q "tabViewStyle(.page)\|tabViewStyle(PageTabViewStyle" \
  apps/ios/Sources/Views/RootPagerView.swift \
  || { echo "FAIL: pager not using page tab view style"; exit 1; }
echo "tier3 pass: horizontal pager using correct tab view style"
```

---

## Phase 6 — iOS: Screens

**Goal:** All five user flows from PRD §4 are navigable. Polaroid aesthetic applied.
Real data from the live Rust server renders in each screen.

---

### T6.1 — Portfolio home (hero, scrollable sections)

**Description:** Build the portfolio home screen. Hero section: photo (AsyncImage from
/static/), name, one-liner summary. Scrollable sections: About (bio text), Experience
(list of experience cards), Projects (list of project cards), Skills (by category).
Each section uses PolaroidCard modifier. ViewModel: `PortfolioViewModel` fetches
`GET /portfolios/1` on appear.

**Subtasks:**
- `Sources/Views/PortfolioHomeView.swift`
- `Sources/ViewModels/PortfolioViewModel.swift`
- `Sources/Views/Components/HeroView.swift`
- `Sources/Views/Components/SectionHeaderView.swift`

**Requires:** T5.4

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
  -only-testing:PortfolioAppTests/PortfolioViewModelTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — PortfolioViewModel loads and exposes portfolio data
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!; sleep 3
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppIntegrationTests/PortfolioHomeTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
RESULT=$?
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
exit $RESULT
```

---

### T6.2 — Experience + Skills polaroid cards

**Description:** Build the experience card and skills card components. Experience card:
company, role, dates (monospace), bullet points. Skills card: category header, items as tags.
Both use `PolaroidCard` modifier with index-seeded rotation. Cards have slight shadow and
off-white border suggesting a photo backing.

**Subtasks:**
- `Sources/Views/Components/ExperienceCardView.swift`
- `Sources/Views/Components/SkillsCardView.swift`
- Rotation uses `index` parameter to seed deterministic angle
- Snapshot tests (if XCTest supports) OR unit tests asserting non-nil view construction

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
  -only-testing:PortfolioAppTests/CardComponentTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — rotation modifier uses index not random
grep -q "\.rotation(index:\|rotationAngle(for index:\|degrees.*Double(index" \
  apps/ios/Sources/Views/Components/ExperienceCardView.swift \
  apps/ios/Sources/Theme/PolaroidCard.swift 2>/dev/null \
  || { echo "FAIL: rotation not seeded by index"; exit 1; }
echo "tier3 pass: rotation is index-seeded (deterministic)"
```

---

### T6.3 — Projects list + project detail modal

**Description:** Projects list: scrollable grid or list of polaroid cards with title, role,
view count (monospace). Tap → project detail modal. Detail modal: title, role, writeup,
view count (already incremented by GET on open), "Interested" button (POST /interested,
updates count in place). ViewModel: `ProjectsViewModel` (list) + `ProjectDetailViewModel`
(detail + interested toggle).

**Subtasks:**
- `Sources/Views/ProjectsListView.swift`
- `Sources/Views/ProjectDetailView.swift`
- `Sources/ViewModels/ProjectsViewModel.swift`
- `Sources/ViewModels/ProjectDetailViewModel.swift`
- Unit test: tapping interested increments local count before server confirms

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
  -only-testing:PortfolioAppTests/ProjectsViewModelTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — project detail view_count increments via live server
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!; sleep 3
BEFORE=$(sqlite3 services/portfolio-api/dev.db "SELECT view_count FROM projects WHERE id=1;")
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppIntegrationTests/ProjectDetailTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
AFTER=$(sqlite3 services/portfolio-api/dev.db "SELECT view_count FROM projects WHERE id=1;")
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
[ "$AFTER" -gt "$BEFORE" ] \
  || { echo "FAIL: view_count did not increment (before=$BEFORE after=$AFTER)"; exit 1; }
echo "tier3 pass: view_count incremented from $BEFORE to $AFTER"
```

---

### T6.4 — Ask Richard screen

**Description:** Screen showing 5+ tappable canned prompt buttons. Tapping a canned prompt
calls `POST /qa/ask` and displays the answer below. Optional free-text field: when submitted,
calls the same endpoint. If response has `match: null`, show "I'd love to chat — leave a note
below" with a link to T6.5. ViewModel: `AskViewModel`.

**Subtasks:**
- `Sources/Views/AskView.swift`
- `Sources/ViewModels/AskViewModel.swift`
- Canned prompts loaded from `GET /portfolios/1/qa`
- Free-text field with submit button
- Fallback UI when match is null

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
  -only-testing:PortfolioAppTests/AskViewModelTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — null match handled without crash
grep -q "leave_a_note\|leaveANote\|leave a note" \
  apps/ios/Sources/Views/AskView.swift \
  apps/ios/Sources/ViewModels/AskViewModel.swift 2>/dev/null \
  || { echo "FAIL: null match fallback UI not implemented"; exit 1; }
echo "tier3 pass: null match fallback present in Ask screen"
```

---

### T6.5 — Leave a note form

**Description:** Form view with three fields: name, email, message. Submit button calls
`POST /portfolios/1/notes`. All fields validated non-empty on submit (client-side). On
success: replace form with a confirmation card ("Your note has been sent"). On error:
show inline error message. ViewModel: `LeaveNoteViewModel`.

**Subtasks:**
- `Sources/Views/LeaveNoteView.swift`
- `Sources/ViewModels/LeaveNoteViewModel.swift`
- Client-side validation before network call
- Confirmation + error states

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
  -only-testing:PortfolioAppTests/LeaveNoteViewModelTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — validation prevents empty submit
grep -q "isEmpty\|\.isEmpty" \
  apps/ios/Sources/ViewModels/LeaveNoteViewModel.swift \
  || { echo "FAIL: no empty-field validation in LeaveNoteViewModel"; exit 1; }
echo "tier3 pass: empty field validation present"
```

---

### T6.6 — Inbox theatre screen

**Description:** Inbox screen showing seeded conversations list. Tapping a conversation shows
the message thread. Send button/field is visible but disabled or no-op. A "Demo" badge is
visible on the inbox screen (e.g. small pill label or watermark) indicating this is theatre.
ViewModel: `InboxViewModel`.

**Subtasks:**
- `Sources/Views/InboxView.swift`
- `Sources/Views/ConversationThreadView.swift`
- `Sources/ViewModels/InboxViewModel.swift`
- "Demo" badge visible in InboxView
- Send field disabled (`.disabled(true)` or no action attached)

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
  -only-testing:PortfolioAppTests/InboxViewModelTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
```

```bash
# tier3_integration — demo badge and disabled send path present in source
grep -qi "demo\|theatre\|scaffold" apps/ios/Sources/Views/InboxView.swift \
  || { echo "FAIL: no demo/theatre badge in InboxView"; exit 1; }
grep -q '\.disabled(true)\|isDisabled\|// no-op\|stub' \
  apps/ios/Sources/Views/ConversationThreadView.swift \
  apps/ios/Sources/Views/InboxView.swift 2>/dev/null \
  || { echo "FAIL: send path not visibly disabled or stubbed"; exit 1; }
echo "tier3 pass: demo badge present, send path disabled"
```

---

## Phase 7 — Integration & Documentation

**Goal:** Full E2E flow verified. Static file serving works. All three doc stubs completed.

---

### T7.1 — End-to-end smoke test

**Description:** Verify the complete user flow: Rust server running with seeded data → iOS
simulator app running → all five screens reachable → no crashes. Write a dedicated
`PortfolioAppIntegrationTests/E2ESmokeTests.swift` that exercises: portfolio load, project
detail open (verifies view_count increment), ask endpoint, note submission, inbox render.

**Subtasks:**
- `apps/ios/PortfolioAppIntegrationTests/E2ESmokeTests.swift`
- All five screens covered
- Each test asserts on actual data from the live server

**Requires:** T6.6, T4.2

**Verify:**
```bash
# tier1_build
xcodebuild -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
```

```bash
# tier2_unit — E2E test file exists and has at least 5 test methods
TEST_COUNT=$(grep -c "func test" \
  apps/ios/PortfolioAppIntegrationTests/E2ESmokeTests.swift 2>/dev/null || echo 0)
[ "$TEST_COUNT" -ge "5" ] \
  || { echo "FAIL: E2ESmokeTests has $TEST_COUNT tests, need at least 5"; exit 1; }
echo "tier2 pass: $TEST_COUNT E2E smoke tests defined"
```

```bash
# tier3_integration — full E2E suite passes against live server
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!; sleep 3
xcodebuild test \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PortfolioAppIntegrationTests/E2ESmokeTests \
  2>&1 | grep -E "TEST (SUCCEEDED|FAILED)"
RESULT=$?
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
exit $RESULT
```

---

### T7.2 — Static file serving for images

**Description:** Set up the `static/` directory in `services/portfolio-api/`. Add a portfolio
hero photo (or SVG placeholder if no real photo — answer open question in memory.md). Add
placeholder images for each project. Verify the axum static handler (wired in T3.1) serves
them correctly. Update the iOS `APIClient` to resolve `/static/` URLs against the base URL.

**Subtasks:**
- `services/portfolio-api/static/` directory with hero image/placeholder
- `services/portfolio-api/static/projects/` with per-project placeholders
- Seed data updated to reference correct `/static/` paths
- iOS `AsyncImage` usage confirmed to use full URL

**Requires:** T7.1

**Verify:**
```bash
# tier1_build — static directory has at least one file
[ "$(ls services/portfolio-api/static/ 2>/dev/null | wc -l)" -gt "0" ] \
  || { echo "FAIL: static/ directory is empty"; exit 1; }
echo "tier1 pass: static directory has content"
```

```bash
# tier2_unit — static paths referenced in seed data match files on disk
PATHS=$(sqlite3 services/portfolio-api/dev.db \
  "SELECT photo_path FROM portfolios WHERE photo_path IS NOT NULL;")
for p in $PATHS; do
  FULL="services/portfolio-api${p}"
  [ -f "$FULL" ] || { echo "FAIL: static file missing: $FULL"; exit 1; }
done
echo "tier2 pass: all static paths in DB resolve to real files"
```

```bash
# tier3_integration — static endpoint serves a file with 200
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db cargo run &
SERVER_PID=$!; sleep 3
HERO_PATH=$(sqlite3 dev.db "SELECT photo_path FROM portfolios WHERE id=1;" 2>/dev/null)
STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:8080${HERO_PATH}")
kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null
[ "$STATUS" = "200" ] || { echo "FAIL: static file returned $STATUS"; exit 1; }
echo "tier3 pass: static hero file served with 200"
```

---

### T7.3 — Complete documentation stubs

**Description:** Fill in the three documentation stubs created in T1.1.
- `docs/system-design.md`: architecture diagram (ASCII), data flow, cache strategy, what was
  implemented vs. considered-but-not-built, known limitations.
- `docs/test-plan.md`: test coverage summary, what's tested at each tier, what's not tested
  and why.
- `docs/retrospective.md`: explicit scope cuts (from PRD §13), what was hard (Bazel iOS?),
  what would change with more time, honest assessment of theatre components.

**Subtasks:**
- All three files have real content (not stubs)
- system-design.md has a "considered but not built" section
- retrospective.md explicitly names theatre components

**Requires:** T7.2

**Verify:**
```bash
# tier1_build — all three files exist and are non-trivially sized
for f in docs/system-design.md docs/test-plan.md docs/retrospective.md; do
  LINES=$(wc -l < "$f" 2>/dev/null || echo 0)
  [ "$LINES" -gt "20" ] || { echo "FAIL: $f has only $LINES lines — too short"; exit 1; }
done
echo "tier1 pass: all doc files have substantive content"
```

```bash
# tier2_unit — required sections present
grep -q "considered but not built\|Considered But Not Built\|not implemented" \
  docs/system-design.md \
  || { echo "FAIL: system-design.md missing 'considered but not built' section"; exit 1; }
grep -q "theatre\|Theatre\|scaffold\|Scaffold" docs/retrospective.md \
  || { echo "FAIL: retrospective.md doesn't address theatre components"; exit 1; }
echo "tier2 pass: required doc sections present"
```

```bash
# tier3_integration — no stub markers remain
for f in docs/system-design.md docs/test-plan.md docs/retrospective.md; do
  grep -qi "TODO\|FIXME\|stub\|placeholder\|TBD" "$f" \
    && { echo "FAIL: $f still has stub markers"; exit 1; }
done
echo "tier3 pass: no stub markers in documentation"
```

---

## Completion Criteria

All 30 tasks show `"status": "complete"` in `tasks/state.json`. All phases show
`"status": "complete"`. `postmortems[]` has `"resolved": true` on every entry (or is empty).

The deliverable is: a working iOS app (SwiftUI, iOS 17+) showing Richard's real CV content,
backed by a Rust/axum service, structured as a Bazel monorepo, with a documented
agent-optimised codebase. The Lapse interview panel should be able to clone the repo, run the
seed binary, start the server, and open the app in the iOS simulator in under 5 minutes.
