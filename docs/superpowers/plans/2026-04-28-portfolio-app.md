# Portfolio App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iOS portfolio app backed by a Rust/axum service in a Bazel monorepo, showing Richard Lao's real CV content, with polaroid/film aesthetic.

**Architecture:** SwiftUI iOS app (MVVM, @Observable) → HTTP/JSON → Rust axum server → SQLite (sqlx, WAL mode) with DashMap read cache. Bazel builds both iOS and Rust targets. Seed tool populates DB from CV data.

**Tech Stack:** Rust 1.95, axum 0.7, sqlx 0.8, tokio, DashMap 6, tower-http | SwiftUI (iOS 26), URLSession | Bazel 9.1 (Bzlmod), rules_rust, rules_apple | SQLite 3.51

**Spec:** `docs/superpowers/specs/2026-04-28-portfolio-design-v2.md`

---

## File Structure

### Rust Backend (`services/portfolio-api/`)
```
services/portfolio-api/
├── Cargo.toml                          (exists — correct deps)
├── BUILD                               (create — Bazel rust_binary)
├── .env.example                        (create)
├── migrations/
│   └── 0001_initial.sql                (create — 8 tables)
├── static/                             (create — hero + project images)
│   ├── hero.svg
│   └── projects/
│       ├── pharmabridge.svg
│       └── marl.svg
└── src/
    ├── main.rs                         (exists — rewrite to axum server)
    ├── db.rs                           (create — pool init, WAL pragma)
    ├── app_state.rs                    (create — AppState: pool + cache)
    ├── cache.rs                        (create — DashMap cache layer)
    ├── routes/
    │   └── mod.rs                      (create — all route registration)
    ├── handlers/
    │   ├── mod.rs                      (create)
    │   ├── health_handler.rs           (create)
    │   ├── portfolio_handler.rs        (create)
    │   ├── projects_handler.rs         (create)
    │   ├── qa_handler.rs               (create)
    │   ├── notes_handler.rs            (create)
    │   └── conversations_handler.rs    (create)
    ├── repositories/
    │   ├── mod.rs                      (create)
    │   ├── portfolio_repo.rs           (create)
    │   ├── experience_repo.rs          (create)
    │   ├── skills_repo.rs              (create)
    │   ├── projects_repo.rs            (create)
    │   ├── qa_repo.rs                  (create)
    │   ├── notes_repo.rs              (create)
    │   └── conversations_repo.rs       (create)
    └── models/
        ├── mod.rs                      (create)
        ├── portfolio.rs                (create)
        ├── experience.rs               (create)
        ├── skill.rs                    (create)
        ├── project.rs                  (create)
        ├── qa_pair.rs                  (create)
        ├── note.rs                     (create)
        ├── conversation.rs             (create)
        └── message.rs                  (create)
```

### Seed Tool (`tools/seed/`)
```
tools/seed/
├── Cargo.toml                          (exists)
├── data/
│   ├── cv_template.json                (exists — FILL_IN placeholders)
│   └── cv.json                         (create — real CV content)
└── src/
    └── main.rs                         (exists — rewrite with seed logic)
```

### iOS App (`apps/ios/`)
```
apps/ios/
├── BUILD                               (create — Bazel ios_application)
├── Info.plist                          (create — ATS exception)
├── PortfolioApp.xcodeproj/             (create — Xcode project)
└── Sources/
    ├── PortfolioApp.swift              (create — @main App)
    ├── Views/
    │   ├── ContentView.swift           (create — initial stub)
    │   ├── RootPagerView.swift         (create — TabView pager)
    │   ├── PortfolioHomeView.swift     (create)
    │   ├── ProjectsListView.swift      (create)
    │   ├── ProjectDetailView.swift     (create)
    │   ├── AskView.swift               (create)
    │   ├── LeaveNoteView.swift         (create)
    │   ├── InboxView.swift             (create)
    │   ├── ConversationThreadView.swift(create)
    │   └── Components/
    │       ├── HeroView.swift          (create)
    │       ├── ExperienceCardView.swift(create)
    │       ├── SkillsCardView.swift    (create)
    │       └── SectionHeaderView.swift (create)
    ├── ViewModels/
    │   ├── AppState.swift              (create — @Observable)
    │   ├── PortfolioViewModel.swift    (create)
    │   ├── ProjectsViewModel.swift     (create)
    │   ├── ProjectDetailViewModel.swift(create)
    │   ├── AskViewModel.swift          (create)
    │   ├── LeaveNoteViewModel.swift    (create)
    │   └── InboxViewModel.swift        (create)
    ├── APIClient/
    │   ├── APIClient.swift             (create)
    │   └── APIError.swift              (create)
    ├── Models/
    │   └── Models.swift                (create — all Codable types)
    ├── Theme/
    │   ├── LapseTheme.swift            (create)
    │   ├── GrainOverlay.swift          (create)
    │   └── PolaroidCard.swift          (create)
    └── Resources/
```

### Root-Level Files
```
emulsion/
├── MODULE.bazel                        (create — Bzlmod)
├── BUILD                               (create — root)
├── .bazelversion                       (create — "9.1.0")
├── AGENTS.md                           (create)
├── docs/
│   ├── system-design.md                (create — stub then living)
│   ├── test-plan.md                    (create — stub then living)
│   └── retrospective.md               (create — living from Phase 1)
└── shared/
    └── schemas/
        └── README.md                   (create)
```

---

## Phase 1 — Repo Foundation & Bazel

### Task 1: Directory scaffold, READMEs, AGENTS.md (T1.1)

**Files:**
- Create: `AGENTS.md`
- Create: `apps/ios/README.md`
- Modify: `services/portfolio-api/README.md` (create if needed)
- Create: `shared/schemas/README.md`
- Create: `tools/seed/README.md`
- Create: `docs/system-design.md`
- Create: `docs/test-plan.md`
- Create: `docs/retrospective.md`

- [ ] **Step 1: Create AGENTS.md**

```markdown
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

- All Rust handlers: extract AppState → call repo → map error → return Json
- All SwiftUI views: View → ViewModel (@Observable) → APIClient call
- Counter updates: atomic SQL `UPDATE SET col = col + 1` (never read-modify-write)
- Colors/fonts/spacing: always via LapseTheme (never hardcoded in Views)
- Polaroid card rotation: seeded by item index (never random)
```

- [ ] **Step 2: Create package READMEs**

`apps/ios/README.md`:
```markdown
# iOS App

SwiftUI portfolio app targeting iOS 26. MVVM architecture with @Observable ViewModels.

## Build

```bash
# Xcode (development)
xcodebuild -project PortfolioApp.xcodeproj -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Bazel
bazel build //apps/ios:app
```

## Run

Start the backend first (`cargo run -p portfolio-api`), then run in Xcode (Cmd+R).
```

`services/portfolio-api/README.md`:
```markdown
# Portfolio API

Rust axum backend serving the portfolio data over HTTP/JSON on port 8080.

## Build

```bash
# Cargo (development)
cargo build -p portfolio-api

