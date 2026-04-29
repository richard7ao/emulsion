load("@rules_rust//rust:defs.bzl", "rust_library", "rust_test")

# Bazel build does not enable the `ffi-bindings` feature, so the UniFFI
# scaffolding macro and build.rs are skipped. Cargo enables ffi-bindings by
# default and runs the full UniFFI codegen path.
rust_library(
    name = "emulsion_types",
    srcs = glob(["src/**/*.rs"]),
    crate_features = [],
    deps = [
        "@crates//:serde",
    ],
    edition = "2021",
    visibility = ["//visibility:public"],
)

rust_test(
    name = "emulsion_types_test",
    crate = ":emulsion_types",
    deps = [
        "@crates//:serde_json",
    ],
    edition = "2021",
)
