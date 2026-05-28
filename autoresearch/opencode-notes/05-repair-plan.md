# Repair Plan — Synthesized from Metric + Architecture Fact-Check

Date: 2026-05-28. Sources: `02-metric-findings.md`, `03-architecture-findings.md`.
All conflicts re-verified against live repo at HEAD.

`04-rhetoric-findings.md` does not exist; this plan covers all available findings.

---

## 1. Deduplicated Must-Fix Issues

Sorted by target file, then severity (high → low). Each entry merges all overlapping findings from both reports.

### CRITICAL_ANALYSIS.md

| # | Lines | Claim | Actual | Severity | Sources |
|---|---|---|---|---|---|
| CA-1 | 170, 361 | `any` 类型 106 处 | 754 处 (493 源码 + 261 测试); opencode=319, console=326 | **high** | M-13, M-44 |
| CA-2 | 123, 148 | prompt.ts（2,001 行） | 1,780 行 | **high** | M-40 |
| CA-3 | 129 | 19 个内置工具; lists "codesearch" | 18 个; no codesearch.ts or codesearch permission key exists | **high** | A-07, A-09 |
| CA-4 | 15 | 核心代码 ~107,000 行 | ~85,500 行 (`wc -l` total = 85,477) | **high** | M-8 |
| CA-5 | 22 | 总代码量 ~250,000 行 | ~322,000 行 (322,076) | **high** | M-10 |
| CA-6 | 17 | ~55,000 行测试代码 | ~88,300 行 (88,295) | **high** | M-9 |
| CA-7 | 20, 68 | 16 个包 / 20 个 Package 总览 | 22 个包 | **high** | M-12, A-01 |
| CA-8 | 14 | Commits 16,025 | 13,478 (HEAD) | **medium** | M-3 |
| CA-9 | 10, 21 | 1,736 / 1,739 个 .ts/.tsx 文件 | 2,055 (both numbers wrong + contradict each other) | **medium** | M-5 |
| CA-10 | 16 | 源文件 529 个 | 433 个 | **medium** | M-6 |
| CA-11 | 17 | 263 个测试 (233 .test + 30 fixture) | 296 个 (258 .test + 38 fixture) | **medium** | M-7 |
| CA-12 | 88 | Effect import 241/~980 (25%) | 271/~433 (63%) | **medium** | M-14, A-04 |
| CA-13 | 125 | compaction.ts（~300 行） | 639 行 | **medium** | M-20, A-13 |
| CA-14 | 117 | session.ts（937 行） | 1,012 行 | **medium** | M-18 |
| CA-15 | 105 | 22 个 SDK / 16 个 provider 特殊处理 | 23 个 SDK / 21 个 provider | **medium** | A-05, A-06 |
| CA-16 | 57 | schema/route/protocols/providers 四层 | 五层 (includes utils/) | **medium** | A-18 |
| CA-17 | 199–209 | Beta dependency table: 4 of 7 entries stale/wrong | Effect → beta.66, drizzle → rc.2, missing @effect/sql-sqlite-bun | **medium** | A-03 |
| CA-18 | 139 | 11 个内部 TUI 插件 (INTERNAL_TUI_PLUGINS) | 12 个 (+1 conditional), via internalTuiPlugins() | **low** | A-08 |
| CA-19 | 103 | provider.ts（1,767 行）, transform.ts（1,401 行） | 1,882 / 1,384 | **low** | M-16, M-17 |
| CA-20 | 103, 148 | lsp/server.ts 2,065 / acp/agent.ts 1,969 | 2,064 / 1,966 | **low** | M-23, M-24 |
| CA-21 | 156 | config.ts 848 | 884 | **low** | M-25 |
| CA-22 | 113 | dogshit 第 59 行 | 第 62 行 | **low** | M-26, A-10 |
| CA-23 | 131 | permission/evaluate.ts（15 行） | 1 行 (re-export from @opencode-ai/core) | **low** | A-12 |
| CA-24 | 129 | tool/registry.ts（~379 行） | 475 行 | **low** | M-21, A-14 |
| CA-25 | 117 | message-v2.ts（1,199 行） | 1,203 行 | **low** | M-19 |
| CA-26 | 133 | tool/shell.ts（631 行） | 647 行 | **low** | M-22 |
| CA-27 | 11, 13 | Bun 1.3.13 / version 1.14.46 | Bun 1.3.14 / version 1.15.10 | **low** | M-1, M-2 |
| CA-28 | 99, 202 | Effect 4.0-beta.59 | 4.0.0-beta.66 | **low** | M-15, A-02 |
| CA-29 | 94 | Internal component line counts: Runner ~159, SyncEvent 367, etc. | Runner 217, SyncEvent 411, others off by small amounts | **low** | A-11 |

