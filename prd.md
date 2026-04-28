PRD: Portfolio iOS App + Rust Backend
Submission for Lapse — 24h Take-Home
Author: Richard Lao
Status: Draft v1

1. Purpose
   A native iOS portfolio app for Richard Lao, backed by a Rust service, built in a Bazel monorepo. The app is the deliverable; the engineering choices (monorepo layout, Rust backend, Bazel build, agent-friendly structure) are what's being evaluated. Content is real — sourced from Richard's CV — so the app is a usable artifact post-interview, not throwaway.
2. Goals & Non-Goals
   Goals

Demonstrate a working end-to-end system (iOS ↔ Rust) over local network.
Show a monorepo structure that scales to additional clients (Android) and shared code.
Use Bazel meaningfully across iOS, Rust, and shared targets.
Make the codebase legible to AI coding agents (clear conventions, READMEs per package, predictable layout).
Deliver a visual identity (polaroid/film aesthetic) that signals attention to craft without being a costume.
Be honest in documentation about what is real vs. scaffolded.

Non-Goals

Multi-user auth, accounts, or production deploy.
Real-time chat (theatre only).
GitHub or any external API integration (designed-for, not implemented).
Push notifications.
Android client (architecture should permit it; not building it).
Photo capture or upload from device.

3. Users

Primary: Lapse engineering interviewers reviewing the submission and conducting the crit.
Secondary (notional, for product framing): recruiters and hiring managers viewing Richard's portfolio.
Implicit: AI coding agents navigating the repo to extend it.

4. Core User Flows

Browse portfolio — Open app → land on Richard's portfolio (pager-wrapped, swipe gesture wired but only one portfolio exists). See bio, experience, projects, skills as scrollable polaroid-style cards.
View project detail — Tap a project card → detail view with writeup, "interested" tap, view counter increments on open.
Ask Richard — Tap "Ask" → list of canned tappable prompts → tap one, see the answer. Optional free-text field → backend fuzzy-matches to nearest canned answer or falls back to "leave a note."
Leave a note — Tap "Get in touch" → form (name, email, message) → submit → confirmation. Note persists in backend.
Inbox (theatre) — Visible UI showing seeded conversations. Tappable, scrollable, but send-path is stubbed. Documented as scaffolded.

5. Screens (iOS)

Root pager — Horizontal pager, single page = Richard's portfolio. Swipe right reveals an empty "next portfolio" placeholder card to demonstrate the extension point.
Portfolio home — Hero section (photo, name, one-liner from CV summary). Scrollable sections: About, Experience, Projects, Skills. Polaroid-card visual treatment.
Project detail — Modal or push. Title, role, writeup, "interested" tap with count, view counter (incremented server-side on open).
Ask Richard — List of canned prompts + optional free-text input + answer display.
Leave a note — Form view.
Inbox (theatre) — List of seeded conversations, tap into a conversation thread, send box visible but disabled or no-op.

6. Data Model (SQLite, owned by backend)

portfolios — id, name, bio, photo_path, summary, created_at
experiences — id, portfolio_id, company, role, dates, bullets (JSON)
projects — id, portfolio_id, title, role, writeup, screenshots (JSON), view_count, interested_count
skills — id, portfolio_id, category, items (JSON)
qa_pairs — id, portfolio_id, prompt, answer, is_canned (bool)
notes — id, portfolio_id, name, email, message, created_at
conversations (theatre, seeded only) — id, portfolio_id, participant_name, last_message, updated_at
messages (theatre, seeded only) — id, conversation_id, sender, body, created_at

Schema includes fields (e.g. portfolio_id on everything) that are unused for MVP single-portfolio but enable multi-portfolio extension. 7. API Surface
All under /v1. JSON over HTTP, served locally.

GET /portfolios/:id — full portfolio (bio, experience, skills) — single fan-out read
GET /portfolios/:id/projects — projects list
GET /portfolios/:id/projects/:pid — project detail; side-effect: increment view_count
POST /portfolios/:id/projects/:pid/interested — increment interested_count
GET /portfolios/:id/qa — canned Q&A list
POST /portfolios/:id/qa/ask — free-text body, returns best fuzzy match or null
POST /portfolios/:id/notes — submit note
GET /portfolios/:id/notes — owner inbox (header-based auth stub: X-Owner-Token)
GET /portfolios/:id/conversations — theatre, returns seeded data
GET /portfolios/:id/conversations/:cid/messages — theatre, seeded data

