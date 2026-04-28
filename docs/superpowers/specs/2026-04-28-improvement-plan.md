# Emulsion — Improvement Plan

**Goal:** Close all gaps against the 24-hour take-home brief. Restore deleted required documentation, strengthen Bazel as primary build system, add iOS tests, wire up shared platform layer, and polish all docs to pass a crit review.

**Current State:** iOS app (968 LOC), Rust backend (974 LOC), Bazel BUILD files for both, UniFFI shared types crate (unstaged). Missing: retrospective, AGENTS.md, CLAUDE.md, iOS tests. Bazel presented as optional. Shared types not wired into either consumer.

**Pre-commit rule:** Before every commit, run `/simplify` on changed code to review for reuse, quality, and efficiency. Fix any issues found, then commit.

**Commit rule:** No co-author tags. No AI references in commit messages.

---

## Execution Protocol

### Verification Tiers

Every task ends with a 3-tier verification. Tiers are sequential — a tier must exit 0 before the next runs. Do not skip tiers. Do not judge whether a failure "looks close enough."

```
IMPLEMENT → TIER 1 → TIER 2 → TIER 3 → /simplify → COMMIT
```

| Tier | Purpose | Target Time | What it checks |
|------|---------|-------------|----------------|
| **Tier 1** | Build check | ~5s | Files exist, code compiles, no syntax errors |
| **Tier 2** | Unit tests | ~30s | Content correctness, test suite passes, patterns present |
| **Tier 3** | Integration | ~60s | Cross-component checks, counts, end-to-end verification |

### 3-Strike Rule

On any tier failure:

1. **Strike 1:** Diagnose root cause. Fix. Re-run the failing tier AND all previous tiers.
2. **Strike 2:** Same root cause fails again. Try a different fix approach. Re-run all tiers from tier 1.
3. **Strike 3:** Same root cause fails a third time. **STOP.** Write a post-mortem:

```markdown
## Post-Mortem: [Task ID] — [Failing Tier]

**Root cause:** [What went wrong]
**Attempts:** [What was tried 3 times]
**Blocked on:** [What needs to happen to unblock]
**Resumption hint:** [Where to pick up in the next session]
```

Commit the post-mortem and move to the next task. Do not attempt a 4th fix in the same session — the next session reads the post-mortem and picks it up fresh.

### Task Completion Flow

For each task:

1. Read the task description, files, and all steps
2. Implement all steps
3. Run tier 1 → tier 2 → tier 3 (apply 3-strike rule on failure)
4. All tiers pass → run `/simplify` on changed files → fix any issues → re-run tiers if code changed
5. Commit with the specified message (no co-author tags)
6. Proceed to next task

---

## Phase 1 — Restore Required Documentation

### Task 1.1: Restore `docs/retrospective.md`

**Files:**
- Create: `docs/retrospective.md`

- [ ] **Step 1: Write the retrospective**

The retrospective must cover every phase of development. Use the genuine technical content from the original (Bazel version compat, axum route syntax, Swift 6 concurrency, manual pbxproj) but written in first person, no AI-process references.

Sections:
1. **Phase 1 — Repo Foundation & Bazel**: Chose Bazel 9 with Bzlmod over WORKSPACE for forward compatibility. Finding compatible rule versions (rules_rust 0.70.0, rules_apple 4.5.3, rules_swift 3.6.1) took trial and error. Created Xcode project alongside Bazel for faster iteration. Hand-crafting pbxproj was tedious — every Swift file needs manual PBXFileReference/PBXBuildFile/PBXGroup entries.
2. **Phase 2 — Data Layer**: Chose sqlx over diesel for lighter macros. Atomic SQL counters (`col = col + 1`) to eliminate races. JSON strings for arrays in SQLite — acceptable for small fixed datasets. axum 0.7.9 uses `:id` not `{id}` (0.8+ syntax) which caused 404s until identified.
3. **Phase 3 — API Handlers**: tokio::join! fan-out for portfolio endpoint. Cache-aside with DashMap, no TTL. Theatre flag for seeded inbox data.
4. **Phase 4 — Seed Data**: include_str! embeds JSON at compile time. Clear-and-reinsert idempotency.
5. **Phase 5 — iOS Foundation**: @Observable over ObservableObject (iOS 26). @MainActor on all ViewModels for Swift 6 strict concurrency. APIClient as plain class (not singleton) for testability.
6. **Phase 6 — iOS Screens**: NavigationStack from PortfolioHomeView. Optimistic UI for interested counters. Custom FlowLayout for skills tags.
7. **Phase 7 — Shared Platform Layer (Bonus)**: UniFFI 0.28 to define domain types once in Rust, generate Swift bindings. UDL schema covers all 8 domain types + 5 response DTOs. xcframework generation for iOS consumption.
8. **Priorities & Tradeoffs**: What was prioritized (working E2E system, clean architecture, Bazel both targets, documentation) vs what was cut (iOS XCTest, full Bazel-as-primary workflow, pagination, auth). Honest about gaps.
9. **What I'd Change With More Time**: SPM instead of raw Xcode project. XCTest from the start. sqlx query macros for compile-time validation. FTS5 for Q&A. Wire shared types into both consumers.
10. **What I Learned**: Bazel 9 Bzlmod ecosystem, UniFFI binding generation, Swift 6 strict concurrency model, axum version-specific route syntax.

