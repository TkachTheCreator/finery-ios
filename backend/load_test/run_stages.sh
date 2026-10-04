#!/usr/bin/env bash
# Finery Load Test — staged run
# Usage: bash run_stages.sh
# Runs 10 → 50 → 100 → 250 → 500 VU stages.
# Stops if real error rate (non-429) exceeds 5% at any stage.

set -euo pipefail

BASE_URL="http://localhost:8000"
DURATION="90s"
RAMP_RATE=10   # VUs/sec during spawn
STAGES=(10 50 100 250 500)

REPORT_DIR="./reports"
mkdir -p "$REPORT_DIR"

log() { echo "[$(date '+%T')] $*"; }

# ── Prerequisite checks ────────────────────────────────────────────────────
if ! command -v locust &>/dev/null; then
    echo "ERROR: locust not found. Run: pip install locust"
    exit 1
fi
if [[ ! -f test_users.json ]]; then
    echo "ERROR: test_users.json not found. Run setup_users.py first."
    exit 1
fi

# ── Server specs snapshot ──────────────────────────────────────────────────
log "=== SERVER SPECS ==="
echo "CPUs: $(nproc)"
free -h
df -h /
echo ""

log "=== DOCKER STATUS ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "(docker ps failed)"
echo ""

log "=== POSTGRES CONNECTION POOL ==="
# pool_size=10, max_overflow=20 → hard cap 30 connections
DB_CONTAINER=$(docker ps --filter "name=db" --format "{{.Names}}" | head -1)
if [[ -n "$DB_CONTAINER" ]]; then
    docker exec "$DB_CONTAINER" psql -U finery -d finery -c \
        "SELECT state, count(*) FROM pg_stat_activity WHERE datname='finery' GROUP BY state ORDER BY state;" \
        2>/dev/null || echo "(pg_stat_activity query failed)"
fi
echo ""

# ── Stage loop ─────────────────────────────────────────────────────────────
for VUS in "${STAGES[@]}"; do
    log "=========================================="
    log "STAGE: $VUS virtual users"
    log "=========================================="

    # CPU/RAM before stage
    log "Docker stats BEFORE $VUS VU:"
    docker stats --no-stream --format \
        "  {{.Name}}: CPU={{.CPUPerc}} MEM={{.MemUsage}}" 2>/dev/null || true

    REPORT_FILE="$REPORT_DIR/report_${VUS}vu.html"
    CSV_PREFIX="$REPORT_DIR/results_${VUS}vu"

    locust -f locustfile.py \
        --host "$BASE_URL" \
        --headless \
        -u "$VUS" \
        -r "$RAMP_RATE" \
        --run-time "$DURATION" \
        --html "$REPORT_FILE" \
        --csv "$CSV_PREFIX" \
        2>&1 | tee "$REPORT_DIR/locust_${VUS}vu.log"

    # CPU/RAM after stage
    log "Docker stats AFTER $VUS VU:"
    docker stats --no-stream --format \
        "  {{.Name}}: CPU={{.CPUPerc}} MEM={{.MemUsage}}" 2>/dev/null || true

    # Check PG connections after stage
    if [[ -n "${DB_CONTAINER:-}" ]]; then
        log "PostgreSQL connections after $VUS VU:"
        docker exec "$DB_CONTAINER" psql -U finery -d finery -c \
            "SELECT state, count(*) FROM pg_stat_activity WHERE datname='finery' GROUP BY state ORDER BY state;" \
            2>/dev/null || true
    fi

    # Parse failure rate from CSV stats file
    STATS_CSV="${CSV_PREFIX}_stats.csv"
    if [[ -f "$STATS_CSV" ]]; then
        FAIL_RATE=$(python3 -c "
import csv, sys
with open('$STATS_CSV') as f:
    rows = list(csv.DictReader(f))
total_row = next((r for r in rows if r.get('Name') == 'Aggregated'), None)
if total_row:
    req = int(total_row.get('Request Count', 0) or 0)
    fail = int(total_row.get('Failure Count', 0) or 0)
    # Don't count 429s (tracked as failures in locust but named 'rate_limit')
    rate_limited = sum(
        int(r.get('Failure Count', 0) or 0)
        for r in rows if '429_rate_limit' in r.get('Name', '')
    )
    real_fail = fail - rate_limited
    pct = (real_fail / req * 100) if req > 0 else 0
    print(f'{pct:.1f}')
else:
    print('0')
" 2>/dev/null || echo "0")

        log "Real error rate at $VUS VU: ${FAIL_RATE}%"

        if python3 -c "import sys; sys.exit(0 if float('${FAIL_RATE}') > 5 else 1)" 2>/dev/null; then
            log "⚠️  ERROR RATE >5% at $VUS VU — STOPPING."
            log "Review $REPORT_FILE before escalating to higher load."
            break
        fi
    fi

    log "✓ Stage $VUS VU done. Waiting 30s before next stage..."
    sleep 30
done

log "=== ALL STAGES COMPLETE ==="
log "Reports in $REPORT_DIR/"
log ""
log "To clean up test data:"
log "  docker exec \$DB_CONTAINER psql -U finery -d finery -c \\"
log "    \"DELETE FROM users WHERE email LIKE 'loadtest_%@finery-test.local';\""
