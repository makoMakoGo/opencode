# OpenCode Notes — Metric Fact-Check Findings

Date: 2026-05-28. Source of truth: live repo at HEAD + `autoresearch-report.txt`.

---

## Finding 1: CRITICAL_ANALYSIS.md version claim — WRONG (stale)

**Location**: `CRITICAL_ANALYSIS.md` line 13
**Quoted claim**: `版本 | 1.14.46`
**Verdict**: **wrong** — stale by many releases
**Evidence**: `packages/opencode/package.json` line 3: `"version": "1.15.10"`. The report is dated 2026-05-12; 16 days of releases have passed.
**Replacement**: `版本 | 1.15.10`
**Severity**: low — metadata, no argument depends on it

---

## Finding 2: CRITICAL_ANALYSIS.md Bun version — WRONG (stale)

**Location**: `CRITICAL_ANALYSIS.md` line 11
**Quoted claim**: `运行时 | Bun 1.3.13`
**Verdict**: **wrong**
**Evidence**: `bun --version` → `1.3.14`
**Replacement**: `运行时 | Bun 1.3.14`
**Severity**: low

---

## Finding 3: CRITICAL_ANALYSIS.md total commits — WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 14
**Quoted claim**: `Commits | 16,025`
**Verdict**: **wrong** — overstated by ~2,547
**Evidence**: `git rev-list --count HEAD` → `13,478`; `git rev-list --count dev` → `13,428`
**Replacement**: `Commits | 13,478`
**Severity**: medium — inflates perception of codebase churn

---

## Finding 4: critique-report.md dev commits — OK

**Location**: `opencode-critique-report.md` line 586, 789
**Quoted claim**: `Total commits on dev: 13,428`
**Verdict**: **ok**
**Evidence**: `git rev-list --count dev` → `13,428`
**Severity**: n/a

---

## Finding 5: CRITICAL_ANALYSIS.md total .ts/.tsx files — WRONG (two different numbers)

**Location**: `CRITICAL_ANALYSIS.md` lines 10 and 21
**Quoted claim**: line 10: `1,736 个 .ts/.tsx 文件`; line 21: `1,739 个 .ts/.tsx 文件`
**Verdict**: **wrong** — both undercount, and they contradict each other 11 lines apart
**Evidence**: `find packages -name '*.ts' -o -name '*.tsx' | grep -v node_modules | grep -v .sst | wc -l` → `2,055`
**Replacement**: `2,055 个 .ts/.tsx 文件`
**Severity**: medium — understates project scale by ~300 files

---

## Finding 6: CRITICAL_ANALYSIS.md opencode/src file count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 16
**Quoted claim**: `源文件 | 529 个（packages/opencode/src/）`
**Verdict**: **wrong** — overstated by ~96
**Evidence**: `find packages/opencode/src -name '*.ts' | wc -l` → `433`
**Replacement**: `源文件 | 433 个（packages/opencode/src/）`
**Severity**: medium — inflates perceived size

---

## Finding 7: CRITICAL_ANALYSIS.md test file count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 17
**Quoted claim**: `263 个（packages/opencode/test/，含 233 个 .test 文件 + 30 个辅助/fixture）`
**Verdict**: **wrong**
**Evidence**: `.test.ts` files → `258`; total `.ts` in test → `296`. Neither matches 263 or 233.
**Replacement**: `296 个（packages/opencode/test/，含 258 个 .test 文件 + 38 个辅助/fixture）`
**Severity**: medium

---

## Finding 8: CRITICAL_ANALYSIS.md opencode/src lines — WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 15
**Quoted claim**: `核心代码 | ~107,000 行（packages/opencode/src/）`
**Verdict**: **wrong** — overstated by ~25%
**Evidence**: `wc -l` total → `85,477`
**Replacement**: `核心代码 | ~85,500 行（packages/opencode/src/）`
**Severity**: high — core scale metric used throughout

---