# Bazel
bazel build //services/portfolio-api:server
```

## Run

```bash
DATABASE_URL=sqlite:./dev.db cargo run -p portfolio-api
curl http://localhost:8080/health
```

## Test

```bash
cargo test -p portfolio-api -- --test-threads=1
```
```

`shared/schemas/README.md`:
```markdown
# Shared Schemas

Extension point for shared type definitions across iOS and backend.

Currently a placeholder — see Phase 8 (stretch) for the shared Rust platform layer plan.
```

`tools/seed/README.md`:
```markdown
# Seed Tool

Populates SQLite with Richard's CV content. Idempotent — safe to run multiple times.

## Run

```bash
# Ensure migrations have run first
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db sqlx migrate run

# Seed
DATABASE_URL=sqlite:./services/portfolio-api/dev.db cargo run -p seed
```
```

- [ ] **Step 3: Create doc stubs**

`docs/system-design.md`:
```markdown
# System Design

## Architecture Overview

## Data Flow

## Cache Strategy

## Latency Considerations

## Considered But Not Built

## Known Limitations
```

`docs/test-plan.md`:
```markdown
# Test Plan

## Test Coverage by Tier

## What Is Tested

## What Is Not Tested (and Why)
```

`docs/retrospective.md`:
```markdown
# Retrospective

## Phase 1 — Repo Foundation & Bazel

### Key Decisions

### What Was Hard

### What I Would Change
```

- [ ] **Step 4: Run verification**

Run: `bash -c 'for d in apps/ios services/portfolio-api shared/schemas tools/seed docs; do [ -d "$d" ] || { echo "MISSING: $d"; exit 1; }; done && echo "tier1 pass"'`

Run: `bash -c 'for f in AGENTS.md apps/ios/README.md services/portfolio-api/README.md shared/schemas/README.md tools/seed/README.md docs/system-design.md docs/test-plan.md docs/retrospective.md; do [ -s "$f" ] || { echo "MISSING OR EMPTY: $f"; exit 1; }; done && echo "tier2 pass"'`

Run: `bash -c 'grep -q -i "conventions" AGENTS.md && grep -q "_handler\|_view\|ViewModel" AGENTS.md && grep -q -i "phase 1" docs/retrospective.md && echo "tier3 pass"'`

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md apps/ios/README.md services/portfolio-api/README.md \
  shared/schemas/README.md tools/seed/README.md \
  docs/system-design.md docs/test-plan.md docs/retrospective.md
git commit -m "feat(T1.1): scaffold directories, READMEs, and AGENTS.md"
```

---

### Task 2: MODULE.bazel with rules_rust and rules_apple (T1.2)

**Files:**
- Create: `MODULE.bazel`
- Create: `BUILD` (root)
- Create: `.bazelversion`

- [ ] **Step 1: Research Bazel 9 compatible versions of rules_rust and rules_apple**

Run: `bazel --version` to confirm 9.1.0.

Check the latest Bazel Central Registry entries for `rules_rust` and `rules_apple` that support Bazel 9. This requires checking https://registry.bazel.build or testing versions. Start with the latest available and fall back if incompatible.

- [ ] **Step 2: Create .bazelversion**

```
9.1.0
```

- [ ] **Step 3: Create MODULE.bazel**

```starlark
module(
    name = "emulsion",
    version = "0.0.1",
)

bazel_dep(name = "rules_rust", version = "0.56.0")
bazel_dep(name = "rules_apple", version = "3.16.1")
bazel_dep(name = "rules_swift", version = "2.6.0")
bazel_dep(name = "apple_support", version = "1.17.1")

rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(edition = "2021")
use_repo(rust, "rust_toolchains")
register_toolchains("@rust_toolchains//:all")
```

Note: These versions may need adjustment based on actual Bazel 9 compatibility. The subagent should test and update versions if `bazel info workspace` fails.

- [ ] **Step 4: Create root BUILD file**

```starlark
# Root BUILD file — individual packages have their own BUILD files
```

- [ ] **Step 5: Verify Bazel parses the workspace**

Run: `bazel info workspace 2>&1 | head -5`
Expected: workspace path printed, no errors

Run: `bazel query '//...' 2>&1 | head -20`
Expected: targets listed (may be empty if no BUILD files with targets yet)

- [ ] **Step 6: Document versions in memory.md**

Add to `.claude/memory.md` under Decisions:
```
- [2026-04-28] Bazel 9.1.0 with rules_rust X.Y.Z, rules_apple A.B.C (verified compatible).
  MODULE.bazel uses Bzlmod, not legacy WORKSPACE.
```

- [ ] **Step 7: Commit**

```bash
git add MODULE.bazel BUILD .bazelversion .claude/memory.md
git commit -m "feat(T1.2): configure Bazel 9 with rules_rust and rules_apple"
```

---

### Task 3: Bazel target //services/portfolio-api:server (T1.3)

**Files:**
- Create: `services/portfolio-api/BUILD`
- Modify: `services/portfolio-api/src/main.rs`

- [ ] **Step 1: Write minimal axum server in main.rs**

```rust
use axum::{routing::get, Json, Router};
use serde_json::{json, Value};
use tokio::net::TcpListener;

async fn health() -> Json<Value> {
    Json(json!({"status": "ok"}))
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/health", get(health));
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!("listening on http://0.0.0.0:8080");
    axum::serve(listener, app).await.unwrap();
}
```

- [ ] **Step 2: Verify cargo build**

Run: `cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | tail -3`
Expected: `Finished` with exit 0

- [ ] **Step 3: Create services/portfolio-api/BUILD**

```starlark
load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "server",
    srcs = glob(["src/**/*.rs"]),
    deps = [
        "@crates//:axum",
        "@crates//:tokio",
        "@crates//:sqlx",
        "@crates//:serde",
        "@crates//:serde_json",
        "@crates//:dashmap",
        "@crates//:tower-http",
        "@crates//:tracing",
        "@crates//:tracing-subscriber",
        "@crates//:anyhow",
    ],
    edition = "2021",
    visibility = ["//visibility:public"],
)
```

Note: The `@crates//` prefix depends on how crates_universe is configured in MODULE.bazel. The subagent may need to add a `crates_repository` extension to MODULE.bazel. If Bazel build fails due to missing crate deps, add the crate universe extension:

```starlark
# Add to MODULE.bazel if needed
crate = use_extension("@rules_rust//crate_universe:extensions.bzl", "crate")
crate.from_cargo(
    name = "crates",
    cargo_lockfile = "//:Cargo.lock",
    manifests = [
        "//:Cargo.toml",
        "//services/portfolio-api:Cargo.toml",
        "//tools/seed:Cargo.toml",
    ],
)
use_repo(crate, "crates")
```

- [ ] **Step 4: Attempt Bazel build**

Run: `bazel build //services/portfolio-api:server 2>&1 | tail -10`
Expected: `Build completed successfully`

