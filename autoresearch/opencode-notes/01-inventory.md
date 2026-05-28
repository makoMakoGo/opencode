# OpenCode Notes Fact-Check Inventory

## 1. Note Files In Scope

| File | Lines | Role |
|------|-------|------|
| `opencode-critique-report.md` | ~2,121 | Polemical debt report. Heavy on narrative, contains concrete metrics quoted from autoresearch + GitHub claims. |
| `CRITICAL_ANALYSIS.md` | 391 | Detailed architectural analysis. Claims line-by-line source verification. Dated 2026-05-12. |
| `autoresearch-report.txt` | 141 | Machine-generated metrics from `autoresearch.sh`. Authoritative for automated counts. |
| `autoresearch.sh` | 454 | The harness that produces `autoresearch-report.txt`. Defines how each metric is computed. |

**Rule**: `autoresearch-report.txt` + live source are ground truth. The two prose note files are suspect.

---

## 2. Prioritized Checkable Claims

### Theme A: Version & Identity Metadata (HIGH — trivial to verify, often stale)

| # | Claim | Stated In | Actual | Status |
|---|-------|-----------|--------|--------|
| A1 | Version `1.14.46` | CRITICAL_ANALYSIS.md | `1.15.10` (packages/opencode/package.json) | **WRONG** — stale by multiple releases |
| A2 | Bun `1.3.13` | CRITICAL_ANALYSIS.md | `1.3.14` | **WRONG** |
| A3 | 16,025 total commits | CRITICAL_ANALYSIS.md | 13,478 (git rev-list --count HEAD) | **WRONG** — off by ~2,500 |
| A4 | 13,428 commits on dev | critique-report.md | Not independently verified (branch ref may differ) | NEEDS CHECK |
| A5 | Repo name `anomalyco/opencode` (originally `sst/opencode`) | both notes | `anomalyco/opencode` confirmed via `git remote -v` | OK |

**Verifier should inspect**: `packages/opencode/package.json`, `bun --version`, `git rev-list --count HEAD`, `git remote -v`

---

### Theme B: Codebase Scale (HIGH — core to all debt arguments)

| # | Claim | Stated In | Actual | Status |
|---|-------|-----------|--------|--------|
| B1 | 1,736 / 1,739 total .ts/.tsx files | CRITICAL_ANALYSIS.md (two different numbers) | 2,055 (`find packages -name '*.ts' -o -name '*.tsx' \| grep -v node_modules \| grep -v .sst \| wc -l`) | **WRONG** — understates by ~300 |
| B2 | 529 source files in opencode/src | CRITICAL_ANALYSIS.md | 433 (`find packages/opencode/src -name '*.ts' \| wc -l`) | **WRONG** — overstated by ~100 |
| B3 | 233 .test files + 30 helpers = 263 total test files | CRITICAL_ANALYSIS.md | 258 .test.ts + 38 other .ts = 296 total | **WRONG** |
| B4 | ~107,000 lines in opencode/src | CRITICAL_ANALYSIS.md | 85,477 lines | **WRONG** — overstated by ~25% |
| B5 | ~55,000 lines test code | CRITICAL_ANALYSIS.md | 88,295 lines in packages/opencode/test | **WRONG** — understated by ~60% |
| B6 | ~250,000 lines total | CRITICAL_ANALYSIS.md | 322,076 lines all packages .ts | **WRONG** — understated |
| B7 | "186K 行代码" | critique-report title | Inconsistent with its own later "214K" and actual 322K | **SELF-CONTRADICTORY** |
| B8 | Source lines: 214,402 | autoresearch-report | This is the autoresearch `count_lines` figure (non-test, non-.d.ts) | NEEDS RE-RUN to confirm current |
| B9 | 16 packages, 943 files | CRITICAL_ANALYSIS.md | 22 package directories; per-package breakdown covers 16 (some excluded by filter) | **MISLEADING** |
| B10 | "20 个 Package 总览" | CRITICAL_ANALYSIS.md heading | Lists 20 categories but 22 actual dirs | INCONSISTENT |

**Verifier should inspect**: `find packages -name '*.ts'`, `wc -l` on opencode/src, opencode/test, all packages

---

### Theme C: Automated Debt Metrics (HIGH — all notes derive authority from these)

