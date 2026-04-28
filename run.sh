#!/bin/bash
#
# Emulsion Portfolio App — macOS Setup & Run
# Requires: Rust (cargo), Xcode (for iOS Simulator)
#
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
DB_PATH="$ROOT/services/portfolio-api/dev.db"
export DATABASE_URL="sqlite:$DB_PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}→ $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
fail() { echo -e "${RED}  ✗ $1${NC}"; exit 1; }

echo -e "${BOLD}Emulsion Portfolio App${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━"

# --- Prerequisites ---
step "Checking prerequisites"
command -v cargo >/dev/null 2>&1 || fail "Rust not installed — https://rustup.rs"
command -v xcodebuild >/dev/null 2>&1 || fail "Xcode not installed — install from the App Store"
ok "Rust $(rustc --version | awk '{print $2}')"
ok "Xcode $(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')"

# --- Database ---
step "Setting up database"
if [ ! -f "$DB_PATH" ]; then
    cd "$ROOT/services/portfolio-api"
    cargo sqlx database create 2>/dev/null || true
    cargo sqlx migrate run
    cd "$ROOT"
    cargo run -p seed
    ok "Database created and seeded"
else
    ok "Database already exists (delete $DB_PATH to re-seed)"
fi

# --- Build ---
step "Building Rust backend"
cargo build -p portfolio-api
ok "Backend compiled"

step "Building iOS app"
xcodebuild build \
    -project "$ROOT/apps/ios/PortfolioApp.xcodeproj" \
    -scheme PortfolioApp \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    CODE_SIGNING_ALLOWED=NO -quiet
ok "iOS app compiled"

# --- Run ---
step "Starting backend server"
cargo run -p portfolio-api &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null" EXIT

sleep 2
if curl -s http://localhost:8080/health | grep -q '"ok"'; then
    ok "Server running on http://localhost:8080"
else
    fail "Server failed to start"
fi

echo ""
echo -e "${BOLD}Ready!${NC}"
echo ""
echo "  API:      http://localhost:8080"
echo "  Health:   http://localhost:8080/health"
echo "  iOS app:  Open apps/ios/PortfolioApp.xcodeproj in Xcode → Cmd+R"
echo ""
echo "Press Ctrl+C to stop the server."
wait $SERVER_PID