If it fails, debug the crate_universe configuration. This is expected to be the hardest integration point. Document findings in `.claude/memory.md`.

- [ ] **Step 5: Commit**

```bash
git add services/portfolio-api/BUILD services/portfolio-api/src/main.rs MODULE.bazel
git commit -m "feat(T1.3): add Bazel Rust target and minimal axum server"
```

---

### Task 4: Bazel iOS target + Xcode project (T1.4)

**Files:**
- Create: `apps/ios/BUILD`
- Create: `apps/ios/Info.plist`
- Create: `apps/ios/Sources/PortfolioApp.swift`
- Create: `apps/ios/Sources/Views/ContentView.swift`
- Create: `apps/ios/PortfolioApp.xcodeproj` (via xcodebuild or manual)
- Create: directories for Views/, ViewModels/, APIClient/, Models/, Theme/, Resources/

- [ ] **Step 1: Create Info.plist with ATS exception**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PortfolioApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.lapse.portfolio</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>PortfolioApp</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
```

- [ ] **Step 2: Create PortfolioApp.swift**

```swift
import SwiftUI

@main
struct PortfolioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 3: Create ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello Lapse")
            .font(.largeTitle)
    }
}
```

- [ ] **Step 4: Create folder structure**

```bash
mkdir -p apps/ios/Sources/{Views/Components,ViewModels,APIClient,Models,Theme,Resources}
mkdir -p apps/ios/Tests/PortfolioAppTests
```

- [ ] **Step 5: Create the Xcode project**

Use `xcodebuild` or create the `.xcodeproj` programmatically. The subagent should use the `xcodeproj` structure or a Swift Package Manager approach. The simplest reliable method:

Create a Package.swift temporarily to generate the project, or create the xcodeproj manually. The key requirements are:
- Scheme: `PortfolioApp`
- Target: iOS 26
- Bundle ID: `com.lapse.portfolio`
- Sources folder: `Sources/`
- Test target: `PortfolioAppTests`

The subagent should verify: `xcodebuild -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp -destination 'platform=iOS Simulator,name=iPhone 16' build`

- [ ] **Step 6: Create apps/ios/BUILD for Bazel**

```starlark
load("@rules_apple//apple:ios.bzl", "ios_application")
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PortfolioAppLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "PortfolioApp",
)

ios_application(
    name = "app",
    bundle_id = "com.lapse.portfolio",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "26.0",
    visibility = ["//visibility:public"],
    deps = [":PortfolioAppLib"],
)
```

- [ ] **Step 7: Attempt Bazel iOS build**

Run: `bazel build //apps/ios:app 2>&1 | tail -10`

If it fails after reasonable debugging (timebox: 3 hours), document in `.claude/memory.md` under Gotchas and proceed with Xcode-only. The Xcode project is the primary development workflow regardless.

- [ ] **Step 8: Verify xcodebuild**

Run: `xcodebuild -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp -destination 'platform=iOS Simulator,name=iPhone 16' -allowProvisioningUpdates build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 9: Verify ATS exception**

Run: `grep -q "NSAppTransportSecurity" apps/ios/Info.plist && echo "ATS present"`
Expected: `ATS present`

- [ ] **Step 10: Update retrospective**

Add to `docs/retrospective.md` under Phase 1: decisions about Bazel versions, any fallbacks, what was hard.

- [ ] **Step 11: Commit**

```bash
git add apps/ios/ docs/retrospective.md .claude/memory.md
git commit -m "feat(T1.4): add iOS app with Bazel target and Xcode project"
```

---

## Phase 2 — Rust: Data Layer

### Task 5: SQLite schema + sqlx migrations (T2.1)

**Files:**
- Create: `services/portfolio-api/migrations/0001_initial.sql`
- Create: `services/portfolio-api/src/db.rs`
- Create: `services/portfolio-api/.env.example`
- Modify: `services/portfolio-api/src/main.rs` (add mod db)

- [ ] **Step 1: Create migration file**

`services/portfolio-api/migrations/0001_initial.sql`:
```sql
CREATE TABLE IF NOT EXISTS portfolios (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    bio TEXT NOT NULL,
    photo_path TEXT,
    summary TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS experiences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    company TEXT NOT NULL,
    role TEXT NOT NULL,
    dates TEXT NOT NULL,
    bullets TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    title TEXT NOT NULL,
    role TEXT NOT NULL,
    writeup TEXT NOT NULL,
    screenshots TEXT NOT NULL DEFAULT '[]',
    view_count INTEGER NOT NULL DEFAULT 0,
    interested_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    category TEXT NOT NULL,
    items TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS qa_pairs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    prompt TEXT NOT NULL,
    answer TEXT NOT NULL,
    is_canned INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    participant_name TEXT NOT NULL,
    last_message TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id),
    sender TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
```

- [ ] **Step 2: Create db.rs**

```rust
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{Pool, Sqlite};
use std::str::FromStr;

pub async fn init_pool() -> Pool<Sqlite> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./dev.db".to_string());

    let opts = SqliteConnectOptions::from_str(&database_url)
        .expect("invalid DATABASE_URL")
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal);

    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(opts)
        .await
        .expect("failed to connect to database");

    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("failed to run migrations");

    pool
}
```

- [ ] **Step 3: Create .env.example**

```
DATABASE_URL=sqlite:./dev.db
```

- [ ] **Step 4: Add mod db to main.rs**

Update `services/portfolio-api/src/main.rs`:
```rust
mod db;

use axum::{routing::get, Json, Router};
use serde_json::{json, Value};
use tokio::net::TcpListener;

async fn health() -> Json<Value> {
    Json(json!({"status": "ok"}))
}

#[tokio::main]
async fn main() {
    let _pool = db::init_pool().await;

    let app = Router::new().route("/health", get(health));
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!("listening on http://0.0.0.0:8080");
    axum::serve(listener, app).await.unwrap();
}
```

- [ ] **Step 5: Run sqlx prepare for offline mode**

```bash
cd services/portfolio-api
DATABASE_URL=sqlite:./prepare.db sqlx migrate run
DATABASE_URL=sqlite:./prepare.db cargo sqlx prepare
rm -f prepare.db
```

This generates the `.sqlx/` directory. Commit it.

- [ ] **Step 6: Verify**

Run: `cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | tail -3`
Expected: `Finished`

Run: `cd services/portfolio-api && DATABASE_URL=sqlite:./test_verify.db sqlx migrate run 2>&1 && echo "migrations ran" && rm -f test_verify.db`

Run tier3 from spec (all 8 tables check).

- [ ] **Step 7: Commit**

```bash
git add services/portfolio-api/migrations/ services/portfolio-api/src/db.rs \
  services/portfolio-api/src/main.rs services/portfolio-api/.sqlx/ \
  services/portfolio-api/.env.example
