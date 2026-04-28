# Global CLAUDE.md Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `/Users/richardlao/.claude/CLAUDE.md` with a redesigned, more prescriptive operating manual per the design spec at `docs/superpowers/specs/2026-04-29-global-claude-md-redesign.md`.

**Architecture:** Single-file rewrite. Back up the existing global file as a safety net, then write the new content using the Write tool, then verify structurally with grep/jq. The target file lives outside any git repo (`~/.claude/`), so no git commits are involved in the file change itself — verification is done via shell assertions.

**Tech Stack:** Markdown (the file), Bash (backup + verification), Python 3 (JSON validation in the verify step), Claude Code `Read`/`Write` tools.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `/Users/richardlao/.claude/CLAUDE.md` | Modify (full rewrite) | New global operating manual |
| `/Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29` | Create | Safety-net backup of pre-rewrite content |
| `docs/superpowers/specs/2026-04-29-global-claude-md-redesign.md` | Read-only | Authoritative source for new content (already committed in `fd0af1c`) |

---

## Task 1: Backup the current global CLAUDE.md

**Files:**
- Read: `/Users/richardlao/.claude/CLAUDE.md`
- Create: `/Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29`

- [ ] **Step 1: Confirm the current global file exists and capture its size**

Run:
```bash
ls -l /Users/richardlao/.claude/CLAUDE.md && wc -l /Users/richardlao/.claude/CLAUDE.md
```

Expected: file listed, ~132 lines (confirmation that we are about to back up the right thing).

- [ ] **Step 2: Copy the current global to a dated backup**

Run:
```bash
cp /Users/richardlao/.claude/CLAUDE.md /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29
```

Expected: no output, exit 0.

- [ ] **Step 3: Verify the backup matches the original byte-for-byte**

Run:
```bash
diff /Users/richardlao/.claude/CLAUDE.md /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29 && echo "BACKUP OK"
```

Expected output: `BACKUP OK` (diff produces no output and exits 0).

If the diff shows differences or the command fails, STOP — investigate before proceeding.

---

## Task 2: Write the new global CLAUDE.md

**Files:**
- Modify (full rewrite): `/Users/richardlao/.claude/CLAUDE.md`

- [ ] **Step 1: Re-read the design spec for fidelity check**

Use the `Read` tool on `/Users/richardlao/Documents/Github/Personal/emulsion/docs/superpowers/specs/2026-04-29-global-claude-md-redesign.md`.

Expected: spec contains a Decisions table and Section 4 with sub-section drafts (4.1 through 4.13).

- [ ] **Step 2: Write the new global CLAUDE.md with the full content below**

