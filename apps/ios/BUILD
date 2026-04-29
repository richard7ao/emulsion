load("@rules_apple//apple:ios.bzl", "ios_application")
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PortfolioAppLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "PortfolioApp",
    # Standalone build targets host (macOS) where iOS-only APIs are
    # unavailable. Library is reachable transitively through :app, which
    # transitions to the iOS Simulator platform.
    tags = ["manual"],
)

ios_application(
    name = "app",
    bundle_id = "com.lapse.portfolio",
    families = ["iphone"],
    infoplists = [":Info.plist"],
    minimum_os_version = "26.0",
    visibility = ["//visibility:public"],
    deps = [":PortfolioAppLib"],
)
