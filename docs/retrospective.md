# Retrospective

## Phase 1 — Repo Foundation & Bazel

### Key Decisions
- **Bazel 9 with Bzlmod:** Chose MODULE.bazel over WORKSPACE for forward compatibility. Required research to find compatible rule versions (rules_rust 0.70.0, rules_apple 4.5.3, rules_swift 3.6.1, apple_support 2.5.4).
- **Xcode project fallback:** Created a hand-crafted .xcodeproj alongside the Bazel iOS target. This allows iterating in Xcode (faster feedback loop) while Bazel owns the canonical build.
- **Monorepo with workspace Cargo.toml:** Single workspace with two members (portfolio-api, seed). Shared dependency versions, single lock file.

### What Was Hard
- Finding Bazel 9 compatible rule versions. The Bazel Central Registry had version compatibility information, but it took trial and error to get rules_rust, rules_apple, and rules_swift all working together.
- Hand-crafting the pbxproj file. Without the xcodeproj gem (system Ruby permission issue), wrote the project file by hand. Every new Swift file needs manual PBXFileReference, PBXBuildFile, and PBXGroup entries.

### What I Would Change
- Use `swift package init` for the iOS app instead of a raw Xcode project. SPM handles file discovery automatically and would have saved significant pbxproj maintenance overhead.

## Phase 2 — Data Layer

### Key Decisions
- **sqlx with compile-time query checking:** Chose sqlx over diesel for lighter macro overhead. Used `SQLX_OFFLINE=true` with `cargo sqlx prepare` for CI-reproducible builds.
- **Atomic SQL counters:** `UPDATE SET col = col + 1` instead of read-modify-write. Eliminates race conditions without transactions.
- **JSON strings for arrays:** Experience bullets and project screenshots stored as JSON strings in SQLite rather than normalized tables. Acceptable tradeoff for a demo with small, fixed datasets.

### What Was Hard
- axum 0.7.9 uses `:id` for path parameters, not `{id}` (which is axum 0.8+ syntax). This caused all parameterized endpoints to return 404. Took debugging to identify the version-specific syntax.

### What I Would Change
- Would use sqlx query macros (`query_as!`) instead of raw string queries. Compile-time type checking would catch schema mismatches earlier. Skipped due to the need for `cargo sqlx prepare` setup.

## Phase 3 — API Handlers

### Key Decisions
- **Portfolio fan-out with tokio::join!:** Three concurrent queries (portfolio, experiences, skills) for the main endpoint. Reduces wall-clock latency.
- **Cache-aside with DashMap:** Simple in-process cache. No TTL — invalidation is write-driven. Appropriate for single-server, single-user demo.
- **Theatre flag on inbox responses:** `"theatre": true` in conversations/messages responses signals to the iOS client that this is seeded demo data.

### What Was Hard
- Nothing significant. The handler pattern (extract → repo → map error → Json) is mechanical once established. The fan-out was the most interesting piece.

## Phase 4 — Seed Data

### Key Decisions
- **include_str! for CV JSON:** Embeds the JSON at compile time. No runtime file path concerns.
- **Clear-and-reinsert idempotency:** Seed deletes all data then re-inserts. Makes the seed command safe to run multiple times.

## Phase 5 — iOS Foundation

### Key Decisions
- **@Observable over ObservableObject:** Targeting iOS 26, so used the modern Observation framework. Cleaner syntax, no `@Published` boilerplate.
- **@MainActor on all ViewModels:** Required by Swift 6 strict concurrency. Ensures UI state mutations happen on the main actor.
- **APIClient as a plain class:** Not a singleton. Injected through AppState so it's testable and configurable.

### What Was Hard
- Swift 6 strict concurrency. Non-`@MainActor` async methods on `@Observable` classes cause "sending risks data races" errors. Required `@MainActor` on every ViewModel.
- Manual pbxproj maintenance. Every new file (3 theme, 3 APIClient, 6 ViewModels, 10 Views, 2 Components) needed manual entries across 4 sections of the project file.

## Phase 6 — iOS Screens

### Key Decisions
- **NavigationStack from PortfolioHomeView:** Central hub with NavigationLinks to all screens. Simple, flat navigation without deep nesting.
- **Optimistic UI for "Interested":** Increments the local count immediately, then fires the network request. Better perceived performance.
- **FlowLayout for skills tags:** Custom Layout protocol implementation for wrapping tag chips. More natural than a grid for variable-width items.
- **Disabled send in ConversationThreadView:** TextField and send button both `.disabled(true)`. Clearly communicates theatre mode.

### What Was Hard
- Getting the Lapse aesthetic right with code-only SwiftUI. No asset catalog or design tokens beyond the theme enum. The polaroid card effect (rotation + shadow + off-white background) carries the visual identity.

## Overall Assessment

**What went well:**
- Bazel iOS + Rust both building from the start. This was the highest-risk task and it worked on the first attempt.
- The three-tier verification pattern caught real bugs (axum route syntax) before they became integration issues.
- The autonomous agent protocol (state.json + CLAUDE.md) enabled seamless session resumption.

**What I'd do differently:**
- Use Swift Package Manager instead of a hand-crafted Xcode project.
- Add XCTest targets from the start for ViewModel unit tests.
- Use sqlx query macros for compile-time schema validation.
- Consider using a local SQLite database on iOS instead of network calls — eliminates the need for a running server and works offline.
