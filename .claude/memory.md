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

## Decisions

<!-- Architectural or tooling choices made during implementation and why. -->
<!-- Example: - [2026-04-28] Using rules_apple 3.x not 4.x — 4.x broke simulator provisioning on macOS 15 -->

## Patterns

<!-- Code structures established for the first time — handler shape, view shape, etc. -->
<!-- Example: - [2026-04-28] All handlers: extract AppState → call repo fn → map sqlx::Error → Json(response) -->

## Gotchas

<!-- Things that failed or surprised — especially version constraints and env quirks. -->
<!-- Example: - [2026-04-28] SQLite WAL mode must be set at connection time in db.rs, not in migration SQL -->

## Open Questions

<!-- Unresolved items for the next session or for a human to decide. -->
<!-- Remove entries once resolved; add resolution as a Decision entry. -->
- [ ] Hero photo: use placeholder SVG or real photo? (see prd.md §15)
- [ ] Project screenshots for PharmaBridge / MARL dissertation: available or text-only cards?
- [ ] Dark mode: PRD §15 suggests no for MVP — confirm before T5.2
