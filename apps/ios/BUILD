load("@rules_apple//apple:ios.bzl", "ios_application")
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PortfolioAppLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "PortfolioApp",
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