Use the `Write` tool with `file_path` = `/Users/richardlao/.claude/CLAUDE.md` and `content` = the exact text inside the 5-backtick fence below (do NOT include the outer 5-backtick fence markers themselves; those are the plan's container).

`````markdown
# Global Agent Operating Manual

WHAT THIS IS: The default operating manual for every Claude Code session.
HOW IT IS USED: The agent reads this file at session start, then reads the project-level CLAUDE.md (if present), then runs the Session Start Protocol below.

Project-level CLAUDE.md extends and overrides this file. If the two conflict, project-level wins.

---

## 1. Session Start Protocol (MANDATORY)

Read these in order. Do not skip any. Do not write any code before completing all five steps.

1. **Internalize Memory.** Read `.claude/memory.md`. Apply Decisions, Patterns, and Gotchas before touching any code. If `.claude/memory.md` does not exist, create it with the four section headers (`## Decisions`, `## Patterns`, `## Gotchas`, `## Open Questions`) and proceed.

2. **Load State.** Read `tasks/state.json`. If it does not exist, initialize from the project spec with all statuses `pending` and `current_task`/`current_step`/`current_stage` set to the first task/step/stage.

3. **Process Post-Mortems.** Find unresolved entries (`resolved: false`) in `postmortems[]`.
   - `verification_failure` → read `output_tail`, diagnose root cause, fix before retry.
   - `context_exhaustion` → read `resumption_hint`, resume from described state.

4. **Locate Current Stage.** Open the project spec in `docs/superpowers/specs/`. Find the stage matching `current_stage`. Read its description and all four verify blocks fully before starting.

5. **Check Dependencies.** If the stage has a `Requires:` field, verify every listed task/step/stage shows `complete` in `state.json`. If any listed dependency is missing or not yet `complete`, STOP and report the blocker. If no `Requires:` field, proceed.

---

## 2. Task Execution Protocol

```
IMPLEMENT → TIER 1 (Build) → TIER 2 (Simplify) → TIER 3 (Unit) → TIER 4 (Integration)
```

**Rules:**
- Tiers run sequentially. A tier must exit 0 before the next runs.
- **Tier-skip rules:** docs-only stages skip all four; config-only stages skip Tier 2 (Simplify); Tier 4 may be skipped only when the stage has no integration surface AND the spec explicitly marks Tier 4 as skipped for that stage.
- On any tier failure: attempt fix → re-run failing tier and all previous tiers.

**3-Strike Rule:** Same tier, same root cause, three failures → write `verification_failure` post-mortem to `tasks/state.json`, commit, STOP. Do not attempt a fourth fix in the same session — the next session reads the post-mortem.

---

## 3. Task Completion Protocol

Fires when all applicable tiers pass for a stage.

1. Update `tasks/state.json`: set the stage `"status": "complete"` with `"completed_at": "<ISO8601>"`.
2. Advance `current_stage` to the next stage in the current step.
3. If the last stage of the step is now complete: set step `status: complete`, advance `current_step`.
4. If the last step of the task is now complete: set task `status: complete`, advance `current_task`.
5. Write any new discoveries to `.claude/memory.md` (see Memory File Protocol).
6. Commit in one atomic commit: `git add tasks/state.json .claude/memory.md && git commit -m "feat: complete <stage_id> — <short description>"`
7. Return to Session Start Protocol Step 4 (locate next stage).

---

## 4. Context Pressure Rule

After each stage completes, estimate remaining context window percentage. **If under 15%:**

1. Append a `context_exhaustion` post-mortem to `tasks/state.json` with `resumption_hint` describing files modified, what the next stage requires, and any in-flight state.
2. Commit `tasks/state.json` and `.claude/memory.md`.
3. STOP. Do not start the next stage in a depleted context window.

---

## 5. Memory File Protocol

`.claude/memory.md` is mandatory. Sections in this exact order:

```markdown
## Decisions
## Patterns
## Gotchas
## Open Questions
```

**Entry format** under any section: `- [YYYY-MM-DD] <one-line entry>`

**When to write:**
- **Decisions** — non-obvious architectural or tooling choice made during a stage.
- **Patterns** — new code structure established for the first time.
- **Gotchas** — something that failed or surprised; especially version constraints.
- **Open Questions** — unresolved items for next session or human review.

Writes happen during Task Completion Protocol Step 5, never mid-implementation.

---

## 6. Spec Format

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

**Rules:**
- Every Stage MUST own a complete set of four verify blocks.
- Verify commands are deterministic shell — no subjective judgment.
- IDs use dotted integers: `T<task>.<step>.<stage>`.
- Phase grouping is dropped; if visual grouping helps, use plain markdown headers above tasks (no formal Phase ID).

---

## 7. State Schema

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

**Initialization:** If missing, build the tree from the project spec with all statuses `pending`, set `current_task`/`current_step`/`current_stage` to the first task/step/stage, write the file.

---

## 8. Post-Mortem Format

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

---

## 9. Project-Specific Constraints (template — projects MUST fill in)

Every project-level `CLAUDE.md` MUST include a constraints section in this exact format:

```markdown
## Project-Specific Constraints (ABSOLUTE — no exceptions)

| Rule | Reason |
|------|--------|
| <rule> | <why> |
| <rule> | <why> |
```

These are project-level invariants the agent must never violate. Examples (from existing projects): "Never use third-party iOS libraries", "Cache invalidation on ALL writes to portfolio tables".

---

## 10. Gotchas (cross-project)

### Runtime config before migrations
Set runtime configuration (connection modes, pragmas, pool settings) at connection init time, not in migration scripts. Migrations may run before the runtime is fully configured.

### Offline build metadata
When using compile-time query checking or code generation, regenerate and commit the metadata after every schema or query change. Builds on machines without the live backing service will break silently otherwise.

### Strict concurrency and UI state
In frameworks with strict concurrency checking, ViewModels that mutate UI state must be bound to the main thread/actor. Async methods on observable objects without main-thread annotation cause data race errors.

### Deterministic visual effects
Use seeded randomness (e.g. item index) for visual effects like rotation or offset. Unseeded random values re-roll on every framework redraw cycle, causing visual jitter.

**Project-specific gotchas belong in project-level CLAUDE.md** — version-specific quirks, hardcoded values, simulator targets, and tool-specific workarounds.

---

## 11. File Reference Map

| File | Purpose | Mutability |
|------|---------|------------|
| `~/.claude/CLAUDE.md` | This file — global operating manual | Rarely (across many projects) |
| `<project>/CLAUDE.md` | Project-level extension | Rarely (per project) |
| `docs/superpowers/specs/*.md` | Task/step/stage catalog | Mutable when scope evolves |
| `docs/superpowers/plans/*.md` | Implementation plans (from writing-plans skill) | Mutable per-plan |
| `tasks/state.json` | Runtime progress + post-mortems | Every stage |
| `.claude/memory.md` | Accumulated project knowledge | When discoveries are made |

---

## 12. Project-Level Extension

Project-level `CLAUDE.md` extends this with:
- Toolchain versions (verified-on-this-machine table).
- Canonical command snippets the spec's verify blocks reuse (e.g., the project's standard `cargo build` invocation, the standard server-startup boilerplate).
- Naming conventions (file suffixes, type prefixes).
- Server lifecycle (when to start/stop long-running services for tier 4).
- Project-specific gotchas (version pins, simulator targets, environment quirks).
- Project-Specific Constraints table (mandatory; see Section 9).

