#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# OpenCode Technical Debt Analysis — benchmark harness
# ─────────────────────────────────────────────────────────────
# Produces a deterministic, offline report with a composite
# debt score (0–100, lower = less debt).
# ─────────────────────────────────────────────────────────────

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

REPORT="autoresearch-report.txt"
> "$REPORT"

# ── helpers ──────────────────────────────────────────────────
section() { printf '\n=== %s ===\n' "$1" | tee -a "$REPORT"; }
metric() { printf 'METRIC %s=%s\n' "$1" "$2" | tee -a "$REPORT"; }

count_ts()    { { find packages -name '*.ts' -not -path '*/node_modules/*' -not -path '*/.sst/*' "$@" 2>/dev/null || true; } | wc -l; }
count_lines() { find packages -name '*.ts' -not -path '*/node_modules/*' -not -path '*/.sst/*' "$@" -exec wc -l {} + 2>/dev/null | awk 'END{print $1}'; }

# ── 1. Scale ─────────────────────────────────────────────────
section "Scale"
TOTAL_SRC=$(count_ts -not -name '*.test.ts' -not -name '*.d.ts')
TOTAL_TEST=$(count_ts -name '*.test.ts')
TOTAL_LINES=$(count_lines -not -name '*.test.ts' -not -name '*.d.ts')
TEST_LINES=$(count_lines -name '*.test.ts')
TOTAL_FILES=$(find packages -name '*.ts' -not -path '*/node_modules/*' -not -path '*/.sst/*' | wc -l)

tee -a "$REPORT" <<EOF
Source files:         $TOTAL_SRC
Test files:           $TOTAL_TEST
Total .ts files:      $TOTAL_FILES
Source lines:         $TOTAL_LINES
Test lines:           $TEST_LINES
Test-to-source ratio: $(awk "BEGIN{printf \"%.2f\", $TOTAL_TEST/$TOTAL_SRC}")
EOF

# ── 2. God files (>500 LOC, non-test, non-generated) ────────
section "God files (>500 LOC, excl test/gen/i18n)"
GOD_COUNT=$(find packages -name '*.ts' -not -path '*/node_modules/*' -not -path '*/.sst/*' \
  -not -name '*.test.ts' -not -name '*.d.ts' -not -name 'types.gen.ts' \
  -not -name 'sdk.gen.ts' -not -name 'types.ts' -not -path '*/i18n/*' \
  -exec wc -l {} + 2>/dev/null | awk '$1>500{c++}END{print c+0}')

GOD_1K=$(find packages -name '*.ts' -not -path '*/node_modules/*' -not -path '*/.sst/*' \
  -not -name '*.test.ts' -not -name '*.d.ts' -not -name 'types.gen.ts' \
  -not -name 'sdk.gen.ts' -not -name 'types.ts' -not -path '*/i18n/*' \
  -exec wc -l {} + 2>/dev/null | awk '$1>1000{c++}END{print c+0}')

tee -a "$REPORT" <<EOF
Files >500 lines:   $GOD_COUNT
Files >1000 lines:  $GOD_1K
EOF

