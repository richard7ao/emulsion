# Setup Guide
#
# WHAT THIS IS: Step-by-step guide to get the project running from scratch on a new machine.
# Covers all prerequisites, toolchain installation, database setup, and running the full stack.
#
# HOW TO USE: Follow sections in order. Each section ends with a verification command.
# If a verification fails, fix it before moving on — later steps depend on earlier ones.
# Expected time on a clean Mac: ~45 minutes (Xcode download dominates).

---

## 1. System Requirements

- **macOS**: Ventura 13+ or Sequoia (developed on Darwin 25.0.0 / Sequoia)
- **RAM**: 16 GB recommended (iOS Simulator + Rust compilation is memory-heavy)
- **Disk**: 40 GB free (Xcode ~15 GB, Simulator runtimes ~10 GB, build artefacts ~5 GB)
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel — both work

---

## 2. Xcode

Install from the Mac App Store or [developer.apple.com/downloads](https://developer.apple.com/downloads).
Required version: **Xcode 16.x or later** (iOS 26 SDK required by the app target).

After installation:

```bash
# Accept Xcode licence
sudo xcodebuild -license accept

# Install CLI tools
xcode-select --install

# Verify
xcodebuild -version
# Expected: Xcode 16.x or 26.x
```

**Create the iPhone 16 simulator** (required by all iOS verify commands):

```bash
# List available runtimes
xcrun simctl list runtimes

# Create simulator — use the iOS 17 or 18 runtime from the list above
xcrun simctl create "iPhone 16" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16 \
  com.apple.CoreSimulator.SimRuntime.iOS-17-0
# If iOS-17-0 is not available, use the highest iOS runtime listed

# Verify
xcrun simctl list devices | grep "iPhone 16"
# Expected: iPhone 16 (some-uuid) (Shutdown)
```

---

## 3. Rust

Install via rustup (do not use Homebrew Rust — version management matters):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Choose option 1 (default installation)
source "$HOME/.cargo/env"

# Install stable toolchain
rustup toolchain install stable
rustup default stable

# Verify
rustc --version
cargo --version
# Expected: rustc 1.95+ / cargo 1.95+
```

Install sqlx CLI (needed for migrations and offline query preparation):

```bash
cargo install sqlx-cli --no-default-features --features sqlite
sqlx --version
# Expected: sqlx-cli 0.8+
```

---

## 4. Bazel

Install via Bazelisk (version manager for Bazel — reads `.bazelversion` from repo):

```bash
# Via Homebrew
brew install bazelisk

# Bazelisk is invoked as 'bazel' — it reads .bazelversion and downloads the right version
bazel version
# Expected: Bazel 9.1.0 (or whatever .bazelversion pins)
```

If Homebrew is not installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## 5. SQLite

SQLite is pre-installed on macOS. Verify:

```bash
sqlite3 --version
# Expected: 3.x
```

---

## 6. Clone the Repository

```bash
git clone https://github.com/richard7ao/emulsion.git
cd emulsion

# Verify the structure
ls
# Expected: CLAUDE.md  AGENTS.md  prd.md  apps/  services/  tools/  docs/  tasks/  shared/
```

---

## 7. Fill in CV Content (required before database setup)

The seed binary reads real CV content from `tools/seed/data/cv_template.json`.
A new session cannot seed meaningful data without it.

```bash
# Open the template and replace all placeholder values with real content
# See prd.md §6 for the data model and §4 for expected content scope
open tools/seed/data/cv_template.json
```

Required fields to fill:
- Portfolio bio and summary (hero section text)
- 3+ experience entries with company, role, dates, bullets
- PharmaBridge and MARL dissertation writeups
- Skills by category
- 6 canned Q&A pairs (at minimum the ones in the template)
- 3 seeded conversations with 2-3 messages each

After filling, copy to the active seed file:

```bash
cp tools/seed/data/cv_template.json tools/seed/data/cv.json
```

---

## 8. Build the Rust Backend

```bash
cd services/portfolio-api

# Check the environment file
cp ../.env.example .env 2>/dev/null || echo "DATABASE_URL=sqlite:./dev.db" > .env

# Build (uses offline sqlx — no live DB required for build)
SQLX_OFFLINE=true cargo build

# Verify
echo $?
# Expected: 0
```

---

## 9. Database Setup

```bash
# From services/portfolio-api/
DATABASE_URL=sqlite:./dev.db sqlx migrate run

# Verify all 8 tables created
sqlite3 dev.db ".tables"
# Expected: conversations  experiences  messages  notes  portfolios  projects  qa_pairs  skills
```

---

## 10. Seed the Database

```bash
# From repo root
cd tools/seed
DATABASE_URL=sqlite:../services/portfolio-api/dev.db cargo run

# Verify row counts
sqlite3 ../services/portfolio-api/dev.db \
  "SELECT 'portfolios', COUNT(*) FROM portfolios
   UNION SELECT 'experiences', COUNT(*) FROM experiences
   UNION SELECT 'projects', COUNT(*) FROM projects
   UNION SELECT 'qa_pairs', COUNT(*) FROM qa_pairs
   UNION SELECT 'conversations', COUNT(*) FROM conversations;"
# Expected: at least 1, 3, 2, 6, 3 rows respectively
```

---

## 11. Run the Backend Server

```bash
# From services/portfolio-api/
DATABASE_URL=sqlite:./dev.db cargo run

# In a second terminal, verify it's up
curl -s http://localhost:8080/health
# Expected: {"status":"ok"}

curl -s http://localhost:8080/v1/portfolios/1 | head -c 200
# Expected: JSON with Richard's bio and name
```

The server runs on `localhost:8080`. Keep it running for iOS integration.

---

## 12. iOS App Setup

```bash
# From repo root — check the Xcode project exists (created in T5.1)
ls apps/ios/PortfolioApp.xcodeproj
# If this directory doesn't exist yet, task T5.1 hasn't been completed.
# Start the autonomous agent (see Section 13) to build up to T5.1 first.
```

If the project exists:

```bash
# Build for simulator
xcodebuild \
  -project apps/ios/PortfolioApp.xcodeproj \
  -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -allowProvisioningUpdates \
  build 2>&1 | tail -5
# Expected: BUILD SUCCEEDED

# Run in simulator (server must be running in another terminal)
open apps/ios/PortfolioApp.xcodeproj
# Then press Cmd+R in Xcode, or use xcrun simctl launch
```

---

## 13. Running the Autonomous Build Agent

If tasks are not yet complete (check `tasks/state.json`):

```bash
# Check current build progress
cat tasks/state.json | python3 -m json.tool | grep -E '"status"|"current_task"'
```

Start a Claude Code session in the repo root. The agent reads `CLAUDE.md` automatically
and resumes from the current task in `state.json`. No additional instructions needed.

```bash
# From repo root
claude
```

The agent will:
1. Read `.claude/memory.md` (project context, gotchas)
2. Read `tasks/state.json` (find current task)
3. Implement the task
4. Run three-tier verification (build → unit → integration)
5. Commit progress and continue

Sessions can be interrupted at any time. The next session resumes from the last completed task.
If a session fails, a post-mortem is written to `tasks/state.json` and the next session
diagnoses it before retrying.

---

## 14. Troubleshooting

**`cargo build` fails with "offline" sqlx error:**
```bash
# Run with a live DB to regenerate offline metadata
DATABASE_URL=sqlite:./dev.db cargo sqlx prepare
# Then commit the .sqlx/ directory
```

**`bazel build` fails with Xcode not found:**
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**`xcrun simctl` can't find `iPhone 16`:**
```bash
# List available device types and pick closest match
xcrun simctl list devicetypes | grep iPhone
# Re-run the simctl create command from Section 2 with the correct type identifier
```

**Port 8080 already in use:**
```bash
lsof -ti:8080 | xargs kill -9
# The port is hardcoded — do not change it without updating CLAUDE.md, verify commands, and APIClient
```

**`sqlx migrate run` fails with "no such table: _sqlx_migrations":**
```bash
# This is normal on a fresh DB — sqlx creates the table automatically
# If it persists, delete dev.db and rerun: rm dev.db && sqlx migrate run
```

---

## 15. Project Reference

| What | Where |
|------|-------|
| Product requirements | `prd.md` |
| Task execution spec | `docs/superpowers/specs/2026-04-28-portfolio-design.md` |
| Agent operating manual | `CLAUDE.md` |
| Build progress | `tasks/state.json` |
| Session knowledge | `.claude/memory.md` |
| CV seed data | `tools/seed/data/cv.json` (copy from cv_template.json) |
| API base URL | `http://localhost:8080` |
| iOS bundle ID | `com.lapse.portfolio` |
| iOS simulator | `iPhone 16` |
