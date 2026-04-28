load("@rules_rust//rust:defs.bzl", "rust_library")

# NOTE: UniFFI 0.28's transitive dep `uniffi_testing` uses env!("CARGO") which
# is unavailable in Bazel's sandbox. This target builds via `cargo build -p emulsion-types`.
# Bazel target is defined for completeness but requires a crate_universe patch to resolve.
rust_library(
    name = "emulsion_types",
    srcs = glob(["src/**/*.rs"]),
    compile_data = glob(["src/**/*.udl"]),
    deps = [
        "@crates//:uniffi",
        "@crates//:serde",
    ],
    edition = "2021",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)
