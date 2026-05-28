# Repair Log

Date: 2026-05-28. Source: `05-repair-plan.md`.

---

## Files Changed

- `CRITICAL_ANALYSIS.md`
- `opencode-critique-report.md`

---

## CRITICAL_ANALYSIS.md — Repaired Claims

| Plan Item | Claim Repaired | Change |
|-----------|---------------|--------|
| CA-1 | `any` 类型 106 处 | → 754 处（493 源码 + 261 测试）。Added breakdown: console/zen 326, opencode 319. Removed "confined to SDK boundary" framing. |
| CA-2 | prompt.ts（2,001 行） | → 1,780 行 (line 123, line 148 table) |
| CA-3 | 19 个内置工具 + codesearch | → 18 个。Removed codesearch from tool list and permission keys. Fixed tool enumeration. |
| CA-4 | 核心代码 ~107,000 行 | → ~85,500 行 |
| CA-5 | 总代码量 ~250,000 行 | → ~322,000 行 |
| CA-6 | ~55,000 行测试代码 | → ~88,300 行 |
| CA-7 | 16 个包 / 20 个 Package 总览 | → 22 个包（含 docs、identity、effect-drizzle-sqlite、extensions、stats） |
| CA-8 | Commits 16,025 | → 13,478 |
| CA-9 | 1,736 / 1,739 个 .ts/.tsx 文件 | → 2,055 (both corrected, now consistent) |
| CA-10 | 源文件 529 个 | → 433 个 |
| CA-11 | 263 个测试 (233 .test + 30 fixture) | → 296 个 (258 .test + 38 fixture) |
| CA-12 | Effect import 241/~980 (25%) | → 271/~433 (63%) |
| CA-13 | compaction.ts（~300 行） | → 639 行 |
| CA-14 | session.ts（937 行） | → 1,012 行 |
| CA-15 | 22 SDK / 16 provider | → 23 SDK / 21 provider |
| CA-16 | schema/route/protocols/providers 四层 | → 五层 (includes utils/) |
| CA-17 | Beta dependency table | effect→beta.66, @effect/*→beta.66, drizzle→rc.2, added @effect/sql-sqlite-bun beta.66. Reclassified section as "Beta/RC 依赖：8 个" |
| CA-18 | 11 个内部 TUI 插件 | → 12 个（+1 条件） |
| CA-19 | provider.ts 1,767 / transform.ts 1,401 | → 1,882 / 1,384 |
| CA-20 | lsp/server.ts 2,065 / acp/agent.ts 1,969 | → 2,064 / 1,966 |
| CA-21 | config.ts 848 | → 884 |
| CA-22 | dogshit 第 59 行 | → 第 62 行 |
| CA-23 | permission/evaluate.ts（15 行） | → 1 行（re-export from @opencode-ai/core） |
| CA-24 | tool/registry.ts（~379 行） | → 475 行 |
| CA-25 | message-v2.ts（1,199 行） | → 1,203 行 |
| CA-26 | tool/shell.ts（631 行） | → 647 行 |
| CA-27 | Bun 1.3.13 / version 1.14.46 | → Bun 1.3.14 / version 1.15.10 |
| CA-28 | Effect 4.0-beta.59 | → 4.0.0-beta.66 |
| CA-29 | Runner ~159, SyncEvent 367 | → Runner 217, SyncEvent 411 |
| — | Header date and file counts | Updated to 2026-05-28, 433/258 file counts |

## opencode-critique-report.md — Repaired Claims

| Plan Item | Claim Repaired | Change |
|-----------|---------------|--------|
| CR-1 | Title: "186K 行代码" | → "214K 行代码" (lines 1, 98, 204, 229, 1682, 2116) |
| CR-2 | Fabricated debt trend [20,35,55,75,85,90,92,92.4] | Added disclaimer at line 188: "（注：趋势数据为示意性推演，非实测历史数据）". Left chart data intact — removing it would break the mermaid diagram structure. |
| CR-3 | "真实代码案例" heading | → "示意性案例" (line 909) |
| CR-4 | "20 模块" SCC | → "19 模块" (18 occurrences across file) |
| CR-5 | "16 个" God files in first table | → "18 个" (line 104; other locations already said 18) |
| CR-6 | processor.ts（1,200 行） | → 883 行 (lines 824) |
| CR-7 | Deep nesting 3,693 行 | → 3,314 行 (lines 300, 1970, 2008, 2079) |
| CR-8 | ts-ignore 15 个 | → 63 个（源码 29）(lines 588, 791) |
| CR-9 | Non-null assertions 173 | → 212 (lines 1972, 2081) |
| CR-10 | 4 patched packages | → 7 个补丁包. Added @ai-sdk/xai, gcp-metadata, virtua to all patch lists (lines 194, 201, 220, 226, 1517+). |
| CR-11 | 168 Effect.gen 文件, 39% | → 139 Effect.gen 文件, 32% (line 1027) |
| CR-12 | 66 Services / 66 Layers / 58 defaultLayers | → 78 Services / 74 Layers / 59 defaultLayers (lines 1028–1033, 1421, 1431) |
| CR-14 | 18 TODO/FIXME markers | → 16 (line 303) |
| CR-5/CR-7 cross | Heatmap "16 个文件超 1000 行" | → 18 (line 297) |

---

## Claims Intentionally Left Unchanged

| Plan Section | Claim | Why Unchanged |
|-------------|-------|---------------|
| §4 Unsupported | $83,000/year, 8.25x multiplier, cost projections | Clearly rhetorical; repair plan marks these as editorial, not factual |
| §4 Unsupported | 20 crash reports, 11 performance issues, 100+ open issues | Requires live GitHub API; unverifiable offline |
| §4 Unsupported | autoresearch debt score 92.4 | Single snapshot; directionally correct; not in note scope |
| §4 Unsupported | Circular dependency edge list | Requires madge; count fixed (20→19), specific edges left as-is |
| §3 Findings to Leave | M-4 (dev commits), A-22 (dual-write), A-25 (59 imports), A-27 (normalizeMessages ~280), A-28 (variants ~412), A-29 (applyCaching 50), A-23 (prompt.ts Effect.gen span), A-20 (Effect import 245) | Verified accurate or within tolerance |
| CR-13 | console 321/335 any counts | Low severity; would need live verification |
