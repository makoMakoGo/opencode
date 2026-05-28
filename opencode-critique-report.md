# OpenCode 技术债务审计：214K 行代码堆出来的屎山

> 结论先行：OpenCode 不是“没测试的玩具项目”，也不是“每个模块都烂”。它的问题更麻烦：核心路径已经形成一座会继续吞维护成本的屎山。大文件、类型逃逸、v1/v2 双轨、循环依赖、重复块、beta/v0 依赖和失败测试叠在一起，让正确修改变得又慢又危险。
>
> 本报告以 `autoresearch-report.txt` 的自动化指标、仓库源码和已记录的 issue/commit 证据为主体。无法直接证明的夸张类比、成本 ROI、合成代码示例和自相矛盾的旁支结论已删除或收敛。

## 目录

- [1. 综合诊断](#1-综合诊断)
- [2. 最硬的证据](#2-最硬的证据)
- [3. 架构屎山在哪里](#3-架构屎山在哪里)
- [4. 社区与 Git 历史信号](#4-社区与-git-历史信号)
- [5. 测试：不是没有，而是没兜住关键回归](#5-测试不是没有而是没兜住关键回归)
- [6. 依赖与运行时风险](#6-依赖与运行时风险)
- [7. 应该先拆哪里](#7-应该先拆哪里)
- [附录 A. 指标核对表](#附录-a-指标核对表)
- [附录 B. 已删除或降级的旧叙事](#附录-b-已删除或降级的旧叙事)

---

## 1. 综合诊断

| 维度 | 结论 | 证据 |
|---|---|---|
| 核心复杂度 | 严重 | 18 个 >1000 LOC 文件；`session/prompt.ts` 1,780 行、63 个 import；`provider/provider.ts` 1,882 行 |
| 类型债 | 严重 | `any` 总计 754 处，其中源码 493 处、测试 261 处；console 包 326 处，opencode 包 319 处 |
| v1/v2 迁移尾巴 | 严重 | 16 处 `TODO(v2)` dual-write 标记，集中在 `processor.ts` 和 `prompt.ts` |
| 重复与耦合 | 严重 | 647 个重复 8-line blocks，1,418 个实例；循环依赖 SCC 最大 19 模块 |
| 测试健康 | 中高风险 | 2,923 个测试里 11 个失败；5 个 skill discovery 回归；另有 48 个 skip |
| 依赖健康 | 中高风险 | 19 个 v0.x 依赖，7 个 patched packages，Effect/Drizzle 等关键依赖处于 beta/RC 系列 |

一句话：OpenCode 的屎山不是因为“代码多”，而是因为**复杂度集中在最常改、最难测、最容易炸的核心路径上**。

`autoresearch-report.txt` 给出的复合债务评分是 **92.4/100**。这个分数应当被理解为一次自动化快照，而不是数学真理；但它背后的分项并不温和：God files、`any`、dual-write、deep nesting、deprecated markers、test quality、no-test packages 都已经打满或接近打满。

---

## 2. 最硬的证据

### 2.1 大文件不是“职责完整”，而是变更边界失控

| 文件 | 行数 | 问题 |
|---|---:|---|
| `packages/opencode/src/session/prompt.ts` | 1,780 | prompt、tool、compaction、shell、MCP/LSP、subtask、structured output 混在一条核心链路里 |
| `packages/opencode/src/provider/provider.ts` | 1,882 | provider 注册、SDK 加载、自定义 provider 逻辑、模型选择混在一个胶水层里 |
| `packages/opencode/src/provider/transform.ts` | 1,384 | 多 provider message normalization、caching、reasoning variants、schema 修补集中在一起 |
| `packages/opencode/src/lsp/server.ts` | 2,064 | 大量 LSP server 安装/启动配置集中在一个配置型巨文件里 |
| `packages/opencode/src/acp/agent.ts` | 1,966 | ACP 协议实现较大，属于协议复杂度集中 |

行数大本身不是罪。真正的问题是：`prompt.ts` 和 `provider.ts` 不是静态表，也不是单一协议实现，而是核心行为编排层。它们承担的概念太多，导致一个小改动容易碰到多条隐式路径。

### 2.2 `prompt.ts` 是核心上帝文件

`prompt.ts` 的问题不是“1,780 行”这个数字本身，而是它把多个变更理由压进同一个文件：

- system prompt 组装
- tool 定义构建
- 消息历史处理
- 结构化输出
- shell command 路径
- compaction/overflow 路径
- MCP/LSP 引用解析
- subtask 委派
- v1/v2 event dual-write

这种文件是典型屎山核心：新功能绕不开它，bug 修复绕不开它，迁移也绕不开它。只要这个文件继续承担协调之外的具体职责，维护者就会持续在同一个变更热点里踩雷。

### 2.3 `transform.ts` 的自我注释是真实警报

`packages/opencode/src/provider/transform.ts:62` 有真实注释：

```ts
// TODO: fix this stupid inefficient dogshit function
```

这不是整份报告的唯一证据，也不该被反复当核弹用。但它很适合作为症状：维护者已经知道 provider transform 路径难看、低效、难改；代码仍然留在核心路径中。

`transform.ts` 承担的是真复杂度：Anthropic、Bedrock、Claude tool call、Mistral tool id、DeepSeek reasoning、OpenRouter reasoning details、Gemini schema、Moonshot `$ref` 等 provider 差异都在这里汇合。问题不是“这里有分支”，而是这些分支缺少更清楚的 provider-boundary 分层。

### 2.4 `any` 不是局部小问题

自动化统计：

| 指标 | 数值 |
|---|---:|
| `any` 总数 | 754 |
| 源码 `any` | 493 |
| 测试 `any` | 261 |
| opencode 包 | 319 |
| console 包 | 326 |
| console zen provider | 276 |
| `anthropic.ts` | 118 any-uses / 760 行 |

这不是“只有 SDK 边界有一点 any”。console zen provider 和 opencode 核心包都在大量使用 `any`。在 provider 适配层里，外部 API 的动态结构确实会迫使代码处理 unknown shape；但正确做法应该是把不确定性压到 schema/decoder 边界，而不是让 `any` 扩散到业务分支。

`provider/provider.ts` 里 `sdk: any` 的存在可以理解：Vercel AI SDK 和多 provider 加载接口并不总是给出稳定、统一的具体类型。但“可以理解”不等于“没有债”。当核心 provider 抽象靠 `any` 连接，类型系统就无法保护调用者。

### 2.5 v1/v2 dual-write 是迁移失败的尾巴

`TODO(v2)` 共有 16 处，集中在：

| 文件 | 数量 | 含义 |
|---|---:|---|
| `packages/opencode/src/session/processor.ts` | 14 | streaming processor 中多处事件双写 |
| `packages/opencode/src/session/prompt.ts` | 2 | prompt/synthetic message 事件双写 |

典型片段：

```ts
// TODO(v2): Temporary dual-write while migrating session messages to v2 events.
if (flags.experimentalEventSystem) {
  // publish SessionEvent.*
}
```

这类代码的问题不是注释难看，而是它把“旧路径是否仍然需要”和“新路径是否完整”留给每个事件分支自行判断。迁移状态没有单一收敛点，导致维护者在 processor、prompt、compaction、TUI debug flag 等路径之间来回切换。

### 2.6 重复块和循环依赖说明抽象边界没有收住

自动化指标：

| 指标 | 数值 |
|---|---:|
| Duplicate 8-line blocks | 647 |
| Duplicate instances | 1,418 |
| Circular dependency SCCs | 5 |
| Largest SCC | 19 modules |
| Files importing >15 modules | 3 |

重复不是一定要全部消灭；有些重复比错误抽象更安全。但 647 个重复块加上 19 模块 SCC，说明问题不只是“局部 copy-paste”，而是边界没有收住。核心模块互相知道太多，重复逻辑就会自然扩散。

---

## 3. 架构屎山在哪里

### 3.1 Provider 架构：外部复杂度被内部化

多 provider 支持本来就难：不同 API 对 message、tool call、reasoning、schema、caching 的要求都不一样。OpenCode 的问题不是支持 provider 多，而是 provider 差异被塞进少数几个巨大文件中：

- `provider/provider.ts` 管 provider registry、SDK 加载、custom provider 逻辑和 model lookup。
- `provider/transform.ts` 管 message normalization、prompt caching、provider options、reasoning variants、schema patch。
- console zen provider 另有 `anthropic.ts` / `openai.ts` 等高 `any` 密度适配器。

这是一种典型屎山形态：外部世界很脏，内部边界也跟着脏。正确方向不是假装 provider 差异不存在，而是把差异封装在明确的 provider adapter contract 里，让核心路径只处理已经归一化的数据。

### 3.2 Effect-TS：风险在深度绑定和 beta，不是“用了 Effect 就错”

需要收敛旧叙事：不能把“Effect 本身”当成原罪。仓库确实大量使用 Effect，也确实有成熟的 Layer/Service/Runtime 模式；这不是自动错误。

真正的问题是：

| 指标 | 数值 |
|---|---:|
| Effect.gen / yield* files | 188 |
| Effect import files | 271 |
| 关键 Effect 依赖 | 4.0.0-beta.66 系列 |

当一个核心项目在 271 个文件中绑定 Effect，同时关键依赖仍处于 beta 系列，升级、调试和新人理解成本都会被放大。`bridge.ts` 这类 Effect Runtime 与 Node async context 的互操作层可能是必要的；但必要不代表便宜。

所以批评应当精确：**风险不是“Effect 是错的”，而是“深度绑定到 beta Effect，并把核心业务编排写成超大 Effect 链路”**。

### 3.3 Session v1/v2：迁移没有形成干净切口

v1 session files 23 个，v2 session files 1 个。这个比例本身就说明 v2 仍然像附着在旧系统旁边的并行路径，而不是完成切换后的新主干。

16 处 dual-write 标记把迁移债务暴露在 runtime 分支中。只要 `experimentalEventSystem` 还需要在核心 session path 中被反复判断，系统就不是“已经迁移”，而是“迁移状态被摊在业务逻辑里”。

### 3.4 Deprecated 和无测试包是长期尾巴

自动化指标：

| 指标 | 数值 |
|---|---:|
| `@deprecated` markers | 20 |
| packages without tests | 5 |
| no-test packages | `function`, `plugin`, `script`, `slack`, `web` |

Deprecated API 并不一定危险；保留兼容层有时是正确选择。但当 deprecated markers、dual-write、v0 依赖和大文件同时存在时，它们共同指向同一个问题：旧路径下不去，新路径收不拢。

---

## 4. 社区与 Git 历史信号

### 4.1 真实 issue 指向可靠性和迁移问题

报告引用的 issue 集中在几类问题：

| 类别 | 代表 issue | 信号 |
|---|---|---|
| 长会话崩溃 / OOM | #22883 | 长 session 下内存风险 |
| WSL2 crash | #28830 | runtime/listener 路径可靠性问题 |
| AbortError sidecar crash | #26667 | streaming interruption 没有在边界被稳妥吸收 |
| Edit tool Python indentation corruption | #25953 | 工具成功返回但文件内容错误，属于高严重度数据损坏信号 |
| 并发 plugin config 删除 | #16450 | 并发安装/配置路径有数据丢失风险 |
| skill discovery symlink | #27027 / #27638 | 文件系统遍历策略在慢盘/循环链接下失控 |
| V2 prompt controls regression | #28686 / #29051 | v2 UI 迁移缺功能 |
| config modularization requests | #19353 / #9062 / #28600 | 配置复杂度外溢到用户 |

这些 issue 不证明“每个用户都受影响”，但足以证明核心功能路径存在真实痛点：崩溃、性能、数据损坏、配置复杂、v2 回归。

### 4.2 Issue 堆积：不是随机 bug，是几个热点一直外溢

GitHub open issue 搜索显示，问题并不是平均撒在整个仓库里，而是反复堆在少数核心热点上。本次查询每类最多取前 20 条结果；命中 20 条表示该类至少有 20 条当前 open issue 可作为样本。

| 热点 | 当前 open issue 证据 | 暴露的结构问题 |
|---|---|---|
| crash / OOM / WSL2 / sidecar | 查询前 20 条包括 #26667、#22883、#28830、#26669、#29682、#28984、#29177、#23698 | session、desktop renderer、sidecar、runtime listener 和内存生命周期边界没有被压成稳定层 |
| skill discovery / symlink | 查询前 20 条包括 #27638、#27027、#29437、#18848、#16188、#25686、#26478 | 文件系统遍历、symlink 策略、REST/TUI skill 可见性没有统一语义 |
| v2 / prompt / reasoning | 查询前 20 条包括 #29051、#28686、#29595、#29184、#28769、#28716、#28623、#19081 | v2 UI、reasoning metadata、prompt replay、provider thinking 模板仍在同一迁移泥潭里 |
| config / state / paths | 查询前 20 条包括 #9062、#28600、#26051、#10133、#20940、#28733、#28966、#27786 | 配置加载、优先级、路径解析、持久状态位置对用户和插件都不稳定 |
| edit / corruption / data loss | 查询前 20 条包括 #25953、#29573、#14970、#24959、#24742、#14612、#17949 | “工具调用成功”和“磁盘结果正确”之间缺少强校验；文件编辑 fallback 太容易把局部失败放大成数据损坏 |

这就是 bug 修不干净的工程含义：不是没人提交 patch，而是修复点散落在上帝文件、dual-write 分支、provider transform、runtime 文件系统边界和桌面 sidecar 之间。每个 issue 看起来都能局部修，修完却没有把热点收敛成更小、更硬的边界，于是同类问题继续以新标题出现。

### 4.3 长期开着的老问题说明 backlog 不是短期尖峰

这些 open issue 里还有一批创建于 2026 年 1–3 月、到 5 月底仍未关闭的老问题：

| Issue | 创建时间 | 主题 |
|---|---|---|
| #9062 | 2026-01-17 | `config.d/` modular configuration |
| #10133 | 2026-01-23 | unified configuration structure |
| #10986 | 2026-01-28 | standard skills location `.agents/skills/` |
| #11145 | 2026-01-29 | WSL2 TUI freeze |
| #14612 | 2026-02-21 | edit tool indentation corruption not shown in diff |
| #14970 | 2026-02-24 | SQLite database corruption on concurrent NFS sessions |
| #16188 | 2026-03-05 | startup hang/high CPU with skill symlink cycle |
| #17949 | 2026-03-17 | destructive file deletion guardrails |
| #18132 | 2026-03-18 | WSL2 TUI freeze / SIGILL |
| #18432 | 2026-03-20 | Windows directory corruption / junction loops |
| #18848 | 2026-03-23 | project-level skills not discovered through symlink |
| #19081 | 2026-03-25 | reasoning content stripped on replay |

这些不是“昨天刚报、还没来得及处理”的噪声。配置、skills、WSL2、edit/data corruption、session replay 这些主题跨月存在，和代码里的 dual-write、provider transform、filesystem traversal、config path 边界互相印证：屎山的核心特征不是 bug 多，而是同类 bug 会换个入口继续回来。

### 4.4 Git 历史暴露维护摩擦

`transform.ts` 的注释来自 commit `6409aceb1`（PR #25934: `fix: sanitize surrogates`）。这条证据成立，但不应被重复使用成整份报告的唯一支柱。

更值得关注的是同一类维护信号：

- 同一功能出现 revert / reapply 循环。
- 存在 `wip` / `sync` / `events` / `cleanup` 等信息量低的 commit message。
- provider transform 和 session migration 这类核心路径依然有显性 TODO。

这些信号不能单独判死刑，但和代码结构指标叠加后，说明维护者已经在复杂度里反复付成本。

### 4.5 仓库身份叙事收敛

`anomalyco/opencode` 是当前公开仓库，GitHub 显示不是派生仓库；`sst/opencode` 相关访问会指向当前仓库身份。报告不再使用“某方接手派生仓库”这一叙事。这里的批评对象就是当前 OpenCode 代码库本身。

---

## 5. 测试：不是没有，而是没兜住关键回归

旧叙事里把测试资产一笔抹黑的说法不准确，应该删掉。OpenCode 有相当规模的测试资产：

| 指标 | 数值 |
|---|---:|
| Test files | 408 |
| Test lines | 107,212 |
| Test/source ratio | 0.35 |
| Total tests | 2,923 |
| Passing rate | 99.6% |
| Failed tests | 11 |
| Skipped tests | 48 |

测试不是没有。问题是：**有测试，仍然有关键路径失败和回归**。

`autoresearch-report.txt` 记录的失败分布：

| 包 | 测试数 | 失败 | 说明 |
|---|---:|---:|---|
| opencode | 2,621 | 8 | 5 个 skill discovery、1 个 HTTP workspace proxy、2 个 provider HttpApi OAuth |
| llm | 217 | 3 | OpenAI route 缺 `OPENAI_API_KEY`，更像环境/auth schema 问题 |
| core | 85 | 0 | 通过 |

最危险的是 5 个 skill discovery 失败：`all()` 返回 0，期望 1-2。结合 symlink/slow filesystem/circular link 的 issue，这不是“测试小毛刺”，而是用户能直接感知的启动和发现路径风险。

正确批评不是“OpenCode 没测试”，而是：

1. 测试资产不少，但测试/source 比仍只有 0.35。
2. 关键路径仍有失败测试。
3. 48 个 skip 是潜在技术债。
4. 测试没有阻止 v2 UI、skill discovery、edit corruption 等用户可见回归进入主线。

这比“没有测试”更糟糕：团队已经投入了测试成本，但复杂度仍然从缝里漏出来。

---

## 6. 依赖与运行时风险

自动化指标：

| 指标 | 数值 |
|---|---:|
| Total unique deps | 219 |
| v0.x unstable deps | 19 |
| Ranged version deps | 22 |
| Patched packages | 7 |

patched packages 包括：

- `@ai-sdk/xai`
- `@silvia-odwyer/photon-node`
- `gcp-metadata`
- `virtua`
- `@npmcli/agent`
- `@standard-community/standard-openapi`
- `solid-js`

补丁包不是一定错误；有时它是工程上唯一可行的修复方式。但 7 个补丁包 + 19 个 v0.x 依赖 + beta/RC 核心依赖组合在一起，意味着项目不仅要维护自己的屎山，还要维护一部分上游生态的不稳定性。

---

## 7. 应该先拆哪里

### P0：收掉 v1/v2 dual-write

目标：让 session event 迁移有一个主路径，而不是在 `processor.ts` 和 `prompt.ts` 的分支里继续扩散。

验收标准应当是：

- 删除 16 处 `TODO(v2)` dual-write 标记。
- `experimentalEventSystem` 不再是核心 session processor 的常规分支条件。
- 相关 prompt、processor、compaction、TUI debug 路径有明确 owner 和测试覆盖。

### P1：把 provider 差异压回 adapter 边界

目标：减少 `provider/transform.ts` 和 console zen provider 的 `any` 扩散。

优先路径：

- 为 console zen `anthropic.ts` / `openai.ts` 的外部响应建立 decoder/schema 边界。
- 明确 provider-normalized message 的内部形态。
- 让 provider-specific quirks 停留在 adapter 内，不继续污染 core transform path。

### P2：拆 `prompt.ts` 的职责，而不是机械按行数切文件

目标不是“1,780 行变成几个小文件”这种表面工程，而是切出真正的变更边界：

- prompt input resolution
- tool definition/building
- message preparation
- compaction/overflow handling
- shell command path
- subtask delegation
- event publishing boundary

拆分后，新增 tool、修改 provider message、调整 compaction、处理 session event 不应都回到同一个文件里改。

### P3：处理重复块和循环依赖

在 P0/P1/P2 之后再处理重复和 SCC。否则容易把屎山里的重复抽成另一个更难懂的屎山抽象。

优先处理跨文件重复和高 fan-in 模块；文件内重复可以等行为边界稳定后再清。

---

## 附录 A. 指标核对表

| 指标 | 当前报告采用值 | 来源 |
|---|---:|---|
| Source files | 1,154 | `autoresearch-report.txt` |
| Test files | 408 | `autoresearch-report.txt` |
| Source lines | 214,402 | `autoresearch-report.txt` |
| Test lines | 107,212 | `autoresearch-report.txt` |
| Test/source ratio | 0.35 | `autoresearch-report.txt` |
| Files >500 LOC | 59 | `autoresearch-report.txt` |
| Files >1000 LOC | 18 | `autoresearch-report.txt` |
| Duplicate blocks | 647 | `autoresearch-report.txt` |
| Duplicate instances | 1,418 | `autoresearch-report.txt` |
| `any` total | 754 | `autoresearch-report.txt` |
| `any` source | 493 | `autoresearch-report.txt` |
| `any` test | 261 | `autoresearch-report.txt` |
| `@ts-ignore` / `@ts-expect-error` | 63 | `autoresearch-report.txt` |
| `catch(e: any)` | 11 | `autoresearch-report.txt` |
| TODO/FIXME/HACK real | 16 | `autoresearch-report.txt` |
| Dual-write markers | 16 | `autoresearch-report.txt` + source search |
| `@deprecated` markers | 20 | `autoresearch-report.txt` |
| Effect.gen / yield* files | 188 | `autoresearch-report.txt` |
| Effect import files | 271 | `autoresearch-report.txt` |
| Deep nesting lines | 3,314 | `autoresearch-report.txt` |
| Circular dependency SCCs | 5 | `autoresearch-report.txt` |
| Largest SCC | 19 modules | `autoresearch-report.txt` |
| Fragile tests | 5 | `autoresearch-report.txt` |
| Giant test files | 17 | `autoresearch-report.txt` |
| Total tests | 2,923 | `autoresearch-report.txt` |
| Failed tests | 11 | `autoresearch-report.txt` |
| Pass rate | 99.6% | `autoresearch-report.txt` |
| v0.x unstable deps | 19 | `autoresearch-report.txt` |
| Patched packages | 7 | `autoresearch-report.txt` |
| Non-null assertions | 212 | `autoresearch-report.txt` |
| Composite debt score | 92.4/100 | `autoresearch-report.txt` |

---

## 附录 B. 已删除或降级的旧叙事

| 旧叙事 | 处理 |
|---|---|
| 抹黑测试资产 | 删除。改为“测试资产不少，但关键回归仍失败”。 |
| 把空 catch 当系统性灾难 | 删除。11 处 `catch(e: any)` 可作为类型债指标，但不再当核心控诉。 |
| 把 Effect 本身当原罪 | 降级。改为“深度绑定 beta Effect + 超大 Effect 编排链路带来风险”。 |
| 合成的 Effect 示例 | 删除。不再把示意代码伪装成技术深挖证据。 |
| 无来源的自建 agent 基线和倍数比较 | 删除。无可靠基线。 |
| 无算式的成本/ROI 叙事 | 删除。无可核验计算模型。 |
| 人身化贬损类比 | 删除。情绪判断没有工程基线。 |
| 仓库派生/接手叙事 | 删除。当前报告只批评当前 OpenCode 代码库。 |
| 反复引用 `dogshit` 注释 | 收敛为一次证据。它是症状，不是唯一判决。 |

最终判断不变：OpenCode 是一座真实的技术债屎山。修订后的报告只是把不诚信的夸张删掉，让剩下的批评更难反驳。