git commit -m "feat(T2.1): add SQLite schema with 8 tables and sqlx migrations"
```

---

### Task 6: Portfolio, Experience, Skills repositories (T2.2)

**Files:**
- Create: `services/portfolio-api/src/models/mod.rs`
- Create: `services/portfolio-api/src/models/portfolio.rs`
- Create: `services/portfolio-api/src/models/experience.rs`
- Create: `services/portfolio-api/src/models/skill.rs`
- Create: `services/portfolio-api/src/repositories/mod.rs`
- Create: `services/portfolio-api/src/repositories/portfolio_repo.rs`
- Create: `services/portfolio-api/src/repositories/experience_repo.rs`
- Create: `services/portfolio-api/src/repositories/skills_repo.rs`
- Modify: `services/portfolio-api/src/main.rs` (add mod models, mod repositories)

- [ ] **Step 1: Create model structs**

`src/models/mod.rs`:
```rust
pub mod portfolio;
pub mod experience;
pub mod skill;

pub use portfolio::Portfolio;
pub use experience::Experience;
pub use skill::Skill;
```

`src/models/portfolio.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Portfolio {
    pub id: i64,
    pub name: String,
    pub bio: String,
    pub photo_path: Option<String>,
    pub summary: String,
    pub created_at: String,
}
```

`src/models/experience.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Experience {
    pub id: i64,
    pub portfolio_id: i64,
    pub company: String,
    pub role: String,
    pub dates: String,
    pub bullets: String,
}
```

`src/models/skill.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Skill {
    pub id: i64,
    pub portfolio_id: i64,
    pub category: String,
    pub items: String,
}
```

- [ ] **Step 2: Create repository functions**

`src/repositories/mod.rs`:
```rust
pub mod portfolio_repo;
pub mod experience_repo;
pub mod skills_repo;
```

`src/repositories/portfolio_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::Portfolio;

pub async fn find_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<Option<Portfolio>, sqlx::Error> {
    sqlx::query_as::<_, Portfolio>("SELECT * FROM portfolios WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_find_by_id_not_found() {
        let pool = test_pool().await;
        let result = find_by_id(&pool, 999).await.unwrap();
        assert!(result.is_none());
    }

    #[tokio::test]
    async fn test_find_by_id_found() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'Test', 'Bio', 'Summary')")
            .execute(&pool).await.unwrap();
        let result = find_by_id(&pool, 1).await.unwrap();
        assert!(result.is_some());
        assert_eq!(result.unwrap().name, "Test");
    }
}
```

`src/repositories/experience_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::Experience;

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Experience>, sqlx::Error> {
    sqlx::query_as::<_, Experience>("SELECT * FROM experiences WHERE portfolio_id = ?")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_find_by_portfolio_id_empty() {
        let pool = test_pool().await;
        let result = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert!(result.is_empty());
    }

    #[tokio::test]
    async fn test_find_by_portfolio_id_returns_entries() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO experiences (portfolio_id, company, role, dates, bullets) VALUES (1, 'Serac', 'Engineer', '2025-now', '[]')")
            .execute(&pool).await.unwrap();
        let result = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].company, "Serac");
    }
}
```

`src/repositories/skills_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::Skill;

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Skill>, sqlx::Error> {
    sqlx::query_as::<_, Skill>("SELECT * FROM skills WHERE portfolio_id = ?")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_find_by_portfolio_id() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO skills (portfolio_id, category, items) VALUES (1, 'Languages', '[\"Rust\",\"Swift\"]')")
            .execute(&pool).await.unwrap();
        let result = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].category, "Languages");
    }
}
```

- [ ] **Step 3: Add modules to main.rs**

Add `mod models;` and `mod repositories;` at the top of `main.rs`.

- [ ] **Step 4: Re-run sqlx prepare** (queries changed)

```bash
cd services/portfolio-api
DATABASE_URL=sqlite:./prepare.db sqlx migrate run
DATABASE_URL=sqlite:./prepare.db cargo sqlx prepare
rm -f prepare.db
```

- [ ] **Step 5: Verify**

Run: `cd services/portfolio-api && SQLX_OFFLINE=true cargo build 2>&1 | tail -3`
Run: `cd services/portfolio-api && cargo test portfolio_repo experience_repo skills_repo -- --test-threads=1 2>&1 | tail -15`
Expected: all tests pass

- [ ] **Step 6: Commit**

```bash
git add services/portfolio-api/src/models/ services/portfolio-api/src/repositories/ \
  services/portfolio-api/src/main.rs services/portfolio-api/.sqlx/
