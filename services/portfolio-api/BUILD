load("@rules_rust//rust:defs.bzl", "rust_binary", "rust_test")

rust_binary(
    name = "server",
    srcs = glob(["src/**/*.rs"]),
    compile_data = glob(["migrations/**"]),
    deps = [
        "//shared/emulsion-types:emulsion_types",
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

rust_test(
    name = "server_test",
    crate = ":server",
    deps = [
        "@crates//:tower",
        "@crates//:http-body-util",
    ],
    edition = "2021",
)
