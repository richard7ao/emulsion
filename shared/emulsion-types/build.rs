fn main() {
    #[cfg(feature = "ffi-bindings")]
    uniffi::generate_scaffolding("src/emulsion_types.udl").unwrap();
}