| # | Claim | autoresearch-report | Actual | Status |
|---|-------|--------------------|--------|--------|
| C1 | Debt score: 92.4/100 | 92.4 | Needs re-run to confirm | STALE — code has changed |
| C2 | God files >1K LOC: 18 | 18 | 18 (confirmed) | OK |
| C3 | God files >500 LOC: 59 | 59 | Not independently counted | DEFER TO AUTORESEARCH |
| C4 | any casts total: 754 | 754 | 754 (confirmed) | OK |
| C5 | any casts src: 493 | 493 | 493 (confirmed) | OK |
| C6 | any casts test: 261 | 261 | Not independently counted | DEFER |
| C7 | ts-ignore/expect-error: 63 | 63 | 63 (confirmed) | OK |
| C8 | TODO/FIXME/HACK real: 16 | 16 | Not independently counted | DEFER |
| C9 | Dual-write markers: 16 | 16 | 16 (14 processor.ts + 2 prompt.ts — confirmed) | OK |
| C10 | Deprecated: 20 | 20 | 20 (confirmed) | OK |
| C11 | Deep nesting lines: 3,314 | 3,314 | 3,314 (confirmed) | OK |
| C12 | No-test packages: 5 | 5 | 5 with src files (function, plugin, script, slack, web) | OK |
| C13 | Circular dep SCCs: 5 | 5 | Not independently verified | DEFER |
| C14 | Largest SCC: 19 modules | 19 | Not independently verified | DEFER |
| C15 | Non-null assertions: 212 | 212 | Not independently counted | DEFER |
| C16 | Dup blocks: 647 | 647 | Not independently verified | DEFER |
| C17 | Source files: 1,154 | 1,154 | Not independently verified | DEFER |
| C18 | Test files: 408 | 408 | Not independently verified | DEFER |
| C19 | Effect import files: 271 | 271 | 271 (confirmed in opencode/src) | OK |

**Verifier should inspect**: `autoresearch.sh` (metric definitions), optionally re-run `./autoresearch.sh`

---

### Theme D: Specific File Claims (HIGH — used as narrative anchors)

| # | Claim | Stated In | Actual | Status |
|---|-------|-----------|--------|--------|
| D1 | prompt.ts = 1,780 lines, 63 imports | both notes | 1,780 lines, 63 imports (confirmed) | OK |
| D2 | transform.ts = 1,401 lines | CRITICAL_ANALYSIS.md | 1,384 lines | **WRONG** — over by 17 |
| D3 | transform.ts = 1,384 lines | critique-report (some sections) | 1,384 lines (confirmed) | OK — but same report also says 1,401 elsewhere |
| D4 | provider.ts = 1,882 lines | both notes | 1,882 lines (confirmed) | OK |
| D5 | lsp/server.ts = 2,065 lines | CRITICAL_ANALYSIS.md | 2,064 lines | OFF BY 1 |
| D6 | acp/agent.ts = 1,969 lines | CRITICAL_ANALYSIS.md | 1,966 lines | OFF BY 3 |
| D7 | session.ts = 937 lines | CRITICAL_ANALYSIS.md | 1,012 lines | **WRONG** — understated |
| D8 | message-v2.ts = 1,199 lines | CRITICAL_ANALYSIS.md | 1,203 lines | OFF BY 4 |
| D9 | processor.ts = 1,200 lines (scenario) | critique-report | 883 lines | **WRONG** — overstated by 36% |
| D10 | config/config.ts = 848 lines | CRITICAL_ANALYSIS.md | 884 lines | OFF BY 36 |
| D11 | "dogshit" comment at line 59 | CRITICAL_ANALYSIS.md | Line 62 (confirmed present) | **WRONG** — off by 3 lines |
| D12 | "dogshit" comment added 2026-05-05 by Aiden Cline, commit 6409aceb1 | both notes | Confirmed: `6409aceb1 2026-05-05 18:07:23 -0500` | OK |
| D13 | anthropic.ts: 760 lines, 118 any-uses | both notes | 760 lines confirmed; 118 any count from autoresearch | NEEDS COUNT |
| D14 | openai.ts: 629 lines, 124 any | critique-report | 629 lines confirmed; 124 any count not independently verified | NEEDS COUNT |
| D15 | compaction.ts ~300 lines | CRITICAL_ANALYSIS.md | 639 lines | **WRONG** — understated by 2x |
| D16 | tool/registry.ts ~379 lines | CRITICAL_ANALYSIS.md | 475 lines | **WRONG** — understated |
| D17 | tool/shell.ts 631 lines | CRITICAL_ANALYSIS.md | 647 lines | OFF BY 16 |
| D18 | "prompt.ts Effect.gen 1,536 lines" | critique-report | Not independently verified | NEEDS CHECK |
| D19 | prompt.ts "import 30+ 模块" / "63 个 import" | CRITICAL_ANALYSIS / critique | 63 import statements confirmed | OK |

