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

### Key Decisions

- **UniFFI 0.28 for cross-language type sharing:** Domain types defined once in Rust, Swift bindings generated from a UDL schema. A type change in Rust propagates to Swift automatically.
- **All 8 domain types + 5 response DTOs** in the shared crate, covering the full API contract.
- **xcframework generation script:** `generate-bindings.sh` builds for aarch64-apple-ios-sim and packages the output. Standard distribution mechanism for Xcode consumption.
- **Backend depends on shared types via Cargo path.** Backend models maintain their own `FromRow` implementations for sqlx; shared types define the canonical serialisation format.

### What Was Hard

- UniFFI's UDL syntax for optional types and sequences. Documentation is comprehensive but spread across multiple pages — getting `sequence<string>` and nullable fields (`string?`) right required cross-referencing the UDL spec with generated output.

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
- **FTS5 for Q&A matching** instead of LIKE queries.
- **Wire shared types into both consumers** — have the iOS app import the UniFFI-generated types and the backend re-export from the shared crate, eliminating duplicate type definitions.

## What I Learned

- **Bazel 9 Bzlmod is usable but rough.** The biggest gap is version compatibility documentation — you end up testing rule combinations empirically. Once you have a working set, adding new targets is straightforward.
- **UniFFI is surprisingly production-ready.** The setup ceremony (UDL → scaffolding → bindings → xcframework) is a one-time cost. After that, adding a new shared type is three lines of Rust and a few lines of UDL.
- **Swift 6 concurrency catches real bugs but has a learning curve.** The `@Observable` + `@MainActor` + async pattern is the right model, but the compiler needs better diagnostics. I spent more time on concurrency annotations than on actual UI code.
- **Always check version-specific API docs.** The axum `:id` vs `{id}` issue cost me debugging time that reading the 0.7.9 docs would have prevented. Minor version differences can change fundamental APIs.