If project-level CLAUDE.md and global conflict, project-level wins.
`````

- [ ] **Step 3: Read the new file back and confirm size**

Run:
```bash
wc -l /Users/richardlao/.claude/CLAUDE.md && head -3 /Users/richardlao/.claude/CLAUDE.md && tail -3 /Users/richardlao/.claude/CLAUDE.md
```

Expected:
- Line count: ~210-230 lines (significantly larger than the original ~132).
- First 3 lines start with `# Global Agent Operating Manual` then a blank line then `WHAT THIS IS:`.
- Last 3 lines end with the Project-Level Extension section's closing line: `If project-level CLAUDE.md and global conflict, project-level wins.`

If the file is empty, much shorter, or wrong content, STOP — re-run Step 2 with the exact content above.

---

## Task 3: Verify the new file structurally

**Files:**
- Read-only: `/Users/richardlao/.claude/CLAUDE.md`

- [ ] **Step 1: Confirm all 12 numbered sections are present**

Run:
```bash
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do
  grep -E "^## $n\\. " /Users/richardlao/.claude/CLAUDE.md > /dev/null \
    || { echo "MISSING SECTION $n"; exit 1; }
done && echo "ALL 12 SECTIONS PRESENT"
```

Expected output: `ALL 12 SECTIONS PRESENT`. Any other output means the file is missing one or more numbered section headers — re-run Task 2.

- [ ] **Step 2: Confirm the four verify-tier names are documented**

Run:
```bash
for tier in tier1_build tier2_simplify tier3_unit tier4_integration; do
  grep -q "$tier" /Users/richardlao/.claude/CLAUDE.md \
    || { echo "MISSING TIER NAME: $tier"; exit 1; }
done && echo "ALL 4 TIER NAMES PRESENT"
```

Expected output: `ALL 4 TIER NAMES PRESENT`.

- [ ] **Step 3: Confirm `.claude/memory.md` is mandated**

Run:
```bash
grep -q "\\.claude/memory\\.md.*mandatory\\|mandatory.*\\.claude/memory\\.md" /Users/richardlao/.claude/CLAUDE.md \
  && echo "MEMORY FILE MANDATED" \
  || { echo "MEMORY FILE MANDATE MISSING"; exit 1; }
```

Expected output: `MEMORY FILE MANDATED`.

- [ ] **Step 4: Validate JSON code blocks parse**

Run:
```bash
python3 - <<'EOF'
import json, re, sys
text = open('/Users/richardlao/.claude/CLAUDE.md').read()
blocks = re.findall(r'```json\n(.*?)\n```', text, re.DOTALL)
print(f"Found {len(blocks)} JSON blocks")
for i, b in enumerate(blocks, 1):
    cleaned = re.sub(r'<[^>]+>', 'placeholder', b)
    cleaned = cleaned.replace('"pending | in_progress | complete"', '"pending"')
    cleaned = cleaned.replace('"verification_failure | context_exhaustion"', '"verification_failure"')
    try:
        json.loads(cleaned)
        print(f"  Block {i}: OK")
    except json.JSONDecodeError as e:
        print(f"  Block {i}: FAIL — {e}")
        sys.exit(1)
print("ALL JSON BLOCKS VALID")
EOF
```

Expected output:
```
Found 2 JSON blocks
  Block 1: OK
  Block 2: OK
ALL JSON BLOCKS VALID
```

- [ ] **Step 5: Sanity check that backup is still intact**

Run:
```bash
[ -f /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29 ] \
  && wc -l /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29 \
  && echo "BACKUP STILL PRESENT"
```

Expected output: line count of backup (~132) followed by `BACKUP STILL PRESENT`.

- [ ] **Step 6: Final summary**

Print a summary of what changed:
```bash
echo "=== Global CLAUDE.md redesign complete ==="
echo "New file:    $(wc -l < /Users/richardlao/.claude/CLAUDE.md) lines"
echo "Backup file: $(wc -l < /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29) lines"
echo "Spec:        docs/superpowers/specs/2026-04-29-global-claude-md-redesign.md"
echo "Plan:        docs/superpowers/plans/2026-04-29-global-claude-md-redesign.md"
echo ""
echo "If anything looks wrong, restore with:"
echo "  cp /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29 /Users/richardlao/.claude/CLAUDE.md"
```

Expected: clean summary; counts roughly match expectations from earlier steps.

---

## Done

After Task 3 Step 6 prints cleanly, the redesign is complete. The new global operating manual is in place at `~/.claude/CLAUDE.md` and the original is preserved at `~/.claude/CLAUDE.md.backup-2026-04-29` for rollback.

**Rollback** (one-liner if Richard decides he wants the old version back):
```bash
cp /Users/richardlao/.claude/CLAUDE.md.backup-2026-04-29 /Users/richardlao/.claude/CLAUDE.md
```
