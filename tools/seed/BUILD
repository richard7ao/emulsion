load("@rules_rust//rust:defs.bzl", "rust_binary")

# This binary uses compile-time path macros (`sqlx::migrate!` with a path
# relative to the workspace, and `include_str!("../data/cv.json")`) that
# cannot resolve in Bazel's sandbox. The seed tool is intentionally
# Cargo-only — run `cargo run -p seed`. Tagged manual so `bazel build/test
# //...` skips it.
rust_binary(
    name = "seed",
    srcs = glob(["src/**/*.rs"]),
    data = glob(["data/**"]),
    deps = [
        "@crates//:sqlx",
        "@crates//:tokio",
        "@crates//:serde",
        "@crates//:serde_json",
        "@crates//:anyhow",
    ],
    edition = "2021",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)
