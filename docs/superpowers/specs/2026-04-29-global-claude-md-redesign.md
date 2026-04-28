# Global CLAUDE.md Redesign — Design Spec

**Date:** 2026-04-29
**Author:** Richard Lao (with Claude)
**Target file:** `/Users/richardlao/.claude/CLAUDE.md`
**Source materials:**
- Current global: `/Users/richardlao/.claude/CLAUDE.md` (132 lines)
- Reference project manual: `/Users/richardlao/Documents/Github/Personal/emulsion/CLAUDE.md` (and the longer "Portfolio App — Agent Operating Manual" pasted in conversation)
- Reference memory format: `.claude/memory.md` (Decisions/Patterns/Gotchas/Open Questions)
- Reference spec format: `docs/superpowers/specs/2026-04-28-portfolio-design-v2.md`

---

## 1. Goal

Rewrite the global agent operating manual at `~/.claude/CLAUDE.md` so it is more prescriptive, structurally clearer, and more LLM-friendly — modeled after the project-level operating manual style with explicit step-numbered protocols, mandatory `.claude/memory.md`, richer post-mortem schema, file reference map, and a deeper spec hierarchy (Task → Step → Stage with stage-level 4-tier verification).

The redesigned global must remain project-agnostic: it defines the framework; project-level `CLAUDE.md` files extend it with domain specifics.

## 2. Decisions (from brainstorming)

| # | Decision | Choice |
|---|----------|--------|
| 1 | `.claude/memory.md` mandatory? | **Yes — mandatory.** Every project using this protocol must have one; agent reads it at session start before any code. |
| 2 | Verification tiers | **4 tiers kept.** Build → Simplify → Unit → Integration. |
| 3 | Protocol structure | **Three protocols.** Session Start, Task Execution, Task Completion (each with its own trigger event). |
| 4 | Project-specific constraints | **Placeholder section in global.** Global describes the format (Rule \| Reason table); each project CLAUDE.md MUST fill it in. |
| 5 | Spec hierarchy | **Project → Task → Step → Stage**, hierarchical, always. Phase dropped. |
| 6 | Where 4 tiers fire | **Stage level.** Every stage runs all 4 tier blocks (`# tier1_build`, `# tier2_simplify`, `# tier3_unit`, `# tier4_integration`). |

## 3. New Section Layout

The redesigned `~/.claude/CLAUDE.md` will have these sections in order:

1. **Preamble** — what this file is, how it is used (read at every session start).
2. **Session Start Protocol (MANDATORY)** — five steps before any code is written.
3. **Task Execution Protocol** — `IMPLEMENT → TIER 1 → TIER 2 → TIER 3 → TIER 4`. Failure protocol (3-strike).
4. **Task Completion Protocol** — fires when all applicable tiers pass; bookkeeping → commit → next stage.
5. **Context Pressure Rule** — explicit < 15% threshold triggers `context_exhaustion` post-mortem.
6. **Memory File Protocol** — `.claude/memory.md` shape, sections, when to write.
7. **Spec Format** — Task → Step → Stage hierarchy, with stage-level 4-tier verify blocks.
8. **State Schema** — `tasks/state.json` structure, including stage-level tracking.
9. **Post-Mortem Format** — richer schema (id, timestamp, exit_code, context_remaining_pct, etc.).
10. **Project-Specific Constraints (placeholder)** — template `Rule | Reason` table; projects MUST fill in.
11. **Gotchas (cross-project)** — keep current four; project gotchas go in project CLAUDE.md.
12. **File Reference Map** — canonical paths and mutability.
13. **Project-Level Extension** — what project CLAUDE.md adds on top of global.

## 4. Section Drafts

### 4.1 Preamble
```
# Global Agent Operating Manual

WHAT THIS IS: The default operating manual for every Claude Code session.
HOW IT IS USED: The agent reads this file at session start, then reads the
project-level CLAUDE.md (if present), then runs the Session Start Protocol.

Project-level CLAUDE.md extends and overrides this file.
```

### 4.2 Session Start Protocol (MANDATORY)

Read these in order. Do not skip any. Do not write any code before completing all five steps.

