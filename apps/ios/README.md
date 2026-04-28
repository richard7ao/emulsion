# iOS App

SwiftUI portfolio app targeting iOS 26. MVVM architecture with @Observable ViewModels.

## Build

```bash
xcodebuild -project PortfolioApp.xcodeproj -scheme PortfolioApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Run

Start the backend first (`cargo run -p portfolio-api`), then run in Xcode (Cmd+R).