### opencode-critique-report.md

| # | Lines | Claim | Actual | Severity | Sources |
|---|---|---|---|---|---|
| CR-1 | 1 | "186K 行代码" (title) | Contradicts own "214K" at line 204/229; neither matches total 322K | **high** | M-11, M-35 |
| CR-2 | 179, 188 | Historical debt trend [20, 35, 55, 75, 85, 90, 92, 92.4] | Fabricated; no historical debt data exists | **high** | M-36, A-24 |
| CR-3 | 909–1051 | "真实代码案例" — 4 Effect-TS examples | Fabricated; patterns like `yield* _.promise(Bun.file(...).json())` and `Schema.struct({...})` don't appear in codebase | **high** | A-19 |
| CR-4 | 128, 192, 218, ~12 more | 20 模块 largest SCC | autoresearch says 19; doc itself says 19 in Appendix F (line 2099) — internal inconsistency | **medium** | M-30, A-21 |
| CR-5 | 104 vs 121, 297, 414 | 16 个 >1000 LOC files vs 18 个 | 18 (self-contradictory) | **medium** | M-28, A-26 |
| CR-6 | 824 | processor.ts（1,200 行） | 883 行 (overstated 36%) | **medium** | M-27, A-17 |
| CR-7 | 300, 1969, 2080 | deep nesting 3,693 行 | 3,314 行 | **medium** | M-29 |
| CR-8 | 588 | ts-ignore 15 个 | 63 个 (source: 29) | **medium** | M-32 |
| CR-9 | 1972 vs 197, 2100 | non-null assertions 173 vs 212 | 212 (self-contradictory) | **medium** | M-31 |
| CR-10 | 194, 220, 517, 1517 | 4 patched packages | 7 patches (missing @ai-sdk/xai, gcp-metadata, virtua) | **medium** | M-34 |
| CR-11 | 1027 | 168 Effect.gen 文件, 39% | 139 files, 32% (139/433) | **medium** | A-16 |
| CR-12 | 1028–1030 | 66 Services, 66 Layers | 78 Services, 74 Layers | **medium** | A-15 |
| CR-13 | 434–438 | console 321 any, opencode 335 any | console 326, opencode 319 | **low** | M-43 |
| CR-14 | 303 | 18 TODO/FIXME markers | 16 | **low** | M-33 |

---

## 2. Exact Edit Instructions

### CRITICAL_ANALYSIS.md

**CA-1 — any count (HIGH)**
- Line 170: replace `` `any` 类型：106 处 `` with `` `any` 类型：754 处（493 源码 + 261 测试） ``
- Line 361: replace `106 处 any 类型 | 低-中 | 集中在 SDK 边界` with `754 处 any 类型（493 源码）| 高 | opencode 319, console zen 326, 非仅 SDK 边界`
- Any prose saying `any` is "confined to SDK boundary" must be revised: opencode alone has 319, console zen provider has 326.

**CA-2 — prompt.ts line count (HIGH)**
- Line 123: replace `prompt.ts（2,001 行）` with `prompt.ts（1,780 行）`
- Line 148: replace `session/prompt.ts | 2,001` with `session/prompt.ts | 1,780`

**CA-3 — tool count + fabricated codesearch (HIGH)**
- Line 129: replace `19 个内置工具` with `18 个内置工具`
- Remove "codesearch" from any tool list. No such tool exists in `packages/opencode/src/tool/` and no `codesearch` permission key exists in `config/permission.ts`.
- Replace the tool enumeration with: `read, write, edit, grep, glob, shell, apply_patch, task, question, skill, plan, todowrite, webfetch, websearch, repo_clone, repo_overview, lsp, invalid`