- [ ] **Step 2: Verify**

tier1: `test -s docs/retrospective.md && echo "tier1 pass"`
tier2: `bash -c 'grep -q "Bazel" docs/retrospective.md && grep -q "axum" docs/retrospective.md && grep -q "Swift 6" docs/retrospective.md && grep -q "UniFFI" docs/retrospective.md && grep -q "tradeoff\|prioriti" docs/retrospective.md && echo "tier2 pass"'`
tier3: `bash -c 'sections=$(grep -c "^## \|^### " docs/retrospective.md); [ "$sections" -ge 8 ] && echo "tier3 pass ($sections sections)" || echo "tier3 FAIL ($sections sections, need 8+)"'`

- [ ] **Step 3: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add docs/retrospective.md
git commit -m "docs: add retrospective with phase-by-phase decisions and learnings"
```

---

### Task 1.2: Create clean `CLAUDE.md`

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md as a standard agent configuration file**

This is a conventional repo guide, NOT an autonomous execution manual. Contents:

```markdown
# Emulsion

## Build

# Full stack (macOS)
./run.sh

# Backend only
cargo run -p portfolio-api

# Seed database
cargo run -p seed

# iOS (Xcode)
open apps/ios/PortfolioApp.xcodeproj  # Cmd+R for Simulator

# Bazel
bazel build //services/portfolio-api:server
bazel build //apps/ios:app
bazel build //shared/emulsion-types:emulsion_types

## Test

cargo test                    # All Rust tests (16 across 7 repos + cache)
cargo test -p portfolio-api   # Backend only
cargo test -p emulsion-types  # Shared types only

## Architecture

- apps/ios/ — SwiftUI, MVVM with @Observable, URLSession networking
- services/portfolio-api/ — Rust axum 0.7.9, SQLite WAL, DashMap cache
- shared/emulsion-types/ — UniFFI 0.28, domain types defined in Rust, Swift bindings generated
- tools/seed/ — Populates SQLite from embedded CV JSON

## Conventions

- Handlers: extract AppState → call repo → map error → return Json
- Views: View → ViewModel (@Observable) → APIClient call
- Counters: atomic SQL `UPDATE SET col = col + 1` (never read-modify-write)
- Theme: all colors/fonts via LapseTheme (never hardcoded)
- Naming: *_handler.rs, *_repo.rs, *View.swift, *ViewModel.swift

## Adding Things

- New API endpoint: handler in src/handlers/, repo in src/repositories/, route in src/routes/mod.rs
- New iOS screen: View in Sources/Views/, ViewModel in Sources/ViewModels/
- New data model: Rust struct in shared/emulsion-types/src/lib.rs + UDL, re-generate bindings
- New Bazel target: BUILD file in the package directory
```

- [ ] **Step 2: Verify**

tier1: `test -s CLAUDE.md && echo "tier1 pass"`
tier2: `bash -c 'grep -q "cargo test" CLAUDE.md && grep -q "bazel build" CLAUDE.md && grep -q "Conventions" CLAUDE.md && echo "tier2 pass"'`
tier3: `bash -c 'grep -q "portfolio-api" CLAUDE.md && grep -q "emulsion-types" CLAUDE.md && grep -q "Adding Things" CLAUDE.md && echo "tier3 pass"'`

- [ ] **Step 3: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md with build commands and conventions"
```