1. **Internalize Memory.** Read `.claude/memory.md`. Apply Decisions, Patterns, and Gotchas before touching any code. If `.claude/memory.md` does not exist, create it with the four section headers and proceed.
2. **Load State.** Read `tasks/state.json`. If it does not exist, initialize from the project spec with all statuses `pending`, `current_task`/`current_step`/`current_stage` set to the first item.
3. **Process Post-Mortems.** Find unresolved entries (`resolved: false`) in `postmortems[]`. For `verification_failure`: read `output_tail`, diagnose root cause, fix before retry. For `context_exhaustion`: read `resumption_hint`, resume from described state.
4. **Locate Current Stage.** Open the project spec. Find the stage matching `current_stage`. Read its description and all four verify blocks fully before starting.
5. **Check Dependencies.** If the stage has a `Requires:` field, verify every listed task/step/stage shows `complete` in `state.json`. If any listed dependency is missing or not yet `complete`, STOP and report the blocker. If no `Requires:` field, proceed.

### 4.3 Task Execution Protocol

```
IMPLEMENT → TIER 1 (Build) → TIER 2 (Simplify) → TIER 3 (Unit) → TIER 4 (Integration)
```

- Tiers run sequentially. A tier must exit 0 before the next runs.
- Tier-skip rules: docs-only stages skip all four; config-only stages skip Tier 2 (Simplify); Tier 4 may be skipped only when the stage has no integration surface AND the spec explicitly marks Tier 4 as skipped for that stage.
- On any tier failure: attempt fix → re-run failing tier and all previous tiers.
- **3-Strike Rule:** same tier, same root cause, three failures → write `verification_failure` post-mortem, commit, STOP. Do not attempt a fourth fix in the same session.

### 4.4 Task Completion Protocol

Fires when all applicable tiers pass for a stage.

1. Update `tasks/state.json`: set the stage `"status": "complete"` with `"completed_at": "<ISO8601>"`.
2. Advance `current_stage` to the next stage in the current step.
3. If the last stage of the step is now complete: set step `status: complete`, advance `current_step`.
4. If the last step of the task is now complete: set task `status: complete`, advance `current_task`.
5. Write any new discoveries to `.claude/memory.md` (see Memory File Protocol).
6. Commit in one atomic commit: `git add tasks/state.json .claude/memory.md && git commit -m "feat: complete <stage_id> — <short description>"`
7. Return to Session Start Protocol Step 4 (locate next stage).

### 4.5 Context Pressure Rule

After each stage completes, estimate remaining context window percentage. If under 15%:
1. Append a `context_exhaustion` post-mortem to `tasks/state.json` with `resumption_hint` describing files modified, what the next stage requires, and any in-flight state.
2. Commit `tasks/state.json` and `.claude/memory.md`.
3. STOP. Do not start the next stage in a depleted context window.

### 4.6 Memory File Protocol

`.claude/memory.md` is mandatory. Sections (in this exact order):
```markdown
## Decisions
## Patterns
## Gotchas
## Open Questions
```

Entry format under any section: `- [YYYY-MM-DD] <one-line entry>`.

When to write:
- **Decisions:** non-obvious architectural or tooling choice made during a stage.
- **Patterns:** new code structure established for the first time.
- **Gotchas:** something that failed or surprised — especially version constraints.
- **Open Questions:** anything unresolved for next session or human review.

Writes happen during Task Completion Protocol Step 5, never mid-implementation.

### 4.7 Spec Format

Project specs live at `docs/superpowers/specs/*.md` and define the task catalog. Hierarchy is **Project → Task → Step → Stage**, always.

````markdown
# Project Title — Spec

## T1 — Task Title
**Description:** What this task accomplishes and why.

### T1.1 — Step Title
**Description:** What this step accomplishes within the task.

#### T1.1.1 — Stage Title
**Description:** Files changed and scope for this stage.
**Requires:** T1.0.2  (optional, omit if none)

**Verify:**

```bash
# tier1_build
<deterministic build/lint commands>
```

```bash
# tier2_simplify
<run /simplify on changed files; pass = no issues or all fixed>
```

```bash
# tier3_unit
<unit-test commands targeting changed code>
```

```bash
# tier4_integration
<end-to-end commands; spin up dependencies, assert, tear down>
```
````

Rules:
- Every Stage MUST own a complete set of four verify blocks.
- Verify commands are deterministic shell — no subjective judgment.
- IDs use dotted integers: `T<task>.<step>.<stage>`.
- Phase grouping is dropped; if visual grouping helps, use plain markdown headers above tasks (no formal Phase ID).

### 4.8 State Schema