**Verifier should inspect**: `wc -l` on each named file, `grep -n dogshit` transform.ts

---

### Theme E: Effect-TS Metrics (MEDIUM)

| # | Claim | Stated In | Actual | Status |
|---|-------|-----------|--------|--------|
| E1 | Effect import files: 241 | CRITICAL_ANALYSIS.md | 271 (confirmed; matches autoresearch) | **WRONG** |
| E2 | Effect import lines: 245 | CRITICAL_ANALYSIS.md | Not independently counted | NEEDS CHECK |
| E3 | Effect Schema usage: 142 lines | CRITICAL_ANALYSIS.md | Not independently counted | NEEDS CHECK |
| E4 | 66 Services, 66 Layers, 58 defaultLayers | critique-report | Not independently counted | NEEDS CHECK |
| E5 | Effect 4.0.0-beta.59 | CRITICAL_ANALYSIS.md | Not verified from package.json | NEEDS CHECK |

**Verifier should inspect**: `grep -rl '"effect"' packages/opencode/src/`, `grep -c 'Context.Service'`, root `package.json`

---

### Theme F: any-Type Claims in CRITICAL_ANALYSIS vs autoresearch (MEDIUM — major internal contradiction)

| # | Claim | Stated In | Actual | Status |
|---|-------|-----------|--------|--------|
| F1 | "`any` 类型：106 处" | CRITICAL_ANALYSIS.md §3.1 | autoresearch says 754 total, 493 src; per-package breakdown shows opencode alone has 319 | **GROSSLY WRONG** — CRITICAL_ANALYSIS undercounts by 7x |
| F2 | "106 处 any" confined to SDK boundary | CRITICAL_ANALYSIS.md | 319 in opencode package alone, 326 in console | **WRONG** — characterization is wrong |

This is the single largest factual error: CRITICAL_ANALYSIS.md §3.1 claims only 106 `any` uses and attributes them to SDK boundary. The actual count across all packages is 754. The autoresearch (which CRITICAL_ANALYSIS itself cites elsewhere) says 754.

**Verifier should inspect**: `grep -rn 'as any\|: any\b' --include='*.ts' packages/ --exclude-dir=node_modules --exclude-dir=.sst`

---

### Theme G: Dependency & Patch Claims (MEDIUM)

| # | Claim | Stated In | Actual | Status |
|---|-------|-----------|--------|--------|
| G1 | 4 patched packages | critique-report (multiple places) | 7 patch files in `patches/` directory | **WRONG** |
| G2 | Patches: solid-js, photon-node, standard-openapi, npmcli/agent | critique-report | Also includes: @ai-sdk/xai, gcp-metadata, virtua | **INCOMPLETE** |
| G3 | 19 v0.x unstable deps | critique-report | autoresearch says 19, not independently verified | DEFER |
| G4 | 7 beta dependencies listed | CRITICAL_ANALYSIS.md | Not independently verified | NEEDS CHECK |

**Verifier should inspect**: `ls patches/`, `grep '"0\.' packages/*/package.json`

---

### Theme G2: Unsupported GitHub Claims (MEDIUM — cannot verify offline)

The critique report cites ~20 specific GitHub issues by number with quoted text. These cannot be verified without network access. They should be treated as **unverifiable in this pass**:

- Issue #22883 (OOM Kill)
- Issue #28830 (WSL2 crash)
- Issue #26667 (AbortError sidecar crash)
- Issue #25953 (Edit tool Python indentation)
- Issue #16450 (concurrent config deletion)
- Issue #27106 (terribly slow)
- Issue #24771 (severe performance)
- Issue #27027 (symlink skill discovery)
- Issue #28686 (Desktop V2 UI)
- Issue #29051 (V2 prompt reasoning selector)
- Issue #27638 (circular symlinks crash)
- Issue #20940 (plugin config hook)
- Issue #19353 (splitting config)
- Issue #9062 (config.d directory)
- Issue #28600 (centralize paths)
- PR #25934 ("fix: sanitize surrogates")
- PR #18854 ("fix(app): startup efficiency")
- Commit 6409aceb1 (dogshit comment) — **confirmed**

