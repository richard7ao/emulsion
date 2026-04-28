# Portfolio App — Agent Operating Manual
#
# WHAT THIS IS: The autonomous execution guide for this project. Every Claude Code session
# must read this file first. It tells the agent how to boot, resume, verify, and fail safely.
#
# HOW TO USE: Start a Claude Code session in this repo. The agent reads this file, loads
# tasks/state.json, and continues building from exactly where the last session left off.
# Human intervention is only needed if a post-mortem stays unresolved for 3+ sessions.
#
# SPEC:    docs/superpowers/specs/2026-04-28-portfolio-design.md
# STATE:   tasks/state.json
# MEMORY:  .claude/memory.md
# PRD:     prd.md

---

## 1. Session Start Protocol (MANDATORY — run before writing any code)

Read these two files in order. Do not skip either. Do not write any code before completing steps 1–5.

### Step 1 — Internalize Memory
Read `.claude/memory.md`. Apply all Decisions, Patterns, and Gotchas before touching any code.

### Step 2 — Load State
Read `tasks/state.json`.

If `tasks/state.json` does not exist: copy the schema from Section 8 below, initialize all
tasks to `"pending"`, set `current_phase: "phase_1"`, `current_task: "T1.1"`, write the file,
then skip to Step 4.

### Step 3 — Process Post-Mortems
Find the latest entry in `postmortems[]` where `"resolved": false`.

| failure_type         | First action before any implementation                                       |
|----------------------|-----------------------------------------------------------------------------|
| verification_failure | Read `output_tail`. Diagnose and fix root cause. Do not re-attempt blindly. |
| context_exhaustion   | Read `resumption_hint`. Resume implementation from the described state.     |

If no unresolved post-mortems exist: proceed to Step 4.

### Step 4 — Locate Current Task
Open `docs/superpowers/specs/2026-04-28-portfolio-design.md`.
Find the task matching `current_task` in state.json. Read its description, subtasks,
requires, and all three verify commands in full before starting.

### Step 5 — Check Dependencies
Every task with a `requires:` field must have all listed tasks showing `"status": "complete"`
in state.json. If any dependency is incomplete: STOP. Report the blocker. Do not proceed.

---

## 2. Task Execution Protocol

```
IMPLEMENT → TIER1 → TIER2 → TIER3
```

Run each tier as a shell command. Tiers are sequential — a tier must exit 0 before the next
runs. Do not skip tiers. Do not judge whether a failure "looks close enough."

**On any tier failure:**
1. Attempt a fix. Re-run the failing tier and all previous tiers.
2. If the same tier fails 3 times on the same root cause: write a post-mortem, commit, STOP.
3. Do not attempt a 4th fix in the same session — the next session reads the post-mortem.

**On all three tiers passing:**
1. Update `tasks/state.json`: set task `"status": "complete"`, add `"completed_at": "<ISO8601>"`.
2. Advance `current_task` to the next task (see ordering in spec Phase Catalog).
3. If all tasks in a phase are complete: set phase `"status": "complete"`, advance `current_phase`.
4. Write any new discoveries to `.claude/memory.md` (see Section 4).
5. Commit: `git add tasks/state.json .claude/memory.md && git commit -m "feat: complete <task_id> — <short description>"`
6. Proceed to next task from Step 4.

---

## 3. Context Pressure Rule

After completing each task, estimate remaining context window percentage.

If remaining < 15%:
- Write a `context_exhaustion` post-mortem to `tasks/state.json`.
- Set `resumption_hint` to: which files were created/modified, what the next task requires,
  and any in-flight state (e.g. "migration written but cargo sqlx prepare not yet run").
- Commit `tasks/state.json` and `.claude/memory.md`.
- STOP. Do not start the next task in a depleted context window.

---

## 4. Memory File Protocol

Write to `.claude/memory.md` when you discover anything in these categories:

- **Decisions:** A non-obvious architectural or tooling choice made during implementation
- **Patterns:** A code structure established for the first time (e.g. handler shape, view shape)
- **Gotchas:** Something that failed or surprised you — especially version constraints
- **Open Questions:** Anything unresolved that the next session or a human should address

Format: `- [YYYY-MM-DD] <one-line entry>` under the appropriate section header.

---

## 5. Server Lifecycle (required for Phase 5+ integration tiers)

Before running tier3 for any task in Phase 5, 6, or 7:
1. Check `server_running` in `tasks/state.json`.
2. If `false`: run `cargo run -p portfolio-api &` from repo root. Update `server_running: true`.
3. After tier3 completes (pass or fail): kill the server process. Update `server_running: false`.

The server must be seeded (Phase 4 complete) before Phase 5 integration checks will pass.

---

## 6. Bazel iOS Fallback (T1.4 specific)

Attempt to build the Bazel iOS target. Timebox: 3 hours of active debugging.