---

## Phase 2 — Agent Optimization

### Task 2.1: Restore and enhance `AGENTS.md`

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Write AGENTS.md**

Frame this as intentional agent-optimization — the brief asks for it. Include:

1. **Purpose statement**: This repo is structured so AI coding agents can orient quickly, find the right files, and follow established patterns.
2. **Directory Map** (table): apps/ios, services/portfolio-api, shared/emulsion-types, tools/seed, docs
3. **Naming Conventions** (table): *_handler.rs, *_repo.rs, *View.swift, *ViewModel.swift
4. **Where to Add Things**: step-by-step for new endpoint, new screen, new model, new Bazel target
5. **Patterns & Conventions**: handler pattern, ViewModel pattern, atomic counters, theme usage, polaroid card rotation
6. **Build & Test Commands**: cargo build/test, xcodebuild, bazel build for each target
7. **Common Tasks** (numbered checklists):
   - Add a new API endpoint (4 steps)
   - Add a new iOS screen (3 steps)
   - Add a new shared type (5 steps: lib.rs → UDL → generate → update iOS → update backend)
   - Run full verification (3 commands)

- [ ] **Step 2: Verify**

tier1: `test -s AGENTS.md && echo "tier1 pass"`
tier2: `bash -c 'grep -q "Directory Map" AGENTS.md && grep -q "Naming Conventions" AGENTS.md && grep -q "Where to Add" AGENTS.md && grep -q "Common Tasks" AGENTS.md && echo "tier2 pass"'`
tier3: `bash -c 'grep -q "bazel build" AGENTS.md && grep -q "cargo test" AGENTS.md && grep -q "emulsion-types" AGENTS.md && echo "tier3 pass"'`

- [ ] **Step 3: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add AGENTS.md
git commit -m "docs: add AGENTS.md for agent-optimized codebase navigation"
```

---

## Phase 3 — Bazel as Primary Build System

### Task 3.1: Add BUILD for shared/emulsion-types

**Files:**
- Create: `shared/emulsion-types/BUILD`

- [ ] **Step 1: Create BUILD file**

```starlark
load("@rules_rust//rust:defs.bzl", "rust_library")

rust_library(
    name = "emulsion_types",
    srcs = glob(["src/**/*.rs"]),
    deps = [
        "@crates//:uniffi",
        "@crates//:serde",
    ],
    edition = "2021",
    visibility = ["//visibility:public"],
)
```

- [ ] **Step 2: Update MODULE.bazel if needed**

Check that `shared/emulsion-types/Cargo.toml` is already listed in the crate_universe manifest paths. If not, add it.

Current MODULE.bazel has manifest paths for `//:Cargo.toml`, `//services/portfolio-api:Cargo.toml`, `//tools/seed:Cargo.toml`. Need to add `//shared/emulsion-types:Cargo.toml`.

- [ ] **Step 3: Verify**

tier1: `bazel build //shared/emulsion-types:emulsion_types 2>&1 | tail -5`
tier2: `bazel query '//shared/...' 2>&1 | grep emulsion_types`

- [ ] **Step 4: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add shared/emulsion-types/BUILD MODULE.bazel
git commit -m "build: add Bazel target for shared emulsion-types crate"
```

---

### Task 3.2: Verify all Bazel targets build

- [ ] **Step 1: Build all three targets**

```bash
bazel build //services/portfolio-api:server
bazel build //apps/ios:app
bazel build //shared/emulsion-types:emulsion_types
```

- [ ] **Step 2: Fix any build failures**

If iOS target fails: check rules_apple/rules_swift versions, Xcode path, provisioning.
If Rust targets fail: check crate_universe resolution, missing deps.

- [ ] **Step 3: Document working state**

Record the exact commands and their success in test-plan.md (Phase 6).

---

### Task 3.3: Update README to present Bazel as primary

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Change the Build row in the Stack table**

Old: `| **Build** | Cargo workspaces · Xcode · Bazel config present |`
New: `| **Build** | Bazel 9.1.0 (Bzlmod) · Cargo workspaces · Xcode |`

- [ ] **Step 2: Add Bazel commands to Quick Start**

Add a "Bazel" subsection after Manual:

```markdown
### Bazel