## Finding 9: CRITICAL_ANALYSIS.md test line count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 17
**Quoted claim**: `~55,000 行测试代码`
**Verdict**: **wrong** — understated by ~60%
**Evidence**: `find packages/opencode/test -name '*.ts' | xargs wc -l | tail -1` → `88,295`
**Replacement**: `~88,300 行测试代码`
**Severity**: high — understates test investment

---

## Finding 10: CRITICAL_ANALYSIS.md total lines — WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 22
**Quoted claim**: `总代码量 | ~250,000 行`
**Verdict**: **wrong** — understated by ~72K
**Evidence**: `find packages -name '*.ts' | xargs wc -l | tail -1` → `322,076`
**Replacement**: `总代码量 | ~322,000 行`
**Severity**: high — used as rhetorical anchor

---

## Finding 11: critique-report.md "186K 行代码" — WRONG, SELF-CONTRADICTORY

**Location**: `opencode-critique-report.md` line 1 (title), 98, 204 (also "214K"), 1682 ("186,000 行"), 2116
**Quoted claim**: `OpenCode 是一个用 186K 行代码证明了...`
**Verdict**: **wrong** and self-contradictory — same doc says "186K" in title and "214K" at line 204/229
**Evidence**: autoresearch `source_lines=214402` (all packages, non-test, non-.d.ts); total all .ts = 322,076. "186K" doesn't match any defensible count.
**Severity**: high — title claim, sets narrative tone

---

## Finding 12: CRITICAL_ANALYSIS.md package count — MISLEADING

**Location**: `CRITICAL_ANALYSIS.md` line 20 (`16 个包`), line 68 heading (`20 个 Package`)
**Quoted claim**: `16 个包，943 个文件` and `20 个 Package 总览`
**Verdict**: **misleading** — self-contradictory (16 vs 20 vs actual)
**Evidence**: `ls -d packages/*/` → 22 directories
**Severity**: medium — 16/20/22 are all different

---

## Finding 13: CRITICAL_ANALYSIS.md `any` type count — GROSSLY WRONG

**Location**: `CRITICAL_ANALYSIS.md` §3.1 (line 170)
**Quoted claim**: `` `any` 类型：106 处 ``
**Verdict**: **wrong** — undercounts by 7x
**Evidence**: autoresearch `any_casts=754`, `any_casts_src=493`. Per-package breakdown: opencode alone = 319, console = 326.
**Replacement**: `` `any` 类型：754 处（493 源码 + 261 测试） ``
**Severity**: high — the single largest factual error. The document uses 106 to claim it's "confined to SDK boundary" which is false (319 in opencode, 326 in console).

---

## Finding 14: CRITICAL_ANALYSIS.md Effect import file count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.1 (line 88)
**Quoted claim**: `import effect 的文件数 | 241 / ~980 (25%)`
**Verdict**: **wrong** — understates by 30
**Evidence**: `grep -rl '"effect"' packages/opencode/src/ | wc -l` → `271`. Matches autoresearch `effect_import_files=271`.
**Replacement**: `import effect 的文件数 | 271 / ~433 (63%)`
**Severity**: medium — changes the characterization from 25% to 63% of src files

---

## Finding 15: CRITICAL_ANALYSIS.md Effect version — STALE

**Location**: `CRITICAL_ANALYSIS.md` §1.1 (line 99)
**Quoted claim**: `Effect 4.0-beta.59`
**Verdict**: **stale**
**Evidence**: `grep '"effect"' package.json` → `4.0.0-beta.66`
**Replacement**: `Effect 4.0.0-beta.66`
**Severity**: low

---

## Finding 16: CRITICAL_ANALYSIS.md provider.ts line count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.2 (line 103)
**Quoted claim**: `provider/provider.ts（1,767 行全文）`
**Verdict**: **wrong** — understated by 115
**Evidence**: `wc -l packages/opencode/src/provider/provider.ts` → `1,882`
**Replacement**: `provider/provider.ts（1,882 行全文）`
**Severity**: low

---

