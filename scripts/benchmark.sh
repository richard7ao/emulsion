#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:8080}"

echo "=== Emulsion API Benchmark ==="
echo "Target: $BASE"
echo ""

if ! curl -sf "$BASE/health" > /dev/null 2>&1; then
    echo "ERROR: Server not reachable at $BASE"
    exit 1
fi

run_bench() {
    local label="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="${4:-}"
    local times=()

    for i in $(seq 1 50); do
        if [ "$method" = "POST" ]; then
            ms=$(curl -sf -X POST -H "Content-Type: application/json" -d "$data" \
                -o /dev/null -w "%{time_total}" "$url")
        else
            ms=$(curl -sf -o /dev/null -w "%{time_total}" "$url")
        fi
        times+=("$ms")
    done

    sorted=($(printf '%s\n' "${times[@]}" | sort -n))
    p50="${sorted[24]}"
    p95="${sorted[47]}"
    max="${sorted[49]}"
    printf "%-40s p50=%ss  p95=%ss  max=%ss\n" "$label" "$p50" "$p95" "$max"
}

echo "Running 50 requests per endpoint..."
echo ""

run_bench "GET /health"                    "$BASE/health"
run_bench "GET /v1/portfolios/1 (1st)"     "$BASE/v1/portfolios/1"
run_bench "GET /v1/portfolios/1 (cached)"  "$BASE/v1/portfolios/1"
run_bench "GET /v1/portfolios/1/projects"  "$BASE/v1/portfolios/1/projects"
run_bench "GET /v1/projects/1"             "$BASE/v1/projects/1"
run_bench "GET /v1/portfolios/1/qa"        "$BASE/v1/portfolios/1/qa"
run_bench "POST /v1/portfolios/1/qa/ask"   "$BASE/v1/portfolios/1/qa/ask" POST '{"query":"Rust"}'
run_bench "POST /v1/portfolios/1/view"     "$BASE/v1/portfolios/1/view" POST '{}'

echo ""
echo "Done. Cache-hit reads should be < 5ms. DB reads < 10ms."
