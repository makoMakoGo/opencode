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
TOTAL_FILES=$({ find packages -name '*.ts' -not -path '*/node_modules/*' -not -path '*/.sst/*' 2>/dev/null || true; } | wc -l)

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
TS_IGNORE_SRC=$({ grep -rn '// @ts-ignore\|// @ts-expect-error\|// @ts-nocheck' \
  --include='*.ts' packages/ --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -v 'types.gen.ts\|sdk.gen.ts\|\.test\.ts\|\.types\.ts\|packages/llm/test' || true; } | wc -l)
CATCH_ANY=$(grep -rn 'catch\s*(.*: any' --include='*.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null | wc -l)

ANY_SRC=$({ grep -rn 'as any\|: any\b' --include='*.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -v 'types.gen.ts\|sdk.gen.ts\|\.test\.ts' || true; } | wc -l)
ANY_TEST=$({ grep -rn 'as any\|: any\b' --include='*.test.ts' packages/ \
  --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
  | grep -vc 'types.gen.ts\|sdk.gen.ts' || true; })

tee -a "$REPORT" <<EOF
any casts (excl gen):      $ANY_COUNT
  source:                  $ANY_SRC
  test:                    $ANY_TEST
@ts-ignore/expect-error:   $TS_IGNORE (source: $TS_IGNORE_SRC)
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
EFFECT_FILES=$({ grep -rl 'Effect\.\|yield\*' --include='*.ts' packages/opencode/src/ 2>/dev/null || true; } | wc -l)
EFFECT_IMPORT=$({ grep -rl '"effect"' --include='*.ts' packages/opencode/src/ 2>/dev/null || true; } | wc -l)

tee -a "$REPORT" <<EOF
Effect.gen/yield* files:  $EFFECT_FILES
Effect import files:      $EFFECT_IMPORT
EOF

# ── 6. Deep nesting (>4 indent levels) ──────────────────────
section "Deep nesting"
DEEP_LINES=$({ grep -rPn '^\s{16,}' --include='*.ts' packages/opencode/src/ 2>/dev/null || true; } | wc -l)
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
V1_SESSION=$({ find packages/opencode/src/session -maxdepth 1 -name '*.ts' 2>/dev/null || true; } | wc -l)
V2_SESSION=$({ find packages/opencode/src/v2 -name '*.ts' 2>/dev/null || true; } | wc -l)
tee -a "$REPORT" <<EOF
v1 session files:  $V1_SESSION
v2 session files:  $V2_SESSION
EOF

# ── 9. Console zen — any density ───────────────────────────
section "Console zen provider type safety"
ZEN_ANY=$(grep -c 'as any\|: any' packages/console/app/src/routes/zen/util/provider/anthropic.ts 2>/dev/null || echo 0)
ZEN_LINES=$(wc -l < packages/console/app/src/routes/zen/util/provider/anthropic.ts 2>/dev/null || echo 0)
ZEN_ANY_TOTAL=0
for f in packages/console/app/src/routes/zen/util/provider/anthropic.ts \
         packages/console/app/src/routes/zen/util/provider/openai.ts \
         packages/console/app/src/routes/zen/util/provider/openai-compatible.ts; do
  c=$(grep -c 'as any\|: any' "$f" 2>/dev/null || echo 0)
  ZEN_ANY_TOTAL=$((ZEN_ANY_TOTAL + c))
done
tee -a "$REPORT" <<EOF
anthropic.ts: $ZEN_ANY any-uses in $ZEN_LINES lines
zen provider total any: $ZEN_ANY_TOTAL
EOF

# ── 10. Coupling analysis ──────────────────────────────────
section "Coupling"
COUPLED_COUNT=$(find packages/opencode/src -maxdepth 2 -name '*.ts' -not -path '*/node_modules/*' \
  -exec grep -cP "from ['\"]@/" {} + 2>/dev/null | awk -F: '$2>15{c++}END{print c+0}')

HUB_MODULES=$({ grep -rn "from ['\"]@/" --include='*.ts' packages/opencode/src/ 2>/dev/null \
  | grep -oP "from ['\"]@/([^/']+)" || true; } \
  | sed "s/from ['\"]@\\///" | sort | uniq -c | sort -rn | head -5 | awk '{print $2":"$1}')

tee -a "$REPORT" <<EOF
Files importing >15 modules: $COUPLED_COUNT
Top fan-in modules: $HUB_MODULES
EOF

# ── 10b. Circular dependencies ───────────────────────────────
section "Circular dependencies"
CIRC_SCCS=$(python3 << 'PYEOF'
import os, re, collections
src = 'packages/opencode/src'
graph = collections.defaultdict(set)
for root, dirs, files in os.walk(src):
    dirs[:] = [d for d in dirs if d != 'node_modules']
    for f in files:
        if not f.endswith('.ts') or f.endswith('.test.ts') or f.endswith('.d.ts'):
            continue
        filepath = os.path.join(root, f)
        mod = os.path.relpath(filepath, src).replace(os.sep, '/')[:-3]
        with open(filepath) as fh:
            content = fh.read()
        for m in re.finditer(r"from ['\"](@/[^'\"]+)['\"]", content):
            graph[mod].add(m.group(1)[2:])
        for m in re.finditer(r"from ['\"](\.\./[^'\"]+)['\"]", content):
            base_dir = os.path.dirname(mod)
            resolved = os.path.normpath(base_dir + '/' + m.group(1)).replace(os.sep, '/')
            graph[mod].add(resolved)
        for m in re.finditer(r"from ['\"](\./[^'\"]+)['\"]", content):
            base_dir = os.path.dirname(mod)
            resolved = os.path.normpath(base_dir + '/' + m.group(1)).replace(os.sep, '/')
            graph[mod].add(resolved)
index_counter = [0]; stk = []; on_stk = set(); idx_map = {}; low_map = {}; result = []
def sc(v):
    idx_map[v] = index_counter[0]; low_map[v] = index_counter[0]; index_counter[0] += 1
    stk.append(v); on_stk.add(v)
    for w in graph.get(v, set()):
        if w not in idx_map: sc(w); low_map[v] = min(low_map[v], low_map[w])
        elif w in on_stk: low_map[v] = min(low_map[v], idx_map[w])
    if low_map[v] == idx_map[v]:
        comp = []
        while True:
            w = stk.pop(); on_stk.discard(w); comp.append(w)
            if w == v: break
        if len(comp) > 1: result.append(comp)
for v in sorted(graph.keys()):
    if v not in idx_map: sc(v)
big = max((len(s) for s in result), default=0)
print(f"{len(result)} {big}")
PYEOF
)
SCC_COUNT=$(echo "$CIRC_SCCS" | awk '{print $1}')
SCC_LARGEST=$(echo "$CIRC_SCCS" | awk '{print $2}')
metric scc_count $SCC_COUNT
metric scc_largest $SCC_LARGEST
tee -a "$REPORT" <<EOF
Circular dep SCCs (>1 module): $SCC_COUNT
Largest SCC:                   $SCC_LARGEST modules
EOF

# ── 11. Test quality ───────────────────────────────────────
section "Test quality"
FRAGILE_TESTS=$(find packages -name '*.test.ts' -not -path '*/node_modules/*' \
  -exec grep -c 'as any\|: any' {} + 2>/dev/null | awk -F: '$2>10{c++}END{print c+0}')

GIANT_TESTS=$(find packages -name '*.test.ts' -not -path '*/node_modules/*' \
  -exec wc -l {} + 2>/dev/null | awk '$1>1000{c++}END{print c+0}')

tee -a "$REPORT" <<EOF
Fragile tests (>10 any):    $FRAGILE_TESTS
Giant test files (>1K LOC): $GIANT_TESTS
EOF


# ── 11b. Test runtime health (from cached results) ─────────
section "Test runtime health"
tee -a "$REPORT" <<'EOF'
opencode: 2621 tests, 8 fail (99.7% pass), 20 skip
  - 5 skill discovery: all() returns 0, expected 1-2 (suspected regression)
  - 1 HTTP workspace proxy: timeout test, expected 500
  - 2 provider HttpApi OAuth tests
llm: 217 tests, 3 fail (98.6% pass), 28 skip
  - 3 OpenAI route: missing OPENAI_API_KEY (auth schema error, not regression)
core: 85 tests, 0 fail (100% pass)
Total: 2923 tests, 11 fail (99.6% pass)
Note: Run with 'bun test --no-preload' from each package dir.
EOF

section "Dependency health"
DEP_STATS=$(python3 -c "
import json, sys, glob
v0=0; ranged=0; total=0
for pj in glob.glob('packages/*/package.json'):
    with open(pj) as f:
        pkg = json.load(f)
    deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
    for dep, ver in deps.items():
        if ver.startswith('workspace:') or ver.startswith('catalog:') or dep.startswith('@opencode-ai/'):
            continue
        total += 1
        clean = ver.lstrip('^~>=')
        if clean.split('.')[0] == '0':
            v0 += 1
        if ver.startswith('^') or ver.startswith('~') or ver.startswith('>='):
            ranged += 1
print(f'{total} {v0} {ranged}')
" 2>/dev/null)
TOTAL_DEPS=$(echo "$DEP_STATS" | awk '{print $1}')
V0_DEPS=$(echo "$DEP_STATS" | awk '{print $2}')
RANGED_DEPS=$(echo "$DEP_STATS" | awk '{print $3}')
PATCHED_PKGS=$(ls patches/*.patch 2>/dev/null | wc -l)
tee -a "$REPORT" <<EOF
Total unique deps:      $TOTAL_DEPS
v0.x unstable deps:     $V0_DEPS
Ranged version deps:    $RANGED_DEPS
Patched packages:       $PATCHED_PKGS
EOF

# ── 11d. Non-null assertions ────────────────────────────────
section "Non-null assertions"
NON_NULL_TOTAL=$(python3 << 'PYEOF'
import os, re
total = 0
for root, dirs, files in os.walk('packages'):
    dirs[:] = [d for d in dirs if d != 'node_modules']
    for f in files:
        if not f.endswith('.ts') or f.endswith('.test.ts') or f.endswith('.d.ts') or f.endswith('.gen.ts'):
            continue
        filepath = os.path.join(root, f)
        with open(filepath) as fh:
            lines = fh.readlines()
        for line in lines:
            if re.search(r'(String|Int|Float|Boolean|ID)!', line):
                continue
            stripped = line.lstrip()
            if stripped.startswith('//') or stripped.startswith('*'):
                continue
            for m in re.finditer(r'([\w\)\]])(!)(?![!=])', line):
                pos = m.start(2)
                before = line[:pos]
                dq = before.count('"') - before.count('\\"')
                sq = before.count("'") - before.count("\\'")
                bt = before.count('`') - before.count('\\`')
                if dq % 2 == 0 and sq % 2 == 0 and bt % 2 == 0:
                    total += 1
print(total)
PYEOF
)
metric non_null_assertions "$NON_NULL_TOTAL"
tee -a "$REPORT" <<EOF
Non-null assertions (!):  $NON_NULL_TOTAL
EOF

# ── 12. Debt score (composite, 0–100) ──────────────────────
section "Composite debt score"
# Each dimension capped at its weight. No overflow.
#   god files (1K): 15 pts  — baseline: 10 files over 1K lines
#   any casts:      15 pts  — baseline: 500 any casts
#   dual-write:     15 pts  — baseline: 10 markers
#   markers:        10 pts  — baseline: 25 TODO/FIXME
#   deep nesting:   10 pts  — baseline: 3000 deep lines
#   coupling:       10 pts  — baseline: 5 highly-coupled files
#   deprecated:     10 pts  — baseline: 15 deprecated markers
#   test quality:   10 pts  — baseline: 3 fragile + 5 giant tests
#   no-test pkgs:    5 pts  — baseline: 3 packages

clamp() { awk "BEGIN{v=$1*$3/$2; if(v>$3) v=$3; printf \"%.1f\", v}"; }

GOD_PTS=$(clamp "$GOD_1K" 10 15)
ANY_PTS=$(clamp "$ANY_COUNT" 500 15)
DUAL_PTS=$(clamp "$DUAL_WRITE" 10 15)
MARKER_PTS=$(clamp "$REAL_TODOS" 25 10)
DEEP_PTS=$(clamp "$DEEP_LINES" 3000 10)
COUPLE_PTS=$(clamp "$COUPLED_COUNT" 5 10)
DEP_PTS=$(clamp "$DEPRECATED" 15 10)
FRAGILE_TOTAL=$((FRAGILE_TESTS + GIANT_TESTS))
TESTQ_PTS=$(clamp "$FRAGILE_TOTAL" 8 10)
NOTEST_PTS=$(clamp "$NO_TEST_COUNT" 3 5)

DEBT_SCORE=$(awk "BEGIN{printf \"%.1f\", $GOD_PTS+$ANY_PTS+$DUAL_PTS+$MARKER_PTS+$DEEP_PTS+$COUPLE_PTS+$DEP_PTS+$TESTQ_PTS+$NOTEST_PTS}")
DEBT_SCORE_CAPPED=$(awk "BEGIN{printf \"%.1f\", ($DEBT_SCORE>100)?100:$DEBT_SCORE}")

tee -a "$REPORT" <<EOF
God files (1K):     $GOD_PTS/15
Any casts:          $ANY_PTS/15
Dual-write:         $DUAL_PTS/15
Markers:            $MARKER_PTS/10
Deep nesting:       $DEEP_PTS/10
Coupling:           $COUPLE_PTS/10
Deprecated:         $DEP_PTS/10
Test quality:       $TESTQ_PTS/10
No-test packages:   $NOTEST_PTS/5
─────────────────────────
Total:              $DEBT_SCORE_CAPPED/100
EOF

# ── 13. Per-package debt breakdown ──────────────────────────
section "Per-package breakdown"
{
  echo "pkg src test any todo deprec god500 ts-ignore"
  for pkg in packages/*/; do
    name=$(basename "$pkg")
    src=$({ find "$pkg/src" "$pkg/app/src" "$pkg/core/src" -name '*.ts' -not -name '*.test.ts' -not -name '*.d.ts' 2>/dev/null || true; } | wc -l)
    tests=$({ find "$pkg" -name '*.test.ts' -not -path '*/node_modules/*' 2>/dev/null || true; } | wc -l)
    any_c=$({ grep -rn 'as any\|: any\b' --include='*.ts' "$pkg" --exclude-dir=node_modules --exclude-dir=.sst 2>/dev/null \
      | grep -vc 'types.gen.ts\|sdk.gen.ts' || true; })
    todo_c=$({ grep -rn 'TODO:\|FIXME:\|HACK:\|XXX:' --include='*.ts' "$pkg" --exclude-dir=node_modules 2>/dev/null \
      | grep -vc 'i18n/\|prompt.example' || true; })
    dep_c=$({ grep -rn '@deprecated' --include='*.ts' "$pkg" --exclude-dir=node_modules 2>/dev/null \
      | grep -vc 'types.gen.ts\|sdk.gen.ts' || true; })
    god_c=$({ find "$pkg" -name '*.ts' -not -path '*/node_modules/*' -not -name '*.test.ts' \
      -not -name '*.d.ts' -not -name 'types.gen.ts' -not -name 'sdk.gen.ts' -not -path '*/i18n/*' \
      -exec wc -l {} + 2>/dev/null || true; } | awk '$1>500{c++}END{print c+0}')
    tsig_c=$({ grep -rn '@ts-ignore\|@ts-expect-error\|@ts-nocheck' --include='*.ts' "$pkg" --exclude-dir=node_modules 2>/dev/null \
      | grep -vc 'types.gen.ts\|sdk.gen.ts' || true; })
    if [ "$src" -gt 0 ]; then
      echo "$name $src $tests $any_c $todo_c $dep_c $god_c $tsig_c"
    fi
  done
} | column -t | tee -a "$REPORT"

# ── Emit primary + secondary metrics ────────────────────────
metric "debt_score" "$DEBT_SCORE_CAPPED"
metric "god_files" "$GOD_COUNT"
metric "god_files_1k" "$GOD_1K"
metric "any_casts" "$ANY_COUNT"
metric "any_casts_src" "$ANY_SRC"
metric "any_casts_test" "$ANY_TEST"
metric "ts_ignore" "$TS_IGNORE"
metric "todo_fixme" "$REAL_TODOS"
metric "dual_write_markers" "$DUAL_WRITE"
metric "deprecated_markers" "$DEPRECATED"
metric "deep_nesting_lines" "$DEEP_LINES"
metric "no_test_packages" "$NO_TEST_COUNT"
metric "effect_files" "$EFFECT_FILES"
metric "effect_import_files" "$EFFECT_IMPORT"
metric "total_src_files" "$TOTAL_SRC"
metric "total_test_files" "$TOTAL_TEST"
metric "source_lines" "$TOTAL_LINES"
metric "coupled_files" "$COUPLED_COUNT"
metric "fragile_tests" "$FRAGILE_TESTS"
metric "giant_tests" "$GIANT_TESTS"
metric "zen_any_total" "$ZEN_ANY_TOTAL"

echo ""
echo "Report written to $REPORT"