# ── 3. Type safety — any casts ──────────────────────────────
section "Type safety"
ANY_COUNT=$(grep -rn 'as any\|: any\b' --include='*.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -vc 'types.gen.ts\|sdk.gen.ts' || true)
TS_IGNORE=$(grep -rn '// @ts-ignore\|// @ts-expect-error\|// @ts-nocheck' \
  --include='*.ts' packages/ --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -vc 'types.gen.ts\|sdk.gen.ts' || true)
CATCH_ANY=$(grep -rn 'catch\s*(.*: any' --include='*.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null | wc -l)

tee -a "$REPORT" <<EOF
any casts (excl gen):      $ANY_COUNT
@ts-ignore/expect-error:   $TS_IGNORE
catch(e: any):             $CATCH_ANY
EOF

# ── 4. TODO / FIXME / HACK markers ──────────────────────────
section "Markers"
REAL_TODOS=$(grep -rn 'TODO:\|FIXME:\|HACK:\|XXX:' --include='*.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -vc 'i18n/\|prompt.example' || true)
DUAL_WRITE=$(grep -rn 'dual-write\|TODO(v2)' --include='*.ts' packages/ \
  --exclude-dir=node_modules 2>/dev/null | wc -l)
DEPRECATED=$(grep -rn '@deprecated' --include='*.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -vc 'types.gen.ts\|sdk.gen.ts' || true)

tee -a "$REPORT" <<EOF
TODO/FIXME/HACK (real):  $REAL_TODOS
Dual-write migration:    $DUAL_WRITE
@deprecated markers:     $DEPRECATED
EOF

# ── 5. Effect migration ─────────────────────────────────────
section "Effect migration"
EFFECT_FILES=$(grep -rl 'Effect\.\|yield\*' --include='*.ts' packages/opencode/src/ 2>/dev/null | wc -l)
RAW_ASYNC=$(grep -rl 'async function\|Promise<' --include='*.ts' packages/opencode/src/ 2>/dev/null \
  | grep -v -l 'Effect\.' 2>/dev/null | wc -l)

tee -a "$REPORT" <<EOF
Effect-ified files:     $EFFECT_FILES
Raw async/Promise:      $RAW_ASYNC
EOF

# ── 6. Deep nesting (>4 indent levels) ──────────────────────
section "Deep nesting"
DEEP_LINES=$(grep -rPn '^\s{16,}' --include='*.ts' packages/opencode/src/ 2>/dev/null | wc -l)
tee -a "$REPORT" <<EOF
Lines indented >4 levels: $DEEP_LINES
EOF

# ── 7. Test coverage gaps ──────────────────────────────────
section "Packages without tests"
NO_TEST_PKGS=""
NO_TEST_COUNT=0
for pkg in packages/*/; do
  name=$(basename "$pkg")
  src=$({ find "$pkg/src" -name '*.ts' -not -name '*.test.ts' -not -name '*.d.ts' 2>/dev/null || true; } | wc -l)
  tests=$({ find "$pkg" -name '*.test.ts' -not -path '*/node_modules/*' 2>/dev/null || true; } | wc -l)
  if [ "$src" -gt 0 ] && [ "$tests" -eq 0 ]; then
    NO_TEST_PKGS="$NO_TEST_PKGS  $name ($src src files)"
    NO_TEST_COUNT=$((NO_TEST_COUNT + 1))
  fi
done
[ -n "$NO_TEST_PKGS" ] && { echo "$NO_TEST_PKGS" | tee -a "$REPORT"; } || true

# ── 8. v1/v2 dual path ──────────────────────────────────────
section "v1/v2 dual architecture"
V1_SESSION=$(find packages/opencode/src/session -maxdepth 1 -name '*.ts' 2>/dev/null | wc -l)
V2_SESSION=$(find packages/opencode/src/v2 -name '*.ts' 2>/dev/null | wc -l)
tee -a "$REPORT" <<EOF
v1 session files:  $V1_SESSION
v2 session files:  $V2_SESSION
EOF

# ── 9. Console zen — any density ───────────────────────────
section "Console zen provider type safety"
ZEN_ANY=$(grep -c 'as any\|: any' packages/console/app/src/routes/zen/util/provider/anthropic.ts 2>/dev/null || echo 0)
ZEN_LINES=$(wc -l < packages/console/app/src/routes/zen/util/provider/anthropic.ts 2>/dev/null || echo 0)
tee -a "$REPORT" <<EOF
anthropic.ts: $ZEN_ANY any-uses in $ZEN_LINES lines
EOF

# ── 10. Debt score (composite, 0–100) ──────────────────────
section "Composite debt score"
# Weighted: lower is better
#   god files:     up to 20 pts
#   any casts:     up to 20 pts (per 100)
#   markers:       up to 15 pts (per 10)
#   dual-write:    up to 15 pts (per 5)
#   no-test pkgs:  up to 10 pts
#   deep nesting:  up to 10 pts (per 1000)
#   deprecated:    up to 10 pts (per 5)

GOD_PTS=$(awk "BEGIN{printf \"%.1f\", ($GOD_COUNT/96)*20}")
ANY_PTS=$(awk "BEGIN{printf \"%.1f\", ($ANY_COUNT/500)*20}")
MARKER_PTS=$(awk "BEGIN{printf \"%.1f\", ($REAL_TODOS/30)*15}")
DUAL_PTS=$(awk "BEGIN{printf \"%.1f\", ($DUAL_WRITE/15)*15}")
NOTEST_PTS=$(awk "BEGIN{printf \"%.1f\", ($NO_TEST_COUNT/5)*10}")
DEEP_PTS=$(awk "BEGIN{printf \"%.1f\", ($DEEP_LINES/4000)*10}")
DEP_PTS=$(awk "BEGIN{printf \"%.1f\", ($DEPRECATED/20)*10}")

DEBT_SCORE=$(awk "BEGIN{printf \"%.1f\", $GOD_PTS+$ANY_PTS+$MARKER_PTS+$DUAL_PTS+$NOTEST_PTS+$DEEP_PTS+$DEP_PTS}")
DEBT_SCORE_CAPPED=$(awk "BEGIN{printf \"%.1f\", ($DEBT_SCORE>100)?100:$DEBT_SCORE}")

tee -a "$REPORT" <<EOF
God files:      $GOD_PTS/20
Any casts:      $ANY_PTS/20
Markers:        $MARKER_PTS/15
Dual-write:     $DUAL_PTS/15
No-test pkgs:   $NOTEST_PTS/10
Deep nesting:   $DEEP_PTS/10
Deprecated:     $DEP_PTS/10
─────────────────────────
Total:          $DEBT_SCORE_CAPPED/100
EOF

# ── Emit primary + secondary metrics ────────────────────────
metric "debt_score" "$DEBT_SCORE_CAPPED"
metric "god_files" "$GOD_COUNT"
metric "god_files_1k" "$GOD_1K"
metric "any_casts" "$ANY_COUNT"
metric "ts_ignore" "$TS_IGNORE"
metric "todo_fixme" "$REAL_TODOS"
metric "dual_write_markers" "$DUAL_WRITE"
metric "deprecated_markers" "$DEPRECATED"
metric "deep_nesting_lines" "$DEEP_LINES"
metric "no_test_packages" "$NO_TEST_COUNT"
metric "effect_files" "$EFFECT_FILES"
metric "raw_async_files" "$RAW_ASYNC"
metric "total_src_files" "$TOTAL_SRC"
metric "total_test_files" "$TOTAL_TEST"
metric "source_lines" "$TOTAL_LINES"

echo ""
echo "Report written to $REPORT"