**CA-4 — opencode/src line count (HIGH)**
- Line 15: replace `~107,000 行` with `~85,500 行`

**CA-5 — total line count (HIGH)**
- Line 22: replace `~250,000 行` with `~322,000 行`

**CA-6 — test line count (HIGH)**
- Line 17: replace `~55,000 行测试代码` with `~88,300 行测试代码`

**CA-7 — package count (HIGH)**
- Line 20: replace `16 个包，943 个文件` with `22 个包（含 docs、identity、effect-drizzle-sqlite、extensions、stats）`
- Line 68 heading: replace `20 个 Package 总览` with `22 个 Package 总览`

**CA-8 — commit count (MEDIUM)**
- Line 14: replace `16,025` with `13,478`

**CA-9 — total .ts/.tsx file count (MEDIUM)**
- Line 10: replace `1,736 个 .ts/.tsx 文件` with `2,055 个 .ts/.tsx 文件`
- Line 21: replace `1,739 个 .ts/.tsx 文件` with `2,055 个 .ts/.tsx 文件`

**CA-10 — opencode/src file count (MEDIUM)**
- Line 16: replace `529 个` with `433 个`

**CA-11 — test file count (MEDIUM)**
- Line 17: replace `263 个（含 233 个 .test 文件 + 30 个辅助/fixture）` with `296 个（含 258 个 .test 文件 + 38 个辅助/fixture）`

**CA-12 — Effect import coverage (MEDIUM)**
- Line 88: replace `241 / ~980 (25%)` with `271 / ~433 (63%)`

**CA-13 — compaction.ts (MEDIUM)**
- Line 125: replace `compaction.ts（~300 行）` with `compaction.ts（639 行）`

**CA-14 — session.ts (MEDIUM)**
- Line 117: replace `session.ts（937 行）` with `session.ts（1,012 行）`

**CA-15 — provider counts (MEDIUM)**
- Line 105: replace `22 个 SDK` with `23 个 SDK`
- Line 105: replace `16 个 provider 的特殊处理` with `21 个 provider 的特殊处理`

**CA-16 — LLM package layers (MEDIUM)**
- Line 57: replace `schema/route/protocols/providers 四层分离` with `schema/route/protocols/providers/utils 五层分离`

**CA-17 — beta dependency table (MEDIUM)**
- Lines 199–209: update all version numbers:
  - effect: 4.0.0-beta.59 → 4.0.0-beta.66
  - @effect/opentelemetry: 4.0.0-beta.57 → 4.0.0-beta.66
  - @effect/platform-node: 4.0.0-beta.57 → 4.0.0-beta.66
  - drizzle-kit: 1.0.0-beta.19 → 1.0.0-rc.2
  - drizzle-orm: 1.0.0-beta.19 → 1.0.0-rc.2
  - Add missing: `@effect/sql-sqlite-bun 4.0.0-beta.66`
  - Reclassify drizzle from "beta" to "RC" in the heading/count

**CA-18 through CA-29 (LOW)** — single-value replacements per table above. Apply if editing adjacent lines; not worth a dedicated pass.

### opencode-critique-report.md