## Finding 17: CRITICAL_ANALYSIS.md transform.ts line count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.2 (line 103)
**Quoted claim**: `provider/transform.ts（1,401 行全文）`
**Verdict**: **wrong** — overstated by 17
**Evidence**: `wc -l packages/opencode/src/provider/transform.ts` → `1,384`
**Replacement**: `provider/transform.ts（1,384 行全文）`
**Severity**: low

---

## Finding 18: CRITICAL_ANALYSIS.md session.ts line count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.3 (line 117)
**Quoted claim**: `session/session.ts（937 行全文）`
**Verdict**: **wrong** — understated by 75
**Evidence**: `wc -l packages/opencode/src/session/session.ts` → `1,012`
**Replacement**: `session/session.ts（1,012 行全文）`
**Severity**: medium

---

## Finding 19: CRITICAL_ANALYSIS.md message-v2.ts line count — CLOSE

**Location**: `CRITICAL_ANALYSIS.md` §1.3 (line 117)
**Quoted claim**: `session/message-v2.ts（1,199 行全文）`
**Verdict**: **wrong** — off by 4
**Evidence**: `wc -l` → `1,203`
**Severity**: low

---

## Finding 20: CRITICAL_ANALYSIS.md compaction.ts line count — GROSSLY WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.3 (line 125)
**Quoted claim**: `compaction.ts（~300 行）`
**Verdict**: **wrong** — understated by 2x
**Evidence**: `wc -l` → `639`
**Replacement**: `compaction.ts（639 行）`
**Severity**: medium — "300 lines" was used to downplay complexity

---

## Finding 21: CRITICAL_ANALYSIS.md tool/registry.ts line count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.4 (line 129)
**Quoted claim**: `tool/registry.ts（~379 行）`
**Verdict**: **wrong** — understated by 96
**Evidence**: `wc -l` → `475`
**Replacement**: `tool/registry.ts（475 行）`
**Severity**: low

---

## Finding 22: CRITICAL_ANALYSIS.md tool/shell.ts line count — CLOSE

**Location**: `CRITICAL_ANALYSIS.md` §1.4 (line 133)
**Quoted claim**: `tool/shell.ts（631 行）`
**Verdict**: **wrong** — off by 16
**Evidence**: `wc -l` → `647`
**Severity**: low

---

## Finding 23: CRITICAL_ANALYSIS.md lsp/server.ts line count — CLOSE

**Location**: `CRITICAL_ANALYSIS.md` §二 (line 149)
**Quoted claim**: `lsp/server.ts | 2,065`
**Verdict**: **wrong** — off by 1
**Evidence**: `wc -l` → `2,064`
**Severity**: low

---

## Finding 24: CRITICAL_ANALYSIS.md acp/agent.ts line count — CLOSE

**Location**: `CRITICAL_ANALYSIS.md` §二 (line 150)
**Quoted claim**: `acp/agent.ts | 1,969`
**Verdict**: **wrong** — off by 3
**Evidence**: `wc -l` → `1,966`
**Severity**: low

---

## Finding 25: CRITICAL_ANALYSIS.md config.ts line count — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §二 (line 156)
**Quoted claim**: `config/config.ts | 848`
**Verdict**: **wrong** — off by 36
**Evidence**: `wc -l` → `884`
**Severity**: low

---

## Finding 26: critique-report.md "dogshit" line number — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.2 (line 113)
**Quoted claim**: `第 59 行`
**Verdict**: **wrong** — off by 3 lines
**Evidence**: `grep -n 'dogshit' packages/opencode/src/provider/transform.ts` → line 62
**Replacement**: `第 62 行`
**Severity**: low

---

## Finding 27: critique-report.md processor.ts line count — GROSSLY WRONG

**Location**: `opencode-critique-report.md` line 824
**Quoted claim**: `阅读 processor.ts（1,200 行）`
**Verdict**: **wrong** — overstated by 36%
**Evidence**: `wc -l` → `883`
**Replacement**: `阅读 processor.ts（883 行）`
**Severity**: medium

---

## Finding 28: critique-report.md God files >1K — SELF-CONTRADICTORY