`tasks/state.json`:

```json
{
  "schema_version": "2.0",
  "last_updated": "<ISO8601>",
  "current_task": "T1",
  "current_step": "T1.1",
  "current_stage": "T1.1.1",
  "tasks": {
    "T1": {
      "status": "pending | in_progress | complete",
      "steps": {
        "T1.1": {
          "status": "pending | in_progress | complete",
          "stages": {
            "T1.1.1": {
              "status": "pending | in_progress | complete",
              "completed_at": "<ISO8601 when complete>"
            }
          }
        }
      }
    }
  },
  "postmortems": []
}
```

Initialization rule: if missing, build the tree from the project spec with all statuses `pending`, set `current_task`/`current_step`/`current_stage` to the first task/step/stage, write the file.

### 4.9 Post-Mortem Format

Append to `tasks/state.json` `postmortems[]`. Every field required.

```json
{
  "id": "pm_001",
  "timestamp": "<ISO8601>",
  "task": "T1",
  "step": "T1.1",
  "stage": "T1.1.1",
  "failure_type": "verification_failure | context_exhaustion",
  "tier_failed": 1,
  "command": "<exact command string that ran>",
  "exit_code": 1,
  "output_tail": "<last 500 chars of combined stdout+stderr>",
  "context_remaining_pct": 72,
  "resumption_hint": "<what was in progress; what next session must do first>",
  "resolved": false,
  "resolved_at": null
}
```

`tier_failed` is null for `context_exhaustion`. Set `resolved: true` and `resolved_at: "<ISO8601>"` once the failing stage subsequently passes all tiers. Resolved entries stay in the array — they are the audit trail.

### 4.10 Project-Specific Constraints (placeholder)

Every project-level `CLAUDE.md` MUST include a constraints section in this exact format:

```markdown
## Project-Specific Constraints (ABSOLUTE — no exceptions)

| Rule | Reason |
|------|--------|
| <rule> | <why> |
| <rule> | <why> |
```

These are project-level invariants the agent must never violate. Examples (from existing projects): "Never use third-party iOS libraries", "Cache invalidation on ALL writes to portfolio tables".

### 4.11 Gotchas (cross-project)

Keep the existing four:
- **Runtime config before migrations** — set connection-time configuration in init code, not migration SQL.
- **Offline build metadata** — regenerate and commit metadata after schema or query changes.
- **Strict concurrency and UI state** — main-thread-bind ViewModels that mutate UI state.
- **Deterministic visual effects** — seed randomness with stable inputs (e.g., item index).

Project-specific gotchas live in project `CLAUDE.md`.

### 4.12 File Reference Map

| File | Purpose | Mutability |
|------|---------|------------|
| `~/.claude/CLAUDE.md` | This file — global operating manual | Rarely (across many projects) |
| `<project>/CLAUDE.md` | Project-level extension | Rarely (per project) |
| `docs/superpowers/specs/*.md` | Task/step/stage catalog | Mutable when scope evolves |
| `docs/superpowers/plans/*.md` | Implementation plans (from writing-plans skill) | Mutable per-plan |
| `tasks/state.json` | Runtime progress + post-mortems | Every stage |
| `.claude/memory.md` | Accumulated project knowledge | When discoveries are made |

### 4.13 Project-Level Extension

Project-level `CLAUDE.md` extends this with:
- Toolchain versions (verified-on-this-machine table).
- Canonical command snippets the spec's verify blocks reuse (e.g., the project's standard `cargo build` invocation, the standard server-startup boilerplate).
- Naming conventions (file suffixes, type prefixes).
- Server lifecycle (when to start/stop long-running services for tier 4).
- Project-specific gotchas (version pins, simulator targets, environment quirks).
- Project-Specific Constraints table (mandatory, see Section 4.10).

If project-level CLAUDE.md and global conflict, project-level wins.

## 5. Out of Scope

- Migrating the existing emulsion `tasks/state.json` to the new schema (the emulsion project may continue with v1 until it next bumps).
- Updating the existing emulsion spec (`2026-04-28-portfolio-design-v2.md`) to the new Task → Step → Stage hierarchy. That spec was written before this redesign and remains valid under v1.
- Creating a migration tool from v1 (Phase → Task) to v2 (Task → Step → Stage) state schema.

## 6. Open Questions

- None at design time. Implementation may surface formatting or wording choices that should be settled by the writing-plans step.