If the target fails to build after the timebox:
1. Create an Xcode project at `apps/ios/PortfolioApp.xcodeproj` instead.
2. Document the failure in `.claude/memory.md` under `## Gotchas`.
3. For all subsequent iOS tasks (T5.x, T6.x, T7.x): use `xcodebuild` commands, not `bazel build`.
4. Bazel continues to own the Rust service — this fallback only affects the iOS target.

---

## 7. Project-Specific Constraints (ABSOLUTE — no exceptions)

| Rule | Reason |
|---|---|
| Never use third-party iOS libraries | PRD §9: only system frameworks |
| Always use `LapseTheme` values for colors, fonts, spacing | Never hardcode visual values |
| Rust counters: `UPDATE ... SET col = col + 1` | Atomic — never read-modify-write |
| Cache invalidation on ALL writes to portfolio, projects, qa_pairs | Stale cache = incorrect counts |
| `SQLX_OFFLINE=true` in build env after `cargo sqlx prepare` is run | CI/build reproducibility |
| All Rust handlers follow: extract state → call repo → map error → return Json | Consistent error surface |
| All SwiftUI views follow: View → ViewModel (ObservableObject) → APIClient call | MVVM-lite per PRD §9 |
| Polaroid card rotation uses item index as seed | Cards must not re-randomise on redraw |
| Theatre (inbox) endpoints return seeded data only — no write path | Documented as scaffolded in UI |

---

## 8. State Schema (for initializing tasks/state.json from scratch)

```json
{
  "schema_version": "1.0",
  "last_updated": "",
  "server_running": false,
  "current_phase": "phase_1",
  "current_task": "T1.1",
  "phases": {
    "phase_1": { "status": "pending", "tasks": {
      "T1.1": { "status": "pending" }, "T1.2": { "status": "pending" },
      "T1.3": { "status": "pending" }, "T1.4": { "status": "pending" }
    }},
    "phase_2": { "status": "pending", "tasks": {
      "T2.1": { "status": "pending" }, "T2.2": { "status": "pending" },
      "T2.3": { "status": "pending" }, "T2.4": { "status": "pending" },
      "T2.5": { "status": "pending" }
    }},
    "phase_3": { "status": "pending", "tasks": {
      "T3.1": { "status": "pending" }, "T3.2": { "status": "pending" },
      "T3.3": { "status": "pending" }, "T3.4": { "status": "pending" },
      "T3.5": { "status": "pending" }, "T3.6": { "status": "pending" }
    }},
    "phase_4": { "status": "pending", "tasks": {
      "T4.1": { "status": "pending" }, "T4.2": { "status": "pending" }
    }},
    "phase_5": { "status": "pending", "tasks": {
      "T5.1": { "status": "pending" }, "T5.2": { "status": "pending" },
      "T5.3": { "status": "pending" }, "T5.4": { "status": "pending" }
    }},
    "phase_6": { "status": "pending", "tasks": {
      "T6.1": { "status": "pending" }, "T6.2": { "status": "pending" },
      "T6.3": { "status": "pending" }, "T6.4": { "status": "pending" },
      "T6.5": { "status": "pending" }, "T6.6": { "status": "pending" }
    }},
    "phase_7": { "status": "pending", "tasks": {
      "T7.1": { "status": "pending" }, "T7.2": { "status": "pending" },
      "T7.3": { "status": "pending" }
    }}
  },
  "postmortems": []
}
```

---

## 9. Post-Mortem Format

Append to `tasks/state.json` `postmortems[]`. Every field is required.

```json
{
  "id": "pm_001",
  "timestamp": "<ISO8601>",
  "phase": "<phase_id>",
  "task": "<task_id>",
  "failure_type": "verification_failure | context_exhaustion",
  "tier_failed": 1,
  "command": "<exact command string that was run>",
  "exit_code": 1,
  "output_tail": "<last 500 chars of combined stdout+stderr>",
  "context_remaining_pct": 72,
  "resumption_hint": "<what was in progress; what the next session must do first>",
  "resolved": false,
  "resolved_at": null
}
```

Set `"resolved": true` and `"resolved_at": "<ISO8601>"` once the task that failed subsequently
reaches all-tiers-pass. Resolved post-mortems stay in the array — they are the audit trail.

---

## 10. File Reference Map

| File | Purpose | Mutates? |
|---|---|---|
| `prd.md` | Product requirements | Never |
| `docs/superpowers/specs/2026-04-28-portfolio-design.md` | Phase/task/verify catalog | Never |
| `tasks/state.json` | Runtime progress + post-mortems | Every task |
| `.claude/memory.md` | Accumulated project knowledge | When discoveries are made |
| `AGENTS.md` | Human conventions for AI agents in this repo | Rarely |
| `CLAUDE.md` | This file — agent operating manual | Never after initial write |