**Location**: `opencode-critique-report.md` line 104 vs lines 121, 297, 414
**Quoted claim**: line 104: `16 个 超过 1000 行的"巨型文件"`; lines 121,297,414: `18 个`
**Verdict**: **wrong** — self-contradictory; autoresearch says 18
**Evidence**: autoresearch `god_files_1k=18`
**Replacement (line 104)**: `18 个 超过 1000 行的"巨型文件"`
**Severity**: medium — internal inconsistency

---

## Finding 29: critique-report.md deep nesting — WRONG

**Location**: `opencode-critique-report.md` lines 300, 1969, 2080
**Quoted claim**: `3,693 行`
**Verdict**: **wrong** — overstated by 379
**Evidence**: autoresearch `deep_nesting_lines=3,314`
**Replacement**: `3,314 行`
**Severity**: medium

---

## Finding 30: critique-report.md largest SCC — WRONG

**Location**: `opencode-critique-report.md` lines 128, 192, 218, 480, 1342, 1443, 1644, 1650, 1821, 1822, 1879, 1889, 1943, 1972, 2080
**Quoted claim**: `20 模块` largest SCC (repeated ~15 times)
**Verdict**: **wrong** — autoresearch says 19
**Evidence**: autoresearch `scc_largest=19`
**Replacement**: `19 模块` in every occurrence
**Severity**: medium — persistent exaggeration across entire document

---

## Finding 31: critique-report.md non-null assertions — SELF-CONTRADICTORY

**Location**: `opencode-critique-report.md` line 1972 vs line 197, 2100
**Quoted claim**: line 1972: `173 个`; lines 197/2100: `212`
**Verdict**: **wrong** — self-contradictory; autoresearch says 212
**Evidence**: autoresearch `non_null_assertions=212`
**Replacement (line 1972)**: `212 个`
**Severity**: medium

---

## Finding 32: critique-report.md ts-ignore count — WRONG

**Location**: `opencode-critique-report.md` line 588
**Quoted claim**: `15 个（@ts-ignore + @ts-expect-error）`
**Verdict**: **wrong** — undercounts by 4x
**Evidence**: autoresearch `ts_ignore=63` (source: 29)
**Replacement**: `63 个（@ts-ignore + @ts-expect-error，源码 29）`
**Severity**: medium

---

## Finding 33: critique-report.md TODO/FIXME count — WRONG

**Location**: `opencode-critique-report.md` line 303
**Quoted claim**: `18 个真实标记`
**Verdict**: **wrong** — autoresearch says 16
**Evidence**: autoresearch `todo_fixme=16`
**Replacement**: `16 个真实标记`
**Severity**: low

---

## Finding 34: critique-report.md patched packages — WRONG (repeated)

**Location**: `opencode-critique-report.md` lines 194, 220, 517, 1517, 1519-1523
**Quoted claim**: `4 个补丁包（solid-js、photon-node、standard-openapi、npmcli/agent）`
**Verdict**: **wrong** — 7 patches exist, 3 missing from list
**Evidence**: `ls patches/*.patch` → 7 files: `@ai-sdk/xai`, `@npmcli/agent`, `@silvia-odwyer/photon-node`, `@standard-community/standard-openapi`, `gcp-metadata`, `solid-js`, `virtua`. Missing from claim: `@ai-sdk/xai`, `gcp-metadata`, `virtua`.
**Replacement**: `7 个补丁包（solid-js、photon-node、standard-openapi、npmcli/agent、@ai-sdk/xai、gcp-metadata、virtua）`
**Severity**: medium

---

## Finding 35: critique-report.md "186K" vs "214K" title contradiction — WRONG

**Location**: `opencode-critique-report.md` line 1 (title: "186K") vs line 204/229 ("214K")
**Verdict**: **wrong** — two incompatible numbers in the same document
**Evidence**: autoresearch `source_lines=214402`; total .ts = 322,076. Neither "186K" nor "214K" matches total. "214K" matches autoresearch's source_lines definition. "186K" matches no definition.
**Severity**: high — title claim

---