8. Performance / Backend Design

Async everything via tokio + axum.
In-memory read cache (Arc<RwLock<HashMap>> or dashmap) for portfolio, projects, qa_pairs. Cache invalidated on writes. Writes go to SQLite via sqlx.
Fan-out reads (GET /portfolios/:id) parallelised with tokio::join! even though SQLite is single-threaded — demonstrates the pattern.
Connection pooling via sqlx::Pool.
Counter writes (view, interested) are atomic SQL UPDATE ... SET col = col + 1.
Image serving — static file handler for portfolio photo and project screenshots, served from local filesystem.
No auth except header stub for inbox endpoint.

The system design doc will explicitly call out what's implemented vs. what's "considered but not built" (request coalescing, stale-while-revalidate, etc.). 9. iOS Architecture

SwiftUI, target iOS 17+.
MVVM-lite: View ↔ ViewModel (ObservableObject) ↔ APIClient (async/await).
One APIClient with typed request/response models matching backend JSON.
AppState for global pager state and theme.
Theming: a single LapseTheme struct holding colors, typography, spacing — referenced everywhere instead of hardcoded values.
Image loading: simple async URL → Image component, no third-party libs.

10. Visual Direction
    Polaroid/film aesthetic — warm off-white background (think 250/245/235), grain overlay (subtle SVG noise or blend mode), editorial serif for headers (e.g. New York or a system serif), monospace for metadata (dates, counts). Project cards have slight rotation (±2°) like photos in an album. Pager swipe between portfolios = flipping pages. Restrained — the engineering is the substance, the aesthetic is the wrapper.
11. Repo Layout (Bazel monorepo)
    /
    ├── README.md
    ├── docs/
    │ ├── system-design.md
    │ ├── test-plan.md
    │ └── retrospective.md
    ├── WORKSPACE / MODULE.bazel
    ├── apps/
    │ └── ios/ # SwiftUI app, Bazel-built via rules_apple
    ├── services/
    │ └── portfolio-api/ # Rust axum service
    ├── shared/
    │ └── schemas/ # JSON schemas / shared types (extension point)
    ├── tools/
    │ └── seed/ # Rust binary: seed SQLite from Richard's CV content
    └── AGENTS.md # Conventions for AI agents working in this repo
12. Agent-Optimised Codebase

AGENTS.md at root: directory map, conventions, "where to add X" patterns.
Each top-level package has its own README.md with purpose, build command, test command.
Consistent naming (*\_handler.rs, *View.swift, \*ViewModel.swift).
Bazel targets named predictably (//services/portfolio-api:server, //apps/ios:app).
Seed data and content separated from code (tools/seed/data/).
Comments at module headers explain the why, not the what.

13. Scope Cuts (explicit)
    Listed in the retrospective so reviewers see what was deliberately left out:

Bidirectional chat (theatre only)
GitHub integration
Auth beyond header stub
Multi-portfolio (schema supports, UI scaffolded only)
Android client (architecture supports)
Real photo upload
Tests beyond a thin layer per side (will define scope in test plan)

14. Risks

Bazel + iOS is the highest-risk piece. rules_apple is workable but fiddly. Mitigation: timebox to ~3h; if blocked, document and fall back to Xcode build with Bazel still owning Rust + shared targets.
Polaroid aesthetic can read as kitsch if executed badly. Mitigation: restraint — one rotation, one grain texture, one accent color. If it looks costume-y, strip back to clean editorial.
Theatre chat could confuse reviewers if not flagged. Mitigation: visible "demo" badge in UI + explicit retro note.

15. Open Questions

Do you want a dark mode? (I'd say no for MVP — polaroid is a light aesthetic.)
Is there a photo of you available for the hero section, or do we use a placeholder?
Are there screenshots for PharmaBridge / MARL dissertation, or text-only project cards?
