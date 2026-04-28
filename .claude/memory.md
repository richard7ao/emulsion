# Project Memory
#
# WHAT THIS IS: Accumulated knowledge from every build session — decisions made,
# patterns established, gotchas hit, and open questions. Written by the agent,
# read at every session start before any code is touched.
#
# HOW TO USE: The agent reads this file at the top of every session (Step 1 of
# CLAUDE.md boot protocol). Add new entries under the appropriate section header
# using format: `- [YYYY-MM-DD] <one-line entry>`. Commit alongside state.json.

---

## Project Context (read this first)

- [2026-04-28] This is a 24h take-home submission for a Lapse engineering interview.
  The primary reviewer is a Lapse engineer. Engineering choices (monorepo, Rust backend,
  Bazel, agent-optimised structure) are being evaluated as much as the iOS app itself.
  The aesthetic (polaroid/film) must be executed with restraint — if it looks costume-y, strip back.
  Be explicit in docs/retrospective.md about what is theatre vs. real. See prd.md for full context.

- [2026-04-28] Repo name: `emulsion` (github.com/richard7ao/emulsion).
  Portfolio subject: Richard Lao — software engineer, founder of Serac Tech (richard@seractech.co.uk).
  Key projects to seed: PharmaBridge, MARL dissertation. See prd.md §2–4 for content scope.

## Decisions

<!-- Architectural or tooling choices made during implementation and why. -->
- [2026-04-28] Port 8080 is the canonical server port — hardcoded in all verify commands,
  CLAUDE.md boot protocol, and the iOS APIClient base URL. Do not change without updating all three.
- [2026-04-28] dev.db lives at services/portfolio-api/dev.db — canonical development database path
  used by Phase 4+ verify commands and the default server startup.
- [2026-04-28] iOS simulator target is `iPhone 16` — hardcoded in all xcodebuild verify commands.
  Must exist on the machine. Create with:
  `xcrun simctl create "iPhone 16" com.apple.CoreSimulator.SimDeviceType.iPhone-16 <runtime>`
  or check available runtimes with `xcrun simctl list devicetypes`.

## Patterns

<!-- Code structures established for the first time — handler shape, view shape, etc. -->
<!-- Example: - [2026-04-28] All handlers: extract AppState → call repo fn → map sqlx::Error → Json(response) -->

## Gotchas

<!-- Things that failed or surprised — especially version constraints and env quirks. -->
- [2026-04-28] SQLite WAL mode must be set at connection init time in src/db.rs via PRAGMA,
  not in migration SQL — migrations run before the connection is fully configured.
- [2026-04-28] Run `cargo sqlx prepare` after ANY change to sqlx query macros, then commit
  the `.sqlx/` directory. All subsequent builds use `SQLX_OFFLINE=true`.
  Forgetting this breaks builds on machines without a live database.
- [2026-04-28] Bazel iOS (T1.4) is the highest-risk task in the whole spec — rules_apple is
  fiddly, especially on newer macOS. Hard timebox: 3 hours. If it fails, use Xcode project
  instead (see CLAUDE.md §6 for the documented fallback). Do not spend the whole session on it.
- [2026-04-28] xcodebuild first-run requires `-allowProvisioningUpdates` flag or it stalls
  waiting for provisioning confirmation. This flag is already in the T1.4 and T5.1 verify commands.
- [2026-04-28] The iOS polaroid card rotation must be seeded by item index, not `Double.random()`.
  Using random causes cards to re-randomise on every SwiftUI redraw. See T5.2 and T6.2.

## Open Questions

<!-- Unresolved items for the next session or for a human to decide. -->
<!-- Remove entries once resolved; add resolution as a Decision entry. -->
- [ ] Hero photo: use placeholder SVG or real photo? (see prd.md §15). Affects T7.2.
- [ ] Project screenshots for PharmaBridge / MARL dissertation: available or text-only cards?
- [ ] Dark mode: PRD §15 suggests no for MVP — confirm before T5.2 (LapseTheme)
- [ ] CV content for seed binary: check tools/seed/data/cv_template.json and fill in real data
      before running T4.1. The template has structure but placeholder values.