## Finding 36: critique-report.md trend chart — FABRICATED

**Location**: `opencode-critique-report.md` line 179
**Quoted claim**: Historical debt scores: `[20, 35, 55, 75, 85, 90, 92, 92.4]` for Q3 2024 through Q2 2026
**Verdict**: **hallucination** — no historical debt scores exist. The autoresearch harness was created in 2026-05; no prior runs exist.
**Evidence**: `autoresearch.sh` is a single-run tool with no version history storage. The claim "4.6x debt increase in 2 years (20 → 92.4)" at line 188 is fabricated.
**Severity**: high — fabricated trend data

---

## Finding 37: critique-report.md economic claims — UNSUPPORTED

**Location**: `opencode-critique-report.md` lines 131, 188, 248-288
**Quoted claims**: `$83,000/year`, `8.25x time cost multiplier`, `9,180 hours saved over 3 years`
**Verdict**: **unsupported** — derived from assumed hourly rates ($80/hr), assumed task frequencies, and speculative scenarios. Not factual claims verifiable from code.
**Severity**: low — rhetorical, not metric claims

---

## Finding 38: critique-report.md Effect.gen 1,536 lines — AMBIGUOUS

**Location**: `opencode-critique-report.md` lines 199, 323, 1061, 1407
**Quoted claim**: `1,536 行的 Effect.gen 函数`
**Verdict**: **ambiguous** — prompt.ts has 11 `Effect.gen` calls, not one monolithic function. The claim likely refers to the outermost `prompt()` or `loop()` function body that contains nested `Effect.gen` calls. The file is 1,780 lines total.
**Evidence**: `grep -n 'Effect.gen' packages/opencode/src/session/prompt.ts` shows 11 separate calls.
**Severity**: medium — misleading characterization ("1,536 line Effect.gen function" implies a single function)

---

## Finding 39: CRITICAL_ANALYSIS.md beta dependency count — STALE

**Location**: `CRITICAL_ANALYSIS.md` §3.3 (line 198-208)
**Quoted claim**: `7 个 beta dependencies`, listing Effect 4.0.0-beta.59, drizzle-kit 1.0.0-beta.19, etc.
**Verdict**: **stale** — Effect is now beta.66 (not beta.59), drizzle is now rc.2 (not beta.19). Count may still be ~6 if drizzle-rc is counted separately from beta.
**Evidence**: `grep 'beta' package.json` → 6 matches (4 Effect-related, @pierre/diffs, @lydell/node-pty). Drizzle is `rc.2`, not `beta`.
**Severity**: low — count direction correct but versions stale

---

## Finding 40: CRITICAL_ANALYSIS.md prompt.ts 2,001 lines — WRONG

**Location**: `CRITICAL_ANALYSIS.md` §1.3 (line 123) and §二 (line 148)
**Quoted claim**: `prompt.ts（2,001 行）` and `session/prompt.ts | 2,001`
**Verdict**: **wrong** — over by 221
**Evidence**: `wc -l packages/opencode/src/session/prompt.ts` → `1,780`
**Replacement**: `prompt.ts（1,780 行）`
**Severity**: high — God-file narrative depends on this number

---

## Finding 41: CRITICAL_ANALYSIS.md Effect.gen files count — STALE

**Location**: autoresearch `effect_files=188` vs critique `168`
**Quoted claim** (critique line 1027): `Effect.gen 文件 | 168`
**Verdict**: **stale** — autoresearch says 188. Live check: `grep -rl 'Effect\.gen\|yield\*' packages/opencode/src/ | wc -l` → 164 (different grep pattern explains variance).
**Evidence**: autoresearch uses `grep -c 'Effect.gen\|yield\*'` counting lines, not files.
**Severity**: low — depends on grep pattern definition

---

## Finding 42: autoresearch debt score — STALE

**Location**: `autoresearch-report.txt` line 100
**Quoted claim**: `Total: 92.4/100`
**Verdict**: **stale** — report was generated 2026-05-26. Code has changed since. Should be re-run to confirm.
**Evidence**: report timestamp + live repo diff since generation
**Severity**: medium — if code has changed significantly, the score may have shifted

