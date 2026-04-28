<div align="center">

# emulsion

*The light-sensitive layer where an image takes permanent form.*

[![Rust](https://img.shields.io/badge/Rust-1.95-orange?logo=rust&logoColor=white)](https://www.rust-lang.org)
[![Swift](https://img.shields.io/badge/Swift-6-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Bazel](https://img.shields.io/badge/Bazel-7-43A047?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTV6TTIgMTdsOCA0IDgtNFY3bC04IDQtOC00eiIvPjwvc3ZnPg==&logoColor=white)](https://bazel.build)

</div>

---

## TLDR

Richard Lao's personal portfolio as a working end-to-end system. A native iOS app with a polaroid/film aesthetic, talking to a Rust backend over local HTTP. The engineering choices — Bazel monorepo, async Rust, agent-friendly structure — are the substance. The visual identity is the wrapper.

---

## Stack

| | Technology |
|---|---|
| **iOS** | SwiftUI · iOS 17+ · MVVM · no third-party deps |
| **Backend** | Rust · Axum · SQLite via sqlx · in-memory read cache |
| **Build** | Bazel 7 (Bzlmod) · rules_apple · rules_rust |
| **Aesthetic** | Polaroid/film — warm off-whites, grain, editorial serif |

---

## Structure

```
emulsion/
├── apps/
│   └── ios/                 SwiftUI app
├── services/
│   └── portfolio-api/       Rust · Axum · SQLite
├── tools/
│   └── seed/                Seeds SQLite from CV content
├── shared/
│   └── schemas/             Shared type definitions (extension point)
└── prd.md                   Full product spec
```

---

## Run

```bash
# 1. Seed the database
cargo run -p seed

# 2. Start the API
cargo run -p portfolio-api

# 3. Open the iOS app
open apps/ios/Emulsion.xcodeproj
```

---

## About

Built as a 24-hour take-home. Content is real — sourced from Richard's CV — so the app is a usable artifact after the fact, not throwaway code.

> See [`prd.md`](prd.md) for the full product spec.