Also cites: "100+ open issues", "20 crash reports", "11 performance issues", "6 V2 transition bugs", "7 skill discovery problems", "8 config architecture requests". These aggregate counts are **unverifiable offline**.

---

### Theme H: Economic & Trend Claims (LOW — speculative, not factual)

| # | Claim | Stated In | Verifiable? |
|---|-------|-----------|-------------|
| H1 | $83,000/year extra developer cost | critique-report | No — based on assumed hourly rates and time estimates |
| H2 | "4.6x debt increase in 2 years (20 → 92.4)" | critique-report | No — no historical debt scores exist |
| H3 | "8.25x time cost multiplier" | critique-report | No — hypothetical scenario |
| H4 | "9,180 hours saved over 3 years" | critique-report | No — derived from speculative assumptions |

These are rhetorical fabrications, not factual claims. Flag for removal or recharacterization.

---

## 3. Source Files Each Verifier Should Inspect

| Scope | Files |
|-------|-------|
| Package metadata | `packages/opencode/package.json`, root `package.json`, `bun --version` |
| Large source files | `packages/opencode/src/session/prompt.ts`, `provider/transform.ts`, `provider/provider.ts`, `lsp/server.ts`, `acp/agent.ts`, `session/session.ts`, `session/compaction.ts`, `tool/registry.ts`, `config/config.ts` |
| Console zen providers | `packages/console/app/src/routes/zen/util/provider/anthropic.ts`, `openai.ts`, `openai-compatible.ts` |
| Dual-write code | `packages/opencode/src/session/processor.ts`, `session/prompt.ts` |
| Effect counts | `grep -rl '"effect"' packages/opencode/src/` |
| Metrics harness | `autoresearch.sh` (defines all metric computations) |
| Patches | `patches/` directory listing |
| Git history | `git rev-list --count HEAD`, `git log -1 6409aceb1` |

---

## 4. Obvious Internal Inconsistencies Between Note Files

### Between CRITICAL_ANALYSIS.md and autoresearch-report.txt

| # | Metric | CRITICAL_ANALYSIS | autoresearch-report | Delta |
|---|--------|-------------------|--------------------|----|
| I1 | `any` casts | **106** (§3.1) | **754** | 7x undercount |
| I2 | Effect import files | **241** | **271** | 30 fewer |
| I3 | transform.ts lines | **1,401** | **1,384** (via harness) | 17 more |
| I4 | opencode src files | **529** | **430** (per-package breakdown) | ~100 more |
| I5 | opencode src lines | **~107,000** | autoresearch `source_lines=214402` is ALL packages | Not comparable but presented as if |

### Within opencode-critique-report.md (self-contradictions)

| # | Metric | Location A | Location B | Conflict |
|---|--------|-----------|-----------|----------|
| I6 | Total code lines | "186K" (title/line 98,204) | "214K" (line 204,229) | Two different numbers in same document |
| I7 | God files >1K | "16 个" (line 104) | "18 个" (lines 121,297,414) | Same doc, two different numbers |
| I8 | Deep nesting | "3,693" (lines 300,1969,2080) | autoresearch: "3,314" | 379 lines overstated |
| I9 | Largest SCC | "20 模块" (lines 128,192,480, etc.) | autoresearch: "19" | 1 module overstated |
| I10 | Non-null assertions | "173" (line 2082) | "212" (lines 197,2100) and autoresearch | Self-contradictory |
| I11 | ts-ignore count | "15" (line 588) | autoresearch: "63" | 4x undercount |
| I12 | TODO/FIXME count | "18" (line 303) | autoresearch: "16" | 2 overstated |
| I13 | Patched packages | "4" (lines 194,220,1519) | autoresearch: "7" (actual: 7) | 3 missing |
| I14 | transform.ts lines | "1,384" (line 337) | "1,401" (CRITICAL_ANALYSIS) / "1,384" elsewhere | Inconsistent within ecosystem |
| I15 | Debt score trend | "20 → 92.4 over 2 years" (line 188) | No historical data exists | Fabricated trend |

### Between CRITICAL_ANALYSIS.md and itself

| # | Metric | Location A | Location B | Conflict |
|---|--------|-----------|-----------|----------|
| I16 | Total .ts files | "1,736" (line 10) | "1,739" (line 21) | Two different numbers 11 lines apart |
| I17 | Package count | "16 个包" (line 20) | "20 个 Package" (line 68 heading) | 16 vs 20 vs actual 22 |