---

## Finding 43: critique-report.md console any distribution — AMBIGUOUS

**Location**: `opencode-critique-report.md` line 434-438
**Quoted claim**: `console 包: 321 次（273 次在 zen provider 的 3 个文件）` and `opencode 包: 335 次`
**Verdict**: **ambiguous** — autoresearch per-package breakdown shows console: 326, opencode: 319. The critique's 321/335 split doesn't match autoresearch's 326/319.
**Evidence**: autoresearch line 105: `console 110 4 326`; line 113: `opencode 430 258 319`
**Replacement**: `console 包: 326 次（273 次在 zen provider 的 3 个文件）` and `opencode 包: 319 次`
**Severity**: low — direction correct, numbers slightly off

---

## Finding 44: CRITICAL_ANALYSIS.md §七 summary `any` claim — GROSSLY WRONG

**Location**: `CRITICAL_ANALYSIS.md` line 361
**Quoted claim**: `106 处 any 类型 | 低-中 | 集中在 SDK 边界`
**Verdict**: **wrong** — see Finding 13. 754 total, 493 in source, not "106".
**Replacement**: `754 处 any 类型（493 源码） | 高 | 集中在 console zen provider (326) 和 opencode (319)`
**Severity**: high — this is the summary table, magnifying the error

---

## Finding 45: critique-report.md "20 个崩溃报告" / "11 个性能问题" — UNSUPPORTED

**Location**: `opencode-critique-report.md` lines 130, 573-577
**Quoted claim**: `Crash Reports: 20 个`, `Performance Issues: 11 个`, etc.
**Verdict**: **unsupported** — cannot verify offline. GitHub issue counts change daily and require API access.
**Severity**: low — unverifiable but plausible

---

## Finding 46: critique-report.md "100+ open issues" — UNSUPPORTED

**Location**: throughout critique-report.md
**Verdict**: **unsupported** — requires live GitHub API query
**Severity**: low

---

## Finding 47: critique-report.md Effect.gen 1,536 lines in prompt.ts — WRONG

**Location**: `opencode-critique-report.md` line 323
**Quoted claim**: `Effect.gen 函数: 1,536 行（占文件的 86%）`
**Verdict**: **ambiguous/wrong** — prompt.ts has 11 separate Effect.gen calls, not one. The largest block from line ~382 to the end is not a single Effect.gen.
**Evidence**: `grep -n 'Effect.gen'` shows calls at lines 103, 382, 406, 498, 500, 582, 614, 629, 1364, 1382, 1564. The function starting at line 382 to line ~1780 spans ~1,398 lines, but it contains nested Effect.gen calls and is not a single Effect.gen body.
**Severity**: medium

---

## Summary by severity

### High (7 findings)
- Finding 8: opencode/src lines ~107K → actually ~85.5K (25% overstatement)
- Finding 10: total lines ~250K → actually ~322K (understatement)
- Finding 11: "186K" title contradicts own "214K" and both are wrong for total
- Finding 13: `any` count 106 → actually 754 (7x undercount, worst error)
- Finding 35: "186K" vs "214K" internal contradiction
- Finding 36: fabricated historical trend data
- Finding 40: prompt.ts 2,001 lines → actually 1,780
- Finding 44: summary table repeats 106 any claim

### Medium (16 findings)
- Finding 3, 5, 6, 7, 12, 14, 18, 20, 27, 28, 29, 30, 31, 32, 34, 38, 42, 43, 47

### Low (14 findings)
- Finding 1, 2, 4, 9→(revised to medium), 15, 16, 17, 19, 21, 22, 23, 24, 25, 26, 33, 37, 39, 41, 45, 46

### Verdict distribution
- **wrong**: 29 findings
- **hallucination**: 1 (fabricated trend)
- **stale**: 3
- **ambiguous**: 3
- **unsupported**: 3 (require network, unverifiable offline)
- **ok**: 1 (dev commit count)
- **misleading**: 1