```bash
# Build everything
bazel build //services/portfolio-api:server //apps/ios:app //shared/emulsion-types:emulsion_types

# Build individually
bazel build //services/portfolio-api:server    # Rust backend
bazel build //apps/ios:app                     # iOS app
bazel build //shared/emulsion-types:emulsion_types  # Shared types
```

Cargo and Xcode remain available for faster iteration during development.
```

- [ ] **Step 3: Verify**

tier1: `grep -q "Bazel 9" README.md && echo "tier1 pass"`
tier2: `grep -q "bazel build //services" README.md && grep -q "bazel build //apps" README.md && echo "tier2 pass"`
tier3: `bash -c '! grep -q "Bazel config present" README.md && echo "tier3 pass (old language removed)"'`

- [ ] **Step 4: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add README.md
git commit -m "docs: present Bazel as primary build system in README"
```

---

## Phase 4 — Shared Platform Layer Polish

### Task 4.1: Wire backend to use emulsion-types

**Files:**
- Modify: `services/portfolio-api/src/models/portfolio.rs` (and other model files)

- [ ] **Step 1: Re-export shared types in backend models**

The backend models currently define their own structs with `#[derive(FromRow, Serialize)]`. The shared types have `#[derive(Serialize, Deserialize)]` but NOT `FromRow`.

