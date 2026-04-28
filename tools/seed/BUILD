load("@rules_rust//rust:defs.bzl", "rust_binary")

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
    visibility = ["//visibility:public"],
)
