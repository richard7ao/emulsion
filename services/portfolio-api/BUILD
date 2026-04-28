load("@rules_rust//rust:defs.bzl", "rust_binary")

rust_binary(
    name = "server",
    srcs = glob(["src/**/*.rs"]),
    deps = [
        "@crates//:axum",
        "@crates//:tokio",
        "@crates//:sqlx",
        "@crates//:serde",
        "@crates//:serde_json",
        "@crates//:dashmap",
        "@crates//:tower-http",
        "@crates//:tracing",
        "@crates//:tracing-subscriber",
        "@crates//:anyhow",
    ],
    edition = "2021",
    visibility = ["//visibility:public"],
)