**CR-1 — title 186K contradiction (HIGH)**
- Line 1: replace `186K 行代码` with `214K 行代码` (matches the document's own later usage and autoresearch source_lines=214,402; neither 186K nor 214K is total .ts, but 214K is at least internally consistent with the rest of the document)
- Lines 1682, 2116: if they say "186,000", change to "214,000" for internal consistency

**CR-2 — fabricated debt trend (HIGH)**
- Line 179: delete or bracket the fabricated quarterly score array `[20, 35, 55, 75, 85, 90, 92, 92.4]`
- Line 188: replace `2 年内增长了 4.6 倍（从 20 到 92.4）` with a note that no historical trend data exists and the score is a single snapshot
- Alternative: if the trend is kept for rhetorical purposes, add a disclaimer that these are illustrative projections, not measured data

**CR-3 — fabricated code examples (HIGH)**
- Lines 909–1051 (§4.6): change heading from "真实代码案例" to "示意性案例" or equivalent
- Add a note that these examples are illustrative reconstructions, not verbatim source code
- If feasible, replace with actual code snippets from the codebase (e.g., the real config system from `config/config.ts`, the real provider pattern from `provider/provider.ts`)

**CR-4 — SCC 20→19 (MEDIUM)**
- Every occurrence of `20 模块` (~15 locations): replace with `19 模块`
- Line 2099 (Appendix F): already says 19 — no change needed there

**CR-5 — God file count 16→18 (MEDIUM)**
- Line 104: replace `16 个` with `18 个`
- Other locations (121, 297, 414) already say 18 — no change needed

**CR-6 — processor.ts (MEDIUM)**
- Line 824: replace `processor.ts（1,200 行）` with `processor.ts（883 行）`

**CR-7 — deep nesting (MEDIUM)**
- Lines 300, 1969, 2080: replace `3,693` with `3,314`

**CR-8 — ts-ignore count (MEDIUM)**
- Line 588: replace `15 个` with `63 个（源码 29）`

**CR-9 — non-null assertions (MEDIUM)**
- Line 1972: replace `173` with `212`

**CR-10 — patched packages (MEDIUM)**
- Lines 194, 220, 517, 1517–1523: replace `4 个` with `7 个` and add `@ai-sdk/xai`, `gcp-metadata`, `virtua` to the list

**CR-11 — Effect.gen file count (MEDIUM)**
- Line 1027: replace `168 Effect.gen 文件, 39%` with `139 Effect.gen 文件, 32%`

**CR-12 — Effect Service/Layer counts (MEDIUM)**
- Lines 1028–1030: replace `66 Services, 66 Layers, 58 defaultLayers` with `78 Services, 74 Layers, 59 defaultLayers`

**CR-13, CR-14 (LOW)** — apply if editing adjacent lines.

---

## 3. Findings to Leave Unchanged

These were checked and found accurate (or within tolerance):

| Finding | What | Why unchanged |
|---|---|---|
| M-4 | Dev commits: 13,428 | Verified correct |
| A-22 | Dual-write claims (16 TODO(v2), 23 experimentalEventSystem refs, Flag gates) | All confirmed against source |
| A-25 | app-runtime.ts 59 imports | Verified: `grep -c "^import"` → 59 |
| A-27 | normalizeMessages() ~280 lines | Verified: 281 (within ±1) |
| A-28 | variants() ~412 lines | Verified: 413 (within ±1) |
| A-29 | applyCaching() 50 lines | Verified: 50 (initial wrong assessment corrected) |
| A-23 | prompt.ts Effect.gen span ~1,536 lines | Verified: 1637 − 101 + 1 = 1,537 (the gen block itself; file is 1,780 total) |
| A-20 | Effect import line count 245 | Plausible for bare `from "effect"` imports; depends on grep scope, not worth changing |

---

## 4. Unsupported Claims Not Worth Editing

| Claim | Location | Why skip |
|---|---|---|
| `$83,000/year`, `8.25x multiplier`, `9,180 hours over 3 years` | CR lines 131, 188, 248–288 | Derived from assumed hourly rates ($80/hr) and speculative task frequencies. These are clearly rhetorical projections, not factual claims. Editing the model assumptions would be editorial, not factual correction. |
| `20 crash reports`, `11 performance issues` | CR lines 130, 573–577 | Requires live GitHub API; unverifiable offline. Directionally plausible for a project this size. |
| `100+ open issues` | Throughout CR | Requires live GitHub API; unverifiable offline. |
| autoresearch debt score `92.4/100` | autoresearch-report.txt line 100 | Stale by ~2 days. Directionally correct; re-running autoresearch would update it. Not in scope for note edits. |
| Circular dependency SCC details | CR §2.4, §4.1 | Requires `madge` or equivalent; edges are plausible but unverified. The count fix (20→19) is in the edit plan. The specific edge list is left as-is. |