git commit -m "feat(T2.2): add portfolio, experience, and skills repositories"
```

---

### Task 7: Projects repository with atomic counters (T2.3)

**Files:**
- Create: `services/portfolio-api/src/models/project.rs`
- Create: `services/portfolio-api/src/repositories/projects_repo.rs`
- Modify: `services/portfolio-api/src/models/mod.rs`
- Modify: `services/portfolio-api/src/repositories/mod.rs`

- [ ] **Step 1: Create project model**

`src/models/project.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Project {
    pub id: i64,
    pub portfolio_id: i64,
    pub title: String,
    pub role: String,
    pub writeup: String,
    pub screenshots: String,
    pub view_count: i64,
    pub interested_count: i64,
}
```

Add to `src/models/mod.rs`:
```rust
pub mod project;
pub use project::Project;
```

- [ ] **Step 2: Create projects repository with atomic counters**

`src/repositories/projects_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::Project;

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Project>, sqlx::Error> {
    sqlx::query_as::<_, Project>("SELECT * FROM projects WHERE portfolio_id = ?")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn find_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<Option<Project>, sqlx::Error> {
    sqlx::query_as::<_, Project>("SELECT * FROM projects WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

pub async fn increment_view_count(pool: &Pool<Sqlite>, id: i64) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE projects SET view_count = view_count + 1 WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn increment_interested_count(pool: &Pool<Sqlite>, id: i64) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE projects SET interested_count = interested_count + 1 WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_increment_view_count() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO projects (id, portfolio_id, title, role, writeup, view_count, interested_count) VALUES (1, 1, 'P', 'R', 'W', 0, 0)")
            .execute(&pool).await.unwrap();

        increment_view_count(&pool, 1).await.unwrap();
        let project = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(project.view_count, 1);

        increment_view_count(&pool, 1).await.unwrap();
        let project = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(project.view_count, 2);
    }

    #[tokio::test]
    async fn test_increment_interested_count() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO projects (id, portfolio_id, title, role, writeup, view_count, interested_count) VALUES (1, 1, 'P', 'R', 'W', 0, 0)")
            .execute(&pool).await.unwrap();

        increment_interested_count(&pool, 1).await.unwrap();
        let project = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(project.interested_count, 1);
    }
}
```

Add to `src/repositories/mod.rs`:
```rust
pub mod projects_repo;
```

- [ ] **Step 3: Re-run sqlx prepare, verify, commit**

Same pattern as Task 6 steps 4-6.

```bash
git commit -m "feat(T2.3): add projects repository with atomic counter updates"
```

---

### Task 8: Q&A, Notes, Theatre repositories (T2.4)

**Files:**
- Create: `services/portfolio-api/src/models/qa_pair.rs`
- Create: `services/portfolio-api/src/models/note.rs`
- Create: `services/portfolio-api/src/models/conversation.rs`
- Create: `services/portfolio-api/src/models/message.rs`
- Create: `services/portfolio-api/src/repositories/qa_repo.rs`
- Create: `services/portfolio-api/src/repositories/notes_repo.rs`
- Create: `services/portfolio-api/src/repositories/conversations_repo.rs`
- Modify: `services/portfolio-api/src/models/mod.rs`
- Modify: `services/portfolio-api/src/repositories/mod.rs`

- [ ] **Step 1: Create remaining model structs**

`src/models/qa_pair.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct QaPair {
    pub id: i64,
    pub portfolio_id: i64,
    pub prompt: String,
    pub answer: String,
    pub is_canned: bool,
}
```

`src/models/note.rs`:
```rust
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Note {
    pub id: i64,
    pub portfolio_id: i64,
    pub name: String,
    pub email: String,
    pub message: String,
    pub created_at: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateNote {
    pub name: String,
    pub email: String,
    pub message: String,
}
```

`src/models/conversation.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Conversation {
    pub id: i64,
    pub portfolio_id: i64,
    pub participant_name: String,
    pub last_message: String,
    pub updated_at: String,
}
```

`src/models/message.rs`:
```rust
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Message {
    pub id: i64,
    pub conversation_id: i64,
    pub sender: String,
    pub body: String,
    pub created_at: String,
}
```

Update `src/models/mod.rs` to include all four new modules and re-exports.

- [ ] **Step 2: Create qa_repo with fuzzy match**

`src/repositories/qa_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::QaPair;

pub async fn find_canned_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<QaPair>, sqlx::Error> {
    sqlx::query_as::<_, QaPair>("SELECT * FROM qa_pairs WHERE portfolio_id = ? AND is_canned = 1")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn fuzzy_match(pool: &Pool<Sqlite>, portfolio_id: i64, query: &str) -> Result<Option<QaPair>, sqlx::Error> {
    let pattern = format!("%{}%", query);
    sqlx::query_as::<_, QaPair>(
        "SELECT * FROM qa_pairs WHERE portfolio_id = ? AND prompt LIKE ? LIMIT 1"
    )
        .bind(portfolio_id)
        .bind(&pattern)
        .fetch_optional(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO qa_pairs (portfolio_id, prompt, answer, is_canned) VALUES (1, 'What are you working on?', 'Building at Serac', 1)")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_fuzzy_match_found() {
        let pool = test_pool().await;
        let result = fuzzy_match(&pool, 1, "working").await.unwrap();
        assert!(result.is_some());
        assert_eq!(result.unwrap().prompt, "What are you working on?");
    }

    #[tokio::test]
    async fn test_fuzzy_match_not_found() {
        let pool = test_pool().await;
        let result = fuzzy_match(&pool, 1, "xyzzy_no_match").await.unwrap();
        assert!(result.is_none());
    }
}
```

- [ ] **Step 3: Create notes_repo**

`src/repositories/notes_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::{Note, CreateNote};

pub async fn create(pool: &Pool<Sqlite>, portfolio_id: i64, note: &CreateNote) -> Result<i64, sqlx::Error> {
    let result = sqlx::query(
        "INSERT INTO notes (portfolio_id, name, email, message) VALUES (?, ?, ?, ?)"
    )
        .bind(portfolio_id)
        .bind(&note.name)
        .bind(&note.email)
        .bind(&note.message)
        .execute(pool)
        .await?;
    Ok(result.last_insert_rowid())
}

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Note>, sqlx::Error> {
    sqlx::query_as::<_, Note>("SELECT * FROM notes WHERE portfolio_id = ? ORDER BY created_at DESC")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new().connect("sqlite::memory:").await.unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_create_and_list() {
        let pool = test_pool().await;
        let note = CreateNote { name: "Alice".into(), email: "a@b.com".into(), message: "Hello".into() };
        create(&pool, 1, &note).await.unwrap();
        let notes = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(notes.len(), 1);
        assert_eq!(notes[0].name, "Alice");
    }
}
```

- [ ] **Step 4: Create conversations_repo**

`src/repositories/conversations_repo.rs`:
```rust
use sqlx::{Pool, Sqlite};
use crate::models::{Conversation, Message};

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Conversation>, sqlx::Error> {
    sqlx::query_as::<_, Conversation>("SELECT * FROM conversations WHERE portfolio_id = ? ORDER BY updated_at DESC")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn find_messages_by_conversation_id(pool: &Pool<Sqlite>, conversation_id: i64) -> Result<Vec<Message>, sqlx::Error> {
    sqlx::query_as::<_, Message>("SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC")
        .bind(conversation_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new().connect("sqlite::memory:").await.unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO conversations (id, portfolio_id, participant_name, last_message) VALUES (1, 1, 'Alex', 'Lets chat')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (1, 'Alex', 'Hi Richard')")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_conversations_and_messages() {
        let pool = test_pool().await;
        let convos = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(convos.len(), 1);
        let msgs = find_messages_by_conversation_id(&pool, 1).await.unwrap();
        assert_eq!(msgs.len(), 1);
        assert_eq!(msgs[0].sender, "Alex");
    }
}
```

- [ ] **Step 5: Update mod files, sqlx prepare, verify, commit**

```bash
git commit -m "feat(T2.4): add Q&A, notes, and theatre repositories"
```

---

### Task 9: In-memory read cache (T2.5)

**Files:**
- Create: `services/portfolio-api/src/cache.rs`
- Modify: `services/portfolio-api/src/main.rs` (add mod cache)

- [ ] **Step 1: Create cache.rs**

```rust
use dashmap::DashMap;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppCache {
    store: Arc<DashMap<String, String>>,
}

impl AppCache {
    pub fn new() -> Self {
        Self {
            store: Arc::new(DashMap::new()),
        }
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.store.get(key).map(|v| v.value().clone())
    }

    pub fn set(&self, key: String, value: String) {
        self.store.insert(key, value);
    }

    pub fn invalidate(&self, key: &str) {
        self.store.remove(key);
    }

    pub fn invalidate_prefix(&self, prefix: &str) {
        self.store.retain(|k, _| !k.starts_with(prefix));
    }

    pub fn invalidate_all(&self) {
        self.store.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cache_set_and_get() {
        let cache = AppCache::new();
        cache.set("portfolio:1".into(), "data".into());
        assert_eq!(cache.get("portfolio:1"), Some("data".into()));
    }

    #[test]
    fn test_cache_invalidate() {
        let cache = AppCache::new();
        cache.set("portfolio:1".into(), "data".into());
        cache.invalidate("portfolio:1");
        assert_eq!(cache.get("portfolio:1"), None);
    }

    #[test]
    fn test_cache_invalidate_prefix() {
        let cache = AppCache::new();
        cache.set("projects:1".into(), "a".into());
        cache.set("projects:2".into(), "b".into());
        cache.set("portfolio:1".into(), "c".into());
        cache.invalidate_prefix("projects:");
        assert_eq!(cache.get("projects:1"), None);
        assert_eq!(cache.get("projects:2"), None);
        assert_eq!(cache.get("portfolio:1"), Some("c".into()));
    }
}
```

- [ ] **Step 2: Add mod cache to main.rs, verify, commit**

```bash
git commit -m "feat(T2.5): add DashMap-based in-memory read cache"
```

---

## Phase 3 — Rust: API Layer

### Task 10: axum bootstrap, router, health check, CORS, static files (T3.1)

**Files:**
- Create: `services/portfolio-api/src/app_state.rs`
- Create: `services/portfolio-api/src/routes/mod.rs`
- Create: `services/portfolio-api/src/handlers/mod.rs`
- Create: `services/portfolio-api/src/handlers/health_handler.rs`
- Modify: `services/portfolio-api/src/main.rs` (full rewrite)

- [ ] **Step 1: Create app_state.rs**

```rust
use sqlx::{Pool, Sqlite};
use crate::cache::AppCache;

#[derive(Clone)]
pub struct AppState {
    pub pool: Pool<Sqlite>,
    pub cache: AppCache,
}
```

- [ ] **Step 2: Create health_handler.rs**

```rust
use axum::Json;
use serde_json::{json, Value};

pub async fn health() -> Json<Value> {
    Json(json!({"status": "ok"}))
}
```

- [ ] **Step 3: Create routes/mod.rs**

```rust
use axum::{routing::get, Router};
use tower_http::cors::CorsLayer;
use tower_http::services::ServeDir;
use crate::app_state::AppState;
use crate::handlers;

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(handlers::health_handler::health))
        .nest_service("/static", ServeDir::new("static"))
        .layer(CorsLayer::permissive())
        .with_state(state)
}
```

- [ ] **Step 4: Rewrite main.rs**

```rust
mod app_state;
mod cache;
mod db;
mod handlers;
mod models;
mod repositories;
mod routes;

use crate::app_state::AppState;
use crate::cache::AppCache;
use tokio::net::TcpListener;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .init();

    let pool = db::init_pool().await;
    let cache = AppCache::new();
    let state = AppState { pool, cache };

    let app = routes::create_router(state);
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    tracing::info!("listening on http://0.0.0.0:8080");
    axum::serve(listener, app).await.unwrap();
}
```

- [ ] **Step 5: Create handlers/mod.rs**

```rust
pub mod health_handler;
```

- [ ] **Step 6: Create static/ directory with placeholder**

```bash
mkdir -p services/portfolio-api/static
echo '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect fill="#ddd" width="200" height="200"/><text x="50%" y="50%" text-anchor="middle" dy=".3em" fill="#999" font-size="14">placeholder</text></svg>' > services/portfolio-api/static/hero.svg
```

- [ ] **Step 7: Verify with tier3 integration test (server starts, health returns 200)**

Run the tier3 verify from the spec.

- [ ] **Step 8: Commit**

```bash
git commit -m "feat(T3.1): bootstrap axum with router, health check, CORS, and static files"
```

---

### Task 11-15: Remaining API handlers (T3.2-T3.6)

Each handler follows the same pattern. The subagent should implement them one at a time:

**Task 11 (T3.2):** `portfolio_handler.rs` — GET /v1/portfolios/:id with tokio::join! fan-out. Returns combined portfolio + experiences + skills JSON. Caches result.

**Task 12 (T3.3):** `projects_handler.rs` — GET list, GET detail (increments view_count), POST interested (increments interested_count). Invalidates cache.

**Task 13 (T3.4):** `qa_handler.rs` — GET /qa (canned list), POST /qa/ask (fuzzy match or `{"match":null,"fallback":"leave_a_note"}`).

**Task 14 (T3.5):** `notes_handler.rs` — POST /notes (validate non-empty, return 201), GET /notes (check X-Owner-Token header, 401 without).

**Task 15 (T3.6):** `conversations_handler.rs` — GET /conversations, GET /conversations/:cid/messages. Add `"theatre": true` to all responses.

For each:
- [ ] Add handler file with endpoint functions
- [ ] Add route to `routes/mod.rs`
- [ ] Add handler module to `handlers/mod.rs`
- [ ] Re-run `cargo sqlx prepare` if any new queries
- [ ] Run tier1-3 verification from spec
- [ ] Commit with message `feat(T3.X): add <endpoint> handler`

**After Task 15:** Draft `docs/system-design.md` and `docs/test-plan.md`. Update `docs/retrospective.md`.

---

## Phase 4 — Seed Data

### Task 16: Seed binary with CV content (T4.1)

**Files:**
- Create: `tools/seed/data/cv.json` (real content from CV PDF)
- Modify: `tools/seed/src/main.rs` (full implementation)

- [ ] **Step 1: Create cv.json with real CV content**

The subagent must fill this with content from Richard's actual CV (already read from PDF). Key data:

```json
{
  "portfolio": {
    "id": 1,
    "name": "Richard Lao",
    "bio": "Founding engineer at a 15-person startup, owning distributed backend systems end-to-end from architecture through on-call. Shipped AWS event-driven pipelines sustaining 14M-record peak bursts across ~1B structured planning data fields, LLM classification infrastructure at ~90% accuracy, and internal AI agents that cut scraper-failure triage from a week to a day.",
    "summary": "Software Engineer — Distributed Systems & Backend Infrastructure",
    "photo_path": "/static/hero.svg"
  },
  "experiences": [
    {
      "company": "Serac Group",
      "role": "Founding Software Engineer",
      "dates": "Jan 2025 – Present",
      "bullets": [
        "Designed event-driven AWS ingestion pipeline (Lambda, SQS, API Gateway) sustaining 10M+ records/month with 14M-record peak bursts at 99.9% SLA",
        "Reduced AWS infrastructure spend from ~£25k to ~£18k/month (~28%) by redesigning pipeline topology",
        "Built LLM-based classification system over ~1B structured fields at ~90% accuracy",
        "Designed AI agents that cut scraper-failure triage from ~1 week to ~1 day (7x faster)",
        "Built authorisation, ingestion, validation, and workflow-orchestration microservices",
        "Own end-to-end internal tooling; mentor engineers and interns on microservices patterns"
      ]
    },
    {
      "company": "Santander UK",
      "role": "Software Engineering Intern, Cybersecurity",
      "dates": "Aug – Oct 2023",
      "bullets": [
        "Contributed to Quantified Forecast Risk, a Python/AWS predictive-modelling initiative across ~100-engineer security department",
        "Embedded across Product Security, GRC, Security Architecture, and Security Engineering"
      ]
    }
  ],
  "projects": [
    {
      "title": "PharmaBridge",
      "role": "Team Captain & Lead Engineer",
      "writeup": "2nd Place at Imperial College x National MedTech Foundation Hackathon (Apr 2026). Built a full-stack B2B platform (Next.js, Node.js, PostgreSQL) connecting licensed pharmacies to exchange, transfer, or sell OTC medicines, formalising informal inter-pharmacy swaps, validating licensing and compliance, and reducing waste from expired stock. Deployed to production under hackathon time constraints."
    },
    {
      "title": "Multi-Agent Reinforcement Learning",
      "role": "Researcher — Final-Year Dissertation",
      "writeup": "Final-year dissertation at King's College London (2024). Designed MARL systems in Python with PyTorch and OpenAI Gym. Implemented policy-gradient and value-based networks, reward shaping, and evaluation pipelines analysing agent coordination under resource constraints."
    }
  ],
  "skills": [
    { "category": "Languages", "items": ["Python", "TypeScript", "Scala", "JavaScript", "Rust", "Swift"] },
    { "category": "Distributed Systems", "items": ["AWS Lambda", "SQS", "SNS", "API Gateway", "S3", "RDS", "Event-driven architectures", "Microservices"] },
    { "category": "Backend & Data", "items": ["Node.js", "REST APIs", "PostgreSQL", "SQLite", "ETL pipelines", "Data modelling"] },
    { "category": "AI/ML", "items": ["OpenAI APIs", "LLM classification", "PyTorch", "scikit-learn", "Reinforcement learning (MARL)"] },
    { "category": "DevOps", "items": ["Docker", "GitHub Actions", "GitLab CI", "Bazel", "Automated rollback", "Zero-downtime releases"] },
    { "category": "Frontend", "items": ["Next.js", "React", "SwiftUI"] }
  ],
  "qa_pairs": [
    { "prompt": "What are you working on right now?", "answer": "I'm a founding engineer at Serac Group, building distributed backend systems for planning data infrastructure in partnership with Idox plc. I own two products end-to-end — Planda Portal and Ava (Application Validation Assistant). Day-to-day that means event-driven AWS pipelines, LLM classification, and internal developer tooling." },
    { "prompt": "What's your strongest technical area?", "answer": "Distributed systems and backend infrastructure. I'm most comfortable designing event-driven pipelines, microservices, and data systems that need to handle scale reliably. At Serac I sustain 14M-record peak bursts at 99.9% SLA — that's where I thrive." },
    { "prompt": "Tell me about PharmaBridge.", "answer": "PharmaBridge placed 2nd at the Imperial College x National MedTech Foundation Hackathon in April 2026. I was Team Captain and Lead Engineer. We built a B2B platform connecting licensed pharmacies to exchange OTC medicines — formalising what was previously done through informal WhatsApp groups. Full-stack: Next.js, Node.js, PostgreSQL, deployed to Vercel under hackathon time constraints." },
    { "prompt": "What's your approach to software architecture?", "answer": "Start boring, add complexity only when forced by scale or requirements. I prefer event-driven patterns because they decouple services naturally, but I don't reach for distributed systems when a monolith would work. At Serac I replaced a legacy system with a partitioned queue architecture — but only because the legacy system was failing under load, not because distributed was inherently better." },
    { "prompt": "Why Lapse?", "answer": "I'm drawn to Lapse because you're building a consumer product that requires real engineering depth — performance at scale, native mobile, and a codebase that needs to move fast without breaking. My background is in backend infrastructure, but I want to work closer to the product and the user. Lapse is the kind of company where engineering decisions directly shape the user experience." },
    { "prompt": "What would you build differently with more time?", "answer": "Real auth (JWT), more integration tests, a shared Rust platform layer for cross-platform code sharing, and I'd flesh out the Android extension point with an actual Kotlin client. I'd also add request-level tracing with OpenTelemetry and a proper CI pipeline with Bazel remote caching." }
  ],
  "conversations": [
    {
      "participant_name": "Alex",
      "messages": [
        { "sender": "Alex", "body": "Hi Richard, I came across your work on the Serac ingestion pipeline — really impressive scale for a 15-person startup. Would love to connect." },
        { "sender": "Richard", "body": "Thanks Alex! Happy to chat — what team are you hiring for?" },
        { "sender": "Alex", "body": "Platform engineering. Your event-driven background is exactly what we need. Let's set up a call." }
      ]
    },
    {
      "participant_name": "Sam",
      "messages": [
        { "sender": "Sam", "body": "Richard — saw PharmaBridge placed 2nd at the Imperial hackathon. Congrats! We're looking for engineers who can ship under pressure." },
        { "sender": "Richard", "body": "Thanks Sam! That hackathon was intense but rewarding. What's the role?" },
        { "sender": "Sam", "body": "Backend lead on our data platform. We'd love to have you join." }
      ]
    },
    {
      "participant_name": "Jordan",
      "messages": [
        { "sender": "Jordan", "body": "Your MARL dissertation is exactly the kind of applied research we value. Have you considered applying ML to production systems?" },
        { "sender": "Richard", "body": "Absolutely — at Serac I built LLM classification over 1B structured fields. I enjoy bridging research and production." }
      ]
    }
  ]
}
```

- [ ] **Step 2: Implement seed main.rs**

```rust
use anyhow::Result;
use serde::Deserialize;
use sqlx::sqlite::SqlitePoolOptions;
use sqlx::{Pool, Sqlite};

#[derive(Deserialize)]
struct CvData {
    portfolio: PortfolioData,
    experiences: Vec<ExperienceData>,
    projects: Vec<ProjectData>,
    skills: Vec<SkillData>,
    qa_pairs: Vec<QaPairData>,
    conversations: Vec<ConversationData>,
}

#[derive(Deserialize)]
struct PortfolioData {
    id: i64,
    name: String,
    bio: String,
    summary: String,
    photo_path: String,
}

#[derive(Deserialize)]
struct ExperienceData {
    company: String,
    role: String,
    dates: String,
    bullets: Vec<String>,
}

#[derive(Deserialize)]
struct ProjectData {
    title: String,
    role: String,
    writeup: String,
}

#[derive(Deserialize)]
struct SkillData {
    category: String,
    items: Vec<String>,
}

#[derive(Deserialize)]
struct QaPairData {
    prompt: String,
    answer: String,
}

#[derive(Deserialize)]
struct ConversationData {
    participant_name: String,
    messages: Vec<MessageData>,
}

#[derive(Deserialize)]
struct MessageData {
    sender: String,
    body: String,
}

async fn seed(pool: &Pool<Sqlite>, data: &CvData) -> Result<()> {
    // Clear and reinsert for idempotency
    sqlx::query("DELETE FROM messages").execute(pool).await?;
    sqlx::query("DELETE FROM conversations").execute(pool).await?;
    sqlx::query("DELETE FROM qa_pairs").execute(pool).await?;
    sqlx::query("DELETE FROM notes").execute(pool).await?;
    sqlx::query("DELETE FROM skills").execute(pool).await?;
    sqlx::query("DELETE FROM projects").execute(pool).await?;
    sqlx::query("DELETE FROM experiences").execute(pool).await?;
    sqlx::query("DELETE FROM portfolios").execute(pool).await?;

    // Portfolio
    sqlx::query("INSERT INTO portfolios (id, name, bio, summary, photo_path) VALUES (?, ?, ?, ?, ?)")
        .bind(data.portfolio.id)
        .bind(&data.portfolio.name)
        .bind(&data.portfolio.bio)
        .bind(&data.portfolio.summary)
        .bind(&data.portfolio.photo_path)
        .execute(pool).await?;

    // Experiences
    for exp in &data.experiences {
        let bullets_json = serde_json::to_string(&exp.bullets)?;
        sqlx::query("INSERT INTO experiences (portfolio_id, company, role, dates, bullets) VALUES (?, ?, ?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&exp.company)
            .bind(&exp.role)
            .bind(&exp.dates)
            .bind(&bullets_json)
            .execute(pool).await?;
    }

    // Projects
    for proj in &data.projects {
        sqlx::query("INSERT INTO projects (portfolio_id, title, role, writeup) VALUES (?, ?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&proj.title)
            .bind(&proj.role)
            .bind(&proj.writeup)
            .execute(pool).await?;
    }

    // Skills
    for skill in &data.skills {
        let items_json = serde_json::to_string(&skill.items)?;
        sqlx::query("INSERT INTO skills (portfolio_id, category, items) VALUES (?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&skill.category)
            .bind(&items_json)
            .execute(pool).await?;
    }

    // Q&A pairs
    for qa in &data.qa_pairs {
        sqlx::query("INSERT INTO qa_pairs (portfolio_id, prompt, answer, is_canned) VALUES (?, ?, ?, 1)")
            .bind(data.portfolio.id)
            .bind(&qa.prompt)
            .bind(&qa.answer)
            .execute(pool).await?;
    }

    // Conversations and messages
    for convo in &data.conversations {
        let last_msg = convo.messages.last().map(|m| m.body.as_str()).unwrap_or("");
        let result = sqlx::query("INSERT INTO conversations (portfolio_id, participant_name, last_message) VALUES (?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&convo.participant_name)
            .bind(last_msg)
            .execute(pool).await?;
        let convo_id = result.last_insert_rowid();

        for msg in &convo.messages {
            sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (?, ?, ?)")
                .bind(convo_id)
                .bind(&msg.sender)
                .bind(&msg.body)
                .execute(pool).await?;
        }
    }

    println!("seeded successfully");
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./dev.db".to_string());

    let pool = SqlitePoolOptions::new()
        .connect(&database_url)
        .await?;

    let cv_json = include_str!("../data/cv.json");
    let data: CvData = serde_json::from_str(cv_json)?;
    seed(&pool, &data).await?;

    Ok(())
}
```

- [ ] **Step 3: Verify idempotency, commit**

```bash
git commit -m "feat(T4.1): implement seed binary with real CV content"
```

---

### Task 17: Run seed against dev.db (T4.2)

- [ ] **Step 1: Run migrations and seed**

```bash
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db sqlx migrate run
cd ../../tools/seed && DATABASE_URL=sqlite:../../services/portfolio-api/dev.db cargo run
```

- [ ] **Step 2: Verify row counts and commit**

Run tier2 and tier3 from spec. Commit:
```bash
git commit -m "feat(T4.2): seed dev.db with Richard's CV content"
```

---

## Phase 5-6 — iOS: Core, Theming & Screens

### Task 18-22: iOS Core (T5.1-T5.3)

**Task 18 (T5.1):** LapseTheme — colors, fonts, spacing, GrainOverlay modifier, PolaroidCard modifier with index-seeded rotation.

**Task 19 (T5.2):** APIClient — async/await URLSession methods for all endpoints, typed Codable models, APIError enum.

**Task 20 (T5.3):** AppState (@Observable) + RootPagerView (TabView with .page style, loops profile).

### Task 21-25: iOS Screens (T6.1-T6.5)

**Task 21 (T6.1):** PortfolioHomeView + PortfolioViewModel + HeroView + component cards.

**Task 22 (T6.2):** ProjectsListView + ProjectDetailView + ViewModels.

**Task 23 (T6.3):** AskView + AskViewModel with fallback UI.

**Task 24 (T6.4):** LeaveNoteView + LeaveNoteViewModel with validation.

**Task 25 (T6.5):** InboxView + ConversationThreadView + InboxViewModel with Demo badge and disabled send.

For each iOS task, the subagent should:
- [ ] Write the Swift files as specified in the spec
- [ ] Use LapseTheme for all visual values (never hardcode)
- [ ] Use @Observable for ViewModels
- [ ] Use APIClient for all network calls
- [ ] Add unit tests in PortfolioAppTests/
- [ ] Run xcodebuild build and test
- [ ] Commit with `feat(T5.X/T6.X): add <component>`

The complete Swift code for each file is available in the spec's subtask descriptions. The subagent should implement the View → ViewModel → APIClient pattern consistently:
- View observes ViewModel state
- ViewModel has `func load()` that calls APIClient
- APIClient returns typed Codable models
- Errors surface via a published `errorMessage: String?`

---

## Phase 7 — Integration & Documentation

### Task 26: Static file serving (T7.1)

- [ ] Create SVG placeholders in `services/portfolio-api/static/` and `static/projects/`
- [ ] Verify axum serves them at /static/hero.svg
- [ ] Commit

### Task 27: E2E smoke test (T7.2)

- [ ] Run full tier3 E2E test from spec (portfolio, projects, Q&A, notes, conversations)
- [ ] Fix any failures
- [ ] Commit

### Task 28: Complete documentation (T7.3)

- [ ] Finalize `docs/system-design.md` with architecture diagram, data flow, cache strategy, latency considerations, "considered but not built" section
- [ ] Finalize `docs/test-plan.md` with coverage summary
- [ ] Finalize `docs/retrospective.md` with honest assessment of decisions, what was hard, what you'd change
- [ ] Update `setup-guide.md` with correct versions
- [ ] Verify no TODO/FIXME/TBD/FILL_IN markers remain
- [ ] Commit

---

## Phase 8 — Shared Rust Layer (STRETCH)

### Task 29: Shared types crate with UniFFI (T8.1)

Only if Phases 1-7 are complete.

- [ ] Create `shared/platform/Cargo.toml` with uniffi
- [ ] Create shared types in `shared/platform/src/lib.rs`
- [ ] Create `shared/platform/BUILD`
- [ ] Generate Swift bindings
- [ ] Import in iOS app
- [ ] Verify both `cargo build` and `xcodebuild` pass
- [ ] Commit

---

## State Management

Before starting Task 1, reinitialize `tasks/state.json` to match the v2 spec task IDs (T1.1-T1.4, T2.1-T2.5, T3.1-T3.6, T4.1-T4.2, T5.1-T5.3, T6.1-T6.5, T7.1-T7.3, T8.1). After each task completes, update `state.json` with `"status": "complete"` and `"completed_at"`. Advance `current_task` to the next task.
