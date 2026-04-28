#!/bin/bash
#
# Generate Swift bindings and xcframework from the shared Rust types.
# Run from the repo root.
#
set -e

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

echo "Building for iOS Simulator (aarch64)..."
cargo build -p emulsion-types --target aarch64-apple-ios-sim --release

echo "Generating Swift bindings..."
cargo run -p emulsion-types --features bindgen --bin uniffi_bindgen -- \
    generate \
    --library target/aarch64-apple-ios-sim/release/libemulsion_types.a \
    --language swift \
    --out-dir shared/emulsion-types/generated

echo "Creating xcframework..."
rm -rf shared/emulsion-types/EmulsionTypes.xcframework
mkdir -p /tmp/emulsion-xcf/headers
cp shared/emulsion-types/generated/emulsion_typesFFI.h /tmp/emulsion-xcf/headers/
cp shared/emulsion-types/generated/emulsion_typesFFI.modulemap /tmp/emulsion-xcf/headers/module.modulemap

xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios-sim/release/libemulsion_types.a \
    -headers /tmp/emulsion-xcf/headers \
    -output shared/emulsion-types/EmulsionTypes.xcframework

rm -rf /tmp/emulsion-xcf

echo "Done. Generated files:"
echo "  shared/emulsion-types/generated/emulsion_types.swift"
echo "  shared/emulsion-types/generated/emulsion_typesFFI.h"
echo "  shared/emulsion-types/EmulsionTypes.xcframework/"