**Approach:** Keep backend model files as-is (they need `sqlx::FromRow` which the shared types don't have). Add a single-line comment at the top of each backend model file linking to the canonical definition. This documents the relationship without a risky refactor.

```rust
// Canonical type: emulsion_types::Portfolio (shared/emulsion-types/src/lib.rs)
```

- [ ] **Step 2: Verify backend still builds and tests pass**

tier1: `cargo build -p portfolio-api 2>&1 | tail -3`
tier2: `cargo test -p portfolio-api 2>&1 | tail -5`

- [ ] **Step 3: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add services/portfolio-api/
git commit -m "docs: link backend models to canonical shared type definitions"
```

---

### Task 4.2: Verify shared types crate builds and tests

**Files:**
- Potentially modify: `shared/emulsion-types/src/lib.rs`

- [ ] **Step 1: Build the shared crate**

```bash
cargo build -p emulsion-types
```

- [ ] **Step 2: Add a basic test to lib.rs**

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn portfolio_roundtrip() {
        let p = Portfolio {
            id: 1,
            name: "Test".to_string(),
            bio: "Bio".to_string(),
            photo_path: None,
            summary: "Summary".to_string(),
            created_at: "2026-01-01 00:00:00".to_string(),
            view_count: 0,
            interested_count: 0,
        };
        let json = serde_json::to_string(&p).unwrap();
        let decoded: Portfolio = serde_json::from_str(&json).unwrap();
        assert_eq!(p.name, decoded.name);
        assert_eq!(p.id, decoded.id);
    }

    #[test]
    fn portfolio_response_contains_nested() {
        let resp = PortfolioResponse {
            portfolio: Portfolio {
                id: 1, name: "N".into(), bio: "B".into(),
                photo_path: Some("/photo.jpg".into()),
                summary: "S".into(), created_at: "".into(),
                view_count: 10, interested_count: 5,
            },
            experiences: vec![],
            skills: vec![],
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("\"name\":\"N\""));
        assert!(json.contains("\"experiences\":[]"));
    }

    #[test]
    fn ask_response_with_none_match() {
        let resp = AskResponse {
            match_result: None,
            fallback: Some("leave_a_note".into()),
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("\"fallback\":\"leave_a_note\""));
    }
}
```

Note: requires adding `serde_json` as a dev-dependency to `shared/emulsion-types/Cargo.toml`:
```toml
[dev-dependencies]
serde_json = "1"
```

- [ ] **Step 3: Verify**

tier1: `cargo build -p emulsion-types 2>&1 | tail -3`
tier2: `cargo test -p emulsion-types 2>&1 | tail -5`
tier3: `bash -c 'count=$(cargo test -p emulsion-types 2>&1 | grep "test result" | grep -o "[0-9]* passed" | grep -o "[0-9]*"); [ "$count" -ge 3 ] && echo "tier3 pass ($count tests)" || echo "tier3 FAIL"'`

- [ ] **Step 4: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add shared/emulsion-types/
git commit -m "test: add serialization roundtrip tests for shared types"
```

---

### Task 4.3: Update system-design.md for shared layer

**Files:**
- Modify: `docs/system-design.md`

- [ ] **Step 1: Add Shared Platform Layer section**

Add after the architecture diagram section:

```markdown
## Shared Platform Layer

`shared/emulsion-types` is a Rust crate that defines all domain types once:

- **8 domain structs:** Portfolio, Experience, Skill, Project, QAPair, Note, Conversation, Message
- **5 response DTOs:** PortfolioResponse, AskMatch, AskResponse, ConversationsResponse, MessagesResponse
- **UDL schema** (`emulsion_types.udl`): UniFFI interface definition for cross-language binding generation
- **Generated Swift bindings** (`generated/emulsion_types.swift`): Type-safe Swift structs generated from the Rust definitions
- **xcframework generation** (`generate-bindings.sh`): Builds for aarch64-apple-ios-sim, produces .xcframework

The backend depends on `emulsion-types` via Cargo path dependency. The iOS app currently uses its own Codable models (matching the same JSON contract) with the generated Swift bindings available for future migration to direct FFI calls.

This architecture means a type change in Rust propagates to Swift bindings automatically — no manual sync needed.
```

- [ ] **Step 2: Verify**

tier1: `grep -q "Shared Platform Layer" docs/system-design.md && echo "tier1 pass"`
tier2: `grep -q "UniFFI" docs/system-design.md && grep -q "emulsion_types.udl" docs/system-design.md && echo "tier2 pass"`

- [ ] **Step 3: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add docs/system-design.md
git commit -m "docs: add shared platform layer section to system design"
```

---

## Phase 5 — iOS Tests

### Task 5.1: Add XCTest infrastructure

**Files:**
- Create: `apps/ios/Tests/PortfolioAppTests/ModelTests.swift`
- Create: `apps/ios/Tests/PortfolioAppTests/APIClientTests.swift`
- Create: `apps/ios/Tests/PortfolioAppTests/ViewModelTests.swift`
- Modify: `apps/ios/PortfolioApp.xcodeproj/project.pbxproj` (add test target)
- Modify: `apps/ios/BUILD` (add test target if feasible)

- [ ] **Step 1: Create ModelTests.swift**

Test JSON decoding for all model types, parseJSONArray helper, formatTimestamp:

```swift
import XCTest
@testable import PortfolioApp

final class ModelTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func testPortfolioDecoding() throws {
        let json = """
        {"id":1,"name":"Richard","bio":"Engineer","photo_path":null,
         "summary":"Summary","created_at":"2026-01-01","view_count":10,"interested_count":5}
        """.data(using: .utf8)!
        let p = try decoder.decode(Portfolio.self, from: json)
        XCTAssertEqual(p.id, 1)
        XCTAssertEqual(p.name, "Richard")
        XCTAssertNil(p.photoPath)
        XCTAssertEqual(p.viewCount, 10)
    }

    func testExperienceDecoding() throws {
        let json = """
        {"id":1,"portfolio_id":1,"company":"Acme","role":"Engineer",
         "dates":"2024-2026","bullets":"[\\"Built X\\",\\"Led Y\\"]"}
        """.data(using: .utf8)!
        let e = try decoder.decode(Experience.self, from: json)
        XCTAssertEqual(e.company, "Acme")
        XCTAssertEqual(e.bullets, "[\"Built X\",\"Led Y\"]")
    }

    func testProjectDecoding() throws {
        let json = """
        {"id":1,"portfolio_id":1,"title":"App","role":"Lead",
         "writeup":"Details","screenshots":"[]","view_count":0,"interested_count":0}
        """.data(using: .utf8)!
        let p = try decoder.decode(Project.self, from: json)
        XCTAssertEqual(p.title, "App")
    }

    func testPortfolioResponseDecoding() throws {
        let json = """
        {"portfolio":{"id":1,"name":"R","bio":"B","photo_path":null,
         "summary":"S","created_at":"","view_count":0,"interested_count":0},
         "experiences":[],"skills":[]}
        """.data(using: .utf8)!
        let resp = try decoder.decode(PortfolioResponse.self, from: json)
        XCTAssertEqual(resp.portfolio.name, "R")
        XCTAssertTrue(resp.experiences.isEmpty)
    }

    func testAskResponseWithMatch() throws {
        let json = """
        {"match":{"prompt":"test","answer":"yes"},"fallback":null}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AskResponse.self, from: json)
        XCTAssertEqual(resp.match?.prompt, "test")
        XCTAssertNil(resp.fallback)
    }

    func testAskResponseWithFallback() throws {
        let json = """
        {"match":null,"fallback":"leave_a_note"}
        """.data(using: .utf8)!
        let resp = try decoder.decode(AskResponse.self, from: json)
        XCTAssertNil(resp.match)
        XCTAssertEqual(resp.fallback, "leave_a_note")
    }

    func testParseJSONArrayValid() {
        let result = parseJSONArray("[\"a\",\"b\",\"c\"]")
        XCTAssertEqual(result, ["a", "b", "c"])
    }

    func testParseJSONArrayEmpty() {
        let result = parseJSONArray("")
        XCTAssertTrue(result.isEmpty)
    }

    func testParseJSONArrayInvalidFallback() {
        let result = parseJSONArray("not json")
        XCTAssertEqual(result, ["not json"])
    }

    func testFormatTimestampValid() {
        let result = formatTimestamp("2026-04-28 14:30:00")
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("Apr") || result.contains("28"))
    }

    func testFormatTimestampInvalidPassthrough() {
        let result = formatTimestamp("invalid")
        XCTAssertEqual(result, "invalid")
    }

    func testConversationsResponseDecoding() throws {
        let json = """
        {"conversations":[],"theatre":true}
        """.data(using: .utf8)!
        let resp = try decoder.decode(ConversationsResponse.self, from: json)
        XCTAssertTrue(resp.theatre)
        XCTAssertTrue(resp.conversations.isEmpty)
    }
}
```

- [ ] **Step 2: Create APIClientTests.swift**

Test URL construction and request formation without a live server:

```swift
import XCTest
@testable import PortfolioApp

final class APIClientTests: XCTestCase {

    func testBaseURLDefault() {
        let client = APIClient()
        XCTAssertEqual(client.baseURL.absoluteString, "http://localhost:8080")
    }

    func testBaseURLCustom() {
        let client = APIClient(baseURL: URL(string: "http://example.com:3000")!)
        XCTAssertEqual(client.baseURL.absoluteString, "http://example.com:3000")
    }
}
```

- [ ] **Step 3: Create ViewModelTests.swift**

Test ViewModel initial state (no network calls needed):

```swift
import XCTest
@testable import PortfolioApp

@MainActor
final class ViewModelTests: XCTestCase {

    func testPortfolioViewModelInitialState() {
        let vm = PortfolioViewModel(apiClient: APIClient())
        XCTAssertNil(vm.portfolio)
        XCTAssertTrue(vm.experiences.isEmpty)
        XCTAssertTrue(vm.skills.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }
}
```

- [ ] **Step 4: Add test target to Xcode project**

Update `project.pbxproj` to add:
- PBXFileReference entries for the 3 test files
- PBXBuildFile entries
- A PBXNativeTarget for `PortfolioAppTests` (type `com.apple.product-type.bundle.unit-test`)
- Test host pointing at `PortfolioApp.app`

- [ ] **Step 5: Verify**

tier1: `ls apps/ios/Tests/PortfolioAppTests/ModelTests.swift apps/ios/Tests/PortfolioAppTests/APIClientTests.swift apps/ios/Tests/PortfolioAppTests/ViewModelTests.swift && echo "tier1 pass"`
tier2: `xcodebuild test -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
tier3: `bash -c 'count=$(xcodebuild test -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp -destination "platform=iOS Simulator,name=iPhone 16" 2>&1 | grep -c "Test Case.*passed"); [ "$count" -ge 10 ] && echo "tier3 pass ($count tests)" || echo "tier3 FAIL ($count passed)"'`

- [ ] **Step 6: Simplify & Commit**

Run `/simplify` on changed test files. Fix any issues. Then:
```bash
git add apps/ios/Tests/ apps/ios/PortfolioApp.xcodeproj/
git commit -m "test: add iOS unit tests for models, APIClient, and ViewModels"
```

---

## Phase 6 — Documentation Polish

### Task 6.1: Update test-plan.md

**Files:**
- Modify: `docs/test-plan.md`

- [ ] **Step 1: Add Bazel iOS build to Tier 1**

Add: `- bazel build //apps/ios:app — iOS app builds via Bazel`
Add: `- bazel build //shared/emulsion-types:emulsion_types — Shared types build via Bazel`

- [ ] **Step 2: Add shared types tests to Tier 2**

Add under Tier 2:
```markdown
- **Shared types (3 tests):** portfolio_roundtrip, portfolio_response_contains_nested, ask_response_with_none_match
```

- [ ] **Step 3: Add iOS tests to Tier 2**

Add under Tier 2:
```markdown
- **iOS models (12 tests):** Portfolio/Experience/Project/PortfolioResponse/AskResponse/ConversationsResponse decoding, parseJSONArray (valid/empty/invalid), formatTimestamp (valid/invalid)
- **iOS APIClient (2 tests):** default baseURL, custom baseURL
- **iOS ViewModel (1 test):** PortfolioViewModel initial state
```

- [ ] **Step 4: Update coverage table**

Add rows:
```markdown
| Shared types | 3 tests | `cargo test -p emulsion-types` |
| iOS models | 12 tests | `xcodebuild test` |
| iOS APIClient | 2 tests | `xcodebuild test` |
| iOS ViewModel | 1 test | `xcodebuild test` |
```

- [ ] **Step 5: Update "What Is Not Tested" table**

Remove or update the "iOS unit tests (XCTest)" row. Replace with:
```markdown
| iOS ViewModel network paths | ViewModels tested for initial state only. Network-dependent paths (load, submit) require a mock server or protocol-based APIClient. |
```

- [ ] **Step 6: Verify**

tier1: `grep -q "bazel build //apps/ios" docs/test-plan.md && echo "tier1 pass"`
tier2: `grep -q "emulsion-types" docs/test-plan.md && grep -q "iOS models" docs/test-plan.md && echo "tier2 pass"`
tier3: `bash -c '! grep -q "Time constraint" docs/test-plan.md && echo "tier3 pass (time constraint language removed)"'`

- [ ] **Step 7: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add docs/test-plan.md
git commit -m "docs: update test plan with iOS tests, shared types, and Bazel targets"
```

---

### Task 6.2: Update README.md for shared layer and structure

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Verify shared layer row already added**

The unstaged diff already adds `| **Shared** | UniFFI 0.28 ... |`. Confirm this is present.

- [ ] **Step 2: Add test commands section**

After the API Endpoints section, add:

```markdown
## Tests

```bash
# Rust backend (16 tests)
cargo test -p portfolio-api

# Shared types (3 tests)
cargo test -p emulsion-types

# iOS (15 tests, requires Xcode + Simulator)
xcodebuild test -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

See [`docs/test-plan.md`](docs/test-plan.md) for the full test plan.
```

- [ ] **Step 3: Verify**

tier1: `grep -q "cargo test" README.md && grep -q "xcodebuild test" README.md && echo "tier1 pass"`
tier2: `grep -q "emulsion-types" README.md && grep -q "test-plan.md" README.md && echo "tier2 pass"`

- [ ] **Step 4: Simplify & Commit**

Run `/simplify` on changed files. Fix any issues. Then:
```bash
git add README.md
git commit -m "docs: add test commands and shared layer to README"
```

---

## Phase 7 — Final Verification

### Task 7.1: Full build verification

- [ ] **Step 1: Cargo builds**

```bash
cargo build --workspace 2>&1 | tail -5
```
Expected: `Finished` with exit 0

- [ ] **Step 2: Cargo tests**

```bash
cargo test --workspace 2>&1 | tail -10
```
Expected: All tests pass, 19+ tests (16 backend + 3 shared types)

- [ ] **Step 3: Bazel builds**

```bash
bazel build //services/portfolio-api:server 2>&1 | tail -3
bazel build //apps/ios:app 2>&1 | tail -3
bazel build //shared/emulsion-types:emulsion_types 2>&1 | tail -3
```
Expected: All three succeed

- [ ] **Step 4: iOS tests**

```bash
xcodebuild test -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```
Expected: 15 tests pass

---

### Task 7.2: Brief requirements checklist

Every requirement from the brief, with a concrete verification:

**Core Requirements:**

- [ ] **R1: Monorepo setup** — single repo with iOS, backend, shared code, docs
  - verify: `for d in apps/ios services/portfolio-api shared/emulsion-types tools/seed docs; do [ -d "$d" ] || echo "MISSING: $d"; done`

- [ ] **R2: iOS application** — buildable, runnable, MVVM, backend interaction, enough UI
  - verify: `xcodebuild build -project apps/ios/PortfolioApp.xcodeproj -scheme PortfolioApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -3`
  - verify: `ls apps/ios/Sources/Views/*.swift | wc -l` (expect 7+)
  - verify: `grep -r "apiClient" apps/ios/Sources/ViewModels/ | wc -l` (expect 5+ backend interactions)

- [ ] **R3: Rust backend with low latency** — functional API, meaningful endpoints, performance considered
  - verify: `cargo build -p portfolio-api 2>&1 | tail -3`
  - verify: `grep -c "pub async fn" services/portfolio-api/src/handlers/*.rs` (expect 10+)
  - verify: `grep -q "tokio::join!" services/portfolio-api/src/handlers/portfolio_handler.rs` (fan-out)
  - verify: `grep -q "DashMap" services/portfolio-api/src/cache.rs` (caching)
  - verify: `grep -q "col + 1\|col +1" services/portfolio-api/src/repositories/*.rs` (atomic counters)

- [ ] **R4: Bazel build system** — builds iOS, backend, and shared modules
  - verify: `bazel build //services/portfolio-api:server //apps/ios:app //shared/emulsion-types:emulsion_types`

- [ ] **R5: Agent-optimized codebase** — intentional design for AI agents
  - verify: `test -s AGENTS.md && test -s CLAUDE.md && echo "pass"`
  - verify: `grep -q "Directory Map" AGENTS.md && grep -q "Common Tasks" AGENTS.md`

**Documentation:**

- [ ] **D1: README** — what, how structured, how to build/run, how to test, assumptions
  - verify: `grep -q "Quick Start" README.md && grep -q "Structure" README.md && grep -q "cargo test\|xcodebuild test" README.md`

- [ ] **D2: System Design** — architecture, components, data flow, tradeoffs, performance
  - verify: `grep -q "Architecture" docs/system-design.md && grep -q "Data Flow" docs/system-design.md && grep -q "Latency" docs/system-design.md && grep -q "Shared Platform" docs/system-design.md`

- [ ] **D3: Test Plan** — how to test, evaluate stability
  - verify: `grep -q "Tier 1" docs/test-plan.md && grep -q "Tier 2" docs/test-plan.md && grep -q "Tier 3" docs/test-plan.md`

- [ ] **D4: Retrospective** — decisions, priorities, alternatives, learnings
  - verify: `grep -q "Bazel" docs/retrospective.md && grep -q "prioriti\|tradeoff" docs/retrospective.md && grep -q "learned\|Learning" docs/retrospective.md`

**Bonus:**

- [ ] **B1: Shared Rust platform layer** — types defined in Rust, iOS + Android bindings
  - verify: `test -s shared/emulsion-types/src/lib.rs && test -s shared/emulsion-types/src/emulsion_types.udl && test -s shared/emulsion-types/generated/emulsion_types.swift`

**Git:**

- [ ] **G1: Sensible commit history** — clear messages, meaningful steps, iterative development
  - verify: `git log --oneline | wc -l` (expect 20+)
  - verify: `git log --oneline | head -20` (review messages are descriptive)

---

### Task 7.3: Final commit verification

- [ ] **Step 1: Check no uncommitted changes**

```bash
git status
```
Expected: clean working tree

- [ ] **Step 2: Verify .gitignore excludes build artifacts**

```bash
grep -q "bazel-" .gitignore && grep -q "target/" .gitignore && grep -q "\.db$\|dev\.db" .gitignore && echo "pass"
```

- [ ] **Step 3: Full requirements pass count**

Run all verify commands from Task 7.2. Count passes. Target: 100% of core requirements, 100% of documentation, bonus present.
