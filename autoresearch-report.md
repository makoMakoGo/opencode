# OpenCode 技术债务分析报告

> 生成日期: 2026-05-11  
> 基线分支: autoresearch/opencode-20260511  
> 复合债务评分: **93.2 / 100** (0=无债务, 100=最高债务)  
> 分析范围: 20 个包, 987 源文件, ~186K 行源码

---

## 1. 执行摘要

OpenCode 是一个 ~186K 行 TypeScript 单仓项目，包含 20 个包。核心包 `packages/opencode` 有 434 个源文件、227 个测试文件。项目正在经历两场并行架构迁移：传统 async/await → Effect-TS（几乎完成）和 session 层 v1→v2 事件系统（进行中，15 处双写标记）。

### 债务热力图

| 债务维度 | 严重度 | 得分 | 影响范围 |
|----------|--------|------|----------|
| 巨型文件 (>1000 LOC) | 🔴 高 | 15.0/15 | 16 个文件超 1000 行 |
| `any` 类型泛滥 | 🔴 高 | 15.0/15 | 717 处，zen provider 占 273 |
| v1/v2 session 双写 | 🔴 高 | 15.0/15 | processor.ts, prompt.ts |
| 深层嵌套 (>4 级缩进) | 🟡 中 | 10.0/10 | 3,693 行 |
| 已废弃 API | 🟡 中 | 10.0/10 | 19 个 @deprecated |
| 测试质量 | 🟡 中 | 10.0/10 | 5 个脆弱测试，16 个巨型测试 |
| TODO/FIXME 标记 | 🟢 低 | 7.2/10 | 18 个真实标记 |
| 模块耦合 | 🟢 低 | 6.0/10 | 3 个高耦合文件 |
| 无测试包 | 🟢 低 | 5.0/5 | 5 个包 |

**关键结论**: 93.2 分中 45 分来自三个满分维度（巨型文件、any 泛滥、v2 双写），集中解决这三个问题可将评分降至 ~48。

---

## 2. 量化指标

### 2.1 规模

| 指标 | 数值 |
|------|------|
| 源文件 | 987 |
| 测试文件 | 329 |
| 测试/源文件比 | 0.33 |
| 源码行数 | 185,865 |
| 测试行数 | 87,502 |
| 依赖数量 | 76 (packages/opencode) |
| Lock 文件大小 | 887 KB |

### 2.2 巨型文件 (God Files)

**16 个文件超过 1000 行**（排除生成代码和 i18n），最严重的：

| 文件 | 行数 | 导入数 | 深嵌套行 | 描述 |
|------|------|--------|---------|------|
| `session/prompt.ts` | 2,101 | 63 | 406 | 1,822 行 Effect.gen |
| `lsp/server.ts` | 2,064 | — | — | LSP 服务器 |
| `acp/agent.ts` | 1,969 | — | 265 | ACP 代理 |
| `provider/sdk/copilot/responses/...ts` | 1,770 | — | 429 | Copilot SDK 适配器 |
| `provider/provider.ts` | 1,767 | 31 | 141 | 提供者注册 |
| `cli/cmd/github.ts` | 1,643 | — | — | GitHub CLI |
| `cli/cmd/run/tool.ts` | 1,460 | — | — | Run tool |
| `provider/transform.ts` | 1,400 | — | — | 消息转换（含自贬注释） |

`prompt.ts` 以 63 个 import 成为耦合最严重的文件，其 Effect.gen 跨越 1,822 行（占文件的 87%）。

### 2.3 类型安全

| 指标 | 数量 |
|------|------|
| `any` 类型使用（排除生成代码） | **717** |
| 其中：**源码** | **449** |
| 其中：测试 | 268 |
| `@ts-ignore` / `@ts-expect-error` | 48 |
| `catch(e: any)` | 13 |

449 处生产代码中的 `any` 是真正的风险。按包分布：

| 包 | 源码 `any` | 说明 |
|----|----------|------|
| console | **321** | 273 在 zen provider 的 3 个文件 |
| opencode | **71** | provider.ts (18), copilot.ts (10), transform.ts (7) 等 |
| core | 20 | log.ts (11, 基础设施), effect-zod.ts (4, Effect 内部) |
| sdk | 13 | client.gen.ts (5, 生成代码), 其余散布 |
| plugin | 8 | 插件加载 API |

**console 包 3 个文件贡献了全部源码 `any` 的 61%**。修复这 3 个文件可将源码 `any` 从 449 降至 176（-61%）。

**源码 `any` 密度最高的文件（Top 5，排除测试）：**

| 文件 | `any` | 说明 |
|------|-------|------|
| `console/.../provider/openai.ts` | 123 | OpenAI 请求格式转换 |
| `console/.../provider/anthropic.ts` | 117 | Anthropic 请求格式转换 |
| `console/.../provider/openai-compatible.ts` | 33 | 兼容层 |
| `opencode/src/provider/provider.ts` | 18 | 自定义提供者加载 |
| `opencode/src/plugin/github-copilot/copilot.ts` | 10 | Copilot 插件适配 |


**`@ts-ignore`/`@ts-expect-error` 分析**（48 处总计，其中 **30 处在源码中**）：
- 10 处有明确说明（外部 API 类型缺失：npm、bun、ai-sdk、构建生成文件）
- 10 处**无说明的 `@ts-ignore`**（`prompt.ts`, `watcher.ts`, `resource.node.ts`, `user.ts`, `auth.ts` 等）——这些比 `@ts-expect-error` 更危险
- 18 处在 llm 测试 `.types.ts` 中（刻意的负向类型测试，非债务）
- 4 处在其他测试文件中
- 6 处在 SDK 生成/客户端/脚本代码中

无说明的 `@ts-ignore` 没有 `@ts-expect-error` 的自清理特性：类型修复后不会报错提醒。`console/resource/resource.node.ts` 一个文件就有 3 处无说明的 `@ts-ignore`。

**`@ts-nocheck`**（禁用整个文件类型检查，2 处）：
- `packages/opencode/specs/v2/api.ts`（67 行）：SDK 使用示例。**作为公开 API 文档，应保证类型正确**——`@ts-nocheck` 意味着示例可能已经类型失效。
- `packages/console/mail/emails/styles.ts`（91 行）：邮件样式常量，低风险，但应改为 `@ts-expect-error`。
### 2.4 迁移标记

| 标记类型 | 数量 |
|----------|------|
| TODO/FIXME/HACK（真实代码） | 18 |
| `TODO(v2)` 双写迁移 | **15** |
| `@deprecated` 标记 | 19 |

**v1/v2 双写是最紧迫的债务**。`Flag.OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` 在 4 个文件中共有 **20 处引用**（processor.ts 13 处, prompt.ts 2 处, compaction.ts 2 处, cli/tui 1 处），其中 15 处标记了 `TODO(v2)`：

```typescript
// TODO(v2): Temporary dual-write while migrating session messages to v2 events.
if (Flag.OPENCODE_EXPERIMENTAL_EVENT_SYSTEM) {
  yield* sync.run(SessionEvent.Reasoning.Started.Sync, { ... })
}
// ... 然后是 v1 写入路径
```

**影响**: 每个 bug fix 必须同步修改 v1 和 v2 两条路径。影响范围涵盖 processor、prompt、compaction 和 TUI 插件系统。

### 2.5 Effect 迁移

| 指标 | 数值 |
|------|------|
| 总源文件 | 434 |
| 导入 effect 包的文件 | 241 (55%) |
| 使用 Effect.gen/yield* 的文件 | 168 (39%) |

Effect 迁移覆盖了核心业务逻辑层（session、provider、project、storage、bus）。未迁移的 193 个文件主要是：
- **util 辅助函数**（26 个）：`lock.ts`, `process.ts`, `timeout.ts` 等基础设施，不涉及业务逻辑
- **CLI 命令层**（39 个）：TUI 渲染、命令处理等边界代码
- **SDK 适配器**（22 个）：Copilot/OpenAI SDK 的 `external API` 封装
- **config 解析器**（6 个）：配置文件读取
- **其他**：plugin 加载、LSP 客户端等边界层

66 个 Service 声明、66 个 Layer.effect、58 个 defaultLayer，形成了完整的依赖注入体系。核心 Effect 迁移已完成，剩余文件属于合理的边界层。

### 2.6 模块耦合

**高耦合文件**（导入 >15 个本地模块）：

| 文件 | 导入数 | 角色 |
|------|--------|------|
| `effect/app-runtime.ts` | 50 | 全局依赖注入组装点 |
| `session/prompt.ts` | 23 | Session 核心路径 |
| `control-plane/workspace.ts` | 19 | 控制面交互 |

**高扇入模块**（被最多文件依赖）：

| 模块 | 被依赖次数 |
|------|-----------|
| util | 123 |
| effect | 101 |
| session | 85 |
| config | 60 |
| provider | 51 |

`app-runtime.ts` 作为全局组装点，50 个导入是合理的（它负责将所有 Layer 连接在一起）。`prompt.ts` 的 23 个导入则表明它承担了过多职责。

### 2.7 测试质量

| 指标 | 数量 |
|------|------|
| 脆弱测试（>10 次 any） | **5** |
| 巨型测试（>1000 行） | **16** |

**脆弱测试**（使用 `any` 绕过类型检查）：

| 文件 | any 次数 |
|------|---------|
| `test/provider/transform.test.ts` | 111 |
| `test/acp/event-subscription.test.ts` | 35 |
| `test/util/effect-zod.test.ts` | 28 |
| `test/mcp/lifecycle.test.ts` | 12 |
| `test/lsp/client.test.ts` | 12 |

**巨型测试文件**（>1000 行）：

| 文件 | 行数 |
|------|------|
| `test/provider/transform.test.ts` | 3,688 |
| `test/provider/provider.test.ts` | 2,617 |
| `test/config/config.test.ts` | 2,570 |
| `test/session/prompt.test.ts` | 2,171 |
| `test/session/compaction.test.ts` | 1,856 |

`transform.test.ts`（3,688 行，111 次 any）是最大的测试文件，也是 `any` 使用最多的测试。这暗示测试在复制而非调用被测代码的逻辑。

**运行时验证**（`bun test --no-preload`，2026-05-11）：

| 包 | 测试数 | 失败 | 跳过 | 通过率 |
|----|--------|------|------|--------|
| opencode | 2,621 | 8 | 20 | 99.7% |
| llm | 217 | 3 | 28 | 98.6% |
| core | 85 | 0 | 0 | 100% |
| **合计** | **2,923** | **11** | 48 | **99.6%** |

**opencode 8 个失败**：
- 5 个 skill discovery：`.claude/skills/` 和 `.agents/skills/` 目录扫描返回 0 结果（期望 1-2）。**疑似回归**——发现代码变更后测试未同步。
- 1 个 HTTP workspace proxy：超时测试，预期返回 500 但收到其他状态码。
- 2 个 provider HttpApi OAuth 测试。

**llm 3 个失败**：全部因缺少 `OPENAI_API_KEY` 环境变量导致 auth schema 校验失败。**非回归**——测试基础设施问题，需要 mock auth 层。

99.6% 的通过率表明测试套件整体健康。但 llm 的 auth mock 缺失和 opencode 的 skill discovery 回归是具体需要修复的问题。

### 2.8 包级别债务热力图

| 包 | 源文件 | 测试 | `any` | TODO | @deprecated | 巨型文件 | ts-ignore |
|----|--------|------|-------|------|-------------|---------|-----------|
| **opencode** | 434 | 227 | **335** | **16** | 8 | **41** | 16 |
| **console** | 104 | 3 | **321** | 0 | 0 | 6 | 8 |
| llm | 52 | 25 | 0 | 0 | 0 | 6 | 18 |
| app | 93 | 56 | 3 | 0 | 0 | 4 | 1 |
| ui | 45 | 5 | 2 | 0 | 0 | 3 | 0 |
| core | 31 | 8 | 20 | 0 | 0 | 2 | 2 |
| desktop | 35 | 2 | 2 | 0 | 0 | 1 | 0 |
| plugin | 6 | 0 | 8 | 0 | **11** | 2 | 1 |
| http-recorder | 9 | 1 | 0 | 0 | 0 | 1 | 0 |
| enterprise | 3 | 2 | 3 | 0 | 0 | 1 | 0 |
| sdk | 92 gen | 0 | 13 | 2 | 0 | 1 | 4 |

**关键发现**:

- **console 包的 `any` 密度是 opencode 的 4.4 倍**（321/104 vs 335/434），几乎全部集中在 zen provider 的 3 个文件中
- **opencode 包是唯一的 TODO 来源**（16/18），双写迁移和 provider 层注释全在此包
- **plugin 包的 11 个 @deprecated 是唯一来源**——废弃的 TUI 插件 API
- **llm 包 18 个 ts-ignore** 全部在类型测试文件（`auth-options.types.ts`, `provider.types.ts`）中——这些是**刻意编写的负向类型测试**，验证错误类型被拒绝。不是债务，而是良好的类型安全实践。
- **core 包 20 次 `any`** 主要在 `log.ts`（日志接口，本质上是 `any` 类型的）和 `effect-zod.ts`（Effect 内部交互）。属于基础设施层面，难以避免。

- **app 包有 182 个非空断言 (`!`)**, opencode 有 57 个，是另一类类型安全隐患
### 2.9 测试覆盖盲区

**5 个包有源代码但完全没有测试：**

| 包 | 源文件数 | 风险 |
|----|---------|------|
| plugin | 6 | 高 — 插件加载核心路径 |
| web | 4 | 中 — 静态网站 |
| function | 1 | 低 |
| slack | 1 | 低 |
| script | 1 | 低 |

### 2.10 已废弃 API

19 个 `@deprecated` 标记：
- **config**: 4 个废弃字段（`share`, `agent`, `maxSteps`, `layout`）
- **plugin TUI API**: 10+ 个废弃方法（`registerKeymap`, `dispatchCommand` 等）
- **session**: 2 个废弃字段（tool/permissions 合并）

---

## 3. 关键债务领域详细分析

### 3.1 Console 包——类型安全黑洞

**位置**: `packages/console/app/src/routes/zen/util/provider/` (5 个 provider 文件 + handler.ts)
**规模**: console 包总计 321 次 `any`，其中 zen provider 目录占 277 次

| 文件 | 行数 | `any` 次数 | 角色 |
|------|------|-----------|------|
| openai.ts | 760 | 123 | OpenAI 格式转换 |
| anthropic.ts | 759 | 117 | Anthropic 格式转换 |
| openai-compatible.ts | 502 | 33 | 通用兼容层 |
| provider.ts | 184 | 4 | 路由分发 |
| google.ts | 46 | 0 | Google 格式（已类型化） |
| handler.ts | 1,132 | 4 | 请求处理 + 流式响应 |

三个核心适配器（openai.ts, anthropic.ts, openai-compatible.ts）占 273 次 `any`，在不同 LLM API 格式间做转换，但**没有为外部 API 定义类型接口**：

```typescript
if ((s as any).type !== "text") continue
if (typeof (s as any).text !== "string") continue
msgs.push({ role: "system", content: (s as any).text })
```

**console 包的 `any` 密度为 3.1 次/源文件**，是 opencode 包（0.77 次/源文件）的 **4 倍**。`google.ts` 有 0 次 `any`，说明类型化转换是可行的。

**影响**: Anthropic/OpenAI API 变更时无编译期错误。生产环境只在请求失败时暴露。

**建议**: 参考 `google.ts`（0 次 `any`）的模式，为 Anthropic 和 OpenAI API 定义 Zod schema，用 `Schema.decodeUnknown` 在边界处验证。这可消除 console 包 ~85% 的 `any`。

### 3.2 Session v1/v2 双写——未完成的迁移

**位置**: `processor.ts` (13 处), `prompt.ts` (2 处), `compaction.ts` (2 处), `cli/tui/plugin/internal.ts` (1 处)
**规模**: 15 处 `TODO(v2)` 标记 + 20 处 `Flag.OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` 引用

v2 架构（`packages/opencode/src/v2/`，10 个文件）与 v1 session（20 个文件）并存。影响范围超出 `processor.ts`：
- `compaction.ts` 有 2 处未标记 `TODO(v2)` 但使用同一 flag 的双写逻辑
- `cli/tui/plugin/internal.ts` 根据 flag 决定是否加载 `SessionV2Debug` 组件
- 共 **4 个文件** 依赖此 flag，不是报告前面提到的 2 个

**影响**:
- `processor.ts` 每个 case 分支增长约 30%
- `Flag.OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` 在 4 个文件中有 20 处引用——这是一个全局分支点
- 所有 bug fix 必须同步 v1 和 v2 两条路径

**建议**: 将 v2 event system 作为唯一路径，批量移除 v1 写入代码、flag 及其全部 20 处引用。

### 3.3 Provider 层——混合架构

**位置**: `packages/opencode/src/provider/`  
**规模**: provider.ts (1,767 行), transform.ts (1,400 行), copilot SDK (1,770 行)

三个问题叠加：

1. **`provider.ts`**: 模型发现、SDK 加载、自定义提供者注册、Azure 适配全在一个文件。`custom()` 函数跨越 685 行（150–835）。

2. **`transform.ts`**: 注释自述 `// TODO: fix this stupid inefficient dogshit function`。消息标准化是一个隐式的多态调度器，未被结构化为策略模式。

3. **Copilot SDK 适配器**: 429 行超过 4 级缩进（24%），大量重复的 case 分支。

**建议**:
- `provider.ts` → `registry.ts` + `discovery.ts` + `custom-providers.ts`
- `transform.ts` 引入策略模式，每个提供者一个策略
- Copilot SDK 适配器提取公共分支为辅助函数

### 3.4 Prompt 构建巨型函数

**位置**: `packages/opencode/src/session/prompt.ts`  
**规模**: 2,101 行，Effect.gen 从第 137 行到第 1,959 行（1,822 行连续生成器函数）

包含：system prompt 组装、tool 定义构建、消息历史处理、结构化输出工具创建、双写迁移代码。

`defaultLayer` 需要提供 19 个依赖 Layer，是所有服务中最多的：

```typescript
Layer.provide(SessionRunState.defaultLayer),
Layer.provide(SessionStatus.defaultLayer),
Layer.provide(SessionCompaction.defaultLayer),
// ... 16 more
```

**建议**: 拆分为 `SystemPromptBuilder`、`ToolDefinitionBuilder`、`MessageHistoryProcessor`、`StructuredOutputHandler` 四个独立 Effect service。

### 3.5 `app-runtime.ts`——全局耦合点

**位置**: `packages/opencode/src/effect/app-runtime.ts`  
**规模**: 50 个导入

作为 Effect 依赖注入的全局组装点，50 个导入在技术上是必要的。但任何新 service 的添加都会修改此文件，形成了一个隐式的变更瓶颈。

**建议**: 考虑自动化的 Layer 合并机制（如基于目录约定的自动发现），减少手动组装。

---

## 4. 积极信号与非债务

| 领域 | 评估 | 数据 |
|------|------|------|
| Effect 迁移 | ✅ 核心层完成 | 241 import effect / 434 总文件 (55%) |
| 测试覆盖 | ✅ 核心包良好 | 227 test / 434 src |
| 模块约定 | ✅ 有明确规范 | AGENTS.md 含 Effect 规范 |
| 废弃标记透明 | ✅ 全部标注 | 19 个 @deprecated |
| TODO 标记少 | ✅ 控制良好 | 仅 18 个真实 TODO |
| 模块耦合 | ✅ 整体可控 | 仅 3 个高耦合文件 |
| llm 包类型安全 | ✅ 负向类型测试 | 18 个 ts-ignore 全是刻意编写的类型守卫测试 |
| 测试运行时 | ✅ 99.6% 通过 | 2,923 tests, 11 fail |
| 新代码质量 | ✅ 规范 Effect 模块 | data-migration.ts 遵循 Service+Layer+defaultLayer 模式 |
| Effect 依赖注入 | ✅ 完整体系 | 66 Service + 66 Layer + 58 defaultLayer |

**需要区分的"伪债务"**（看起来像债务但实际合理）：

- **llm 包 18 个 ts-ignore**: 全部在类型测试文件中，验证错误类型被正确拒绝。这是类型安全的加分项，不是减分项。
- **core 包 20 次 `any`**: 主要在 `log.ts`（日志接口本质上是 `any`）和 `effect-zod.ts`（Effect 内部 API 访问）。基础设施层面，难以避免。
- **app-runtime.ts 50 个导入**: 作为全局 Layer 组装点，这是 Effect 架构的必然结果，不是过度耦合。
- **SDK 生成代码**: `types.gen.ts` + `sdk.gen.ts` 共 ~20K 行，全由 OpenAPI 生成器产出，不属于手写代码债务。

---

## 5. 优先级建议

### P0 — 立即行动

1. **完成 v2 session 迁移**  
   移除 `Flag.OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` 及其全部 **20 处引用**（跨 4 个文件：processor.ts 13 处, prompt.ts 2 处, compaction.ts 2 处, cli/tui 1 处）。  
   当前最大维护风险——每次 bug fix 必须同步 v1/v2 两条路径。  
   预期影响: 双写得分子 15→0，总分 -15。

### P1 — 短期（1-2 sprint）

2. **Console zen 提供者层类型化**  
   为 Anthropic/OpenAI API 请求体定义 Zod schema，消除 273 处 `any`。  
   预期影响: any 得分子 15→5，总分 -10。

3. **清理废弃 Plugin TUI API**  
   10+ 个废弃方法可批量移除（提供外部插件迁移窗口）。  
   预期影响: deprecated 得分 10→5，总分 -5。

### P2 — 中期

4. **修复 llm 包 3 个 OpenAI route 测试失败**  
   **根因**: 测试缺少 `OPENAI_API_KEY` 环境变量，导致 auth schema 校验失败（`SchemaError(Invalid data <redacted> at ["OPENAI_API_KEY"])`）。  
   **非回归**——这是测试基础设施问题，需要 mock auth 层或注入测试 key。  
   涉及文件: `packages/llm/test/route/openai-chat.test.ts`, `openai-responses.test.ts`

5. **修复 opencode 5 个 skill discovery 测试失败**  
   **根因**: `skill.all()` 返回 0 个结果（期望 1-2 个）。测试创建 `.claude/skills/` 目录并写入 `SKILL.md`，但发现逻辑未扫描到。  
   **疑似回归**——发现代码在 `wip` 提交后变更，但测试未同步更新。  
   涉及文件: `packages/opencode/test/skill/skill.test.ts` → `packages/opencode/src/skill/discovery.ts`

6. **拆分 prompt.ts**（2,101 行 → 4-5 个 service）
7. **拆分 provider.ts**（1,767 行 → 3 个文件）
8. **添加 plugin 包测试**（6 个源文件，0 个测试）
9. **修复 transform.test.ts**（3,688 行，111 次 any → 拆分+类型化）
### P3 — 持续改善

10. **深嵌套重构**（3,693 行 >4 级缩进）
11. **Copilot SDK 适配器简化**（429 行深嵌套）
12. **`app-runtime.ts` 自动化组装**（减少手动耦合点）

---

## 6. 评分构成

| 维度 | 权重 | 得分 | 满分 | 关键数据 |
|------|------|------|------|----------|
| 巨型文件 (>1K LOC) | 15 | **15.0** | 15 | 16 个文件 (基线 10) |
| Any 类型使用 | 15 | **15.0** | 15 | 717 处 (基线 500) |
| v1/v2 双写迁移 | 15 | **15.0** | 15 | 15 处标记 (基线 10) |
| TODO/FIXME/HACK | 10 | 7.2 | 10 | 18 个 (基线 25) |
| 深层嵌套 | 10 | **10.0** | 10 | 3,693 行 (基线 3,000) |
| 模块耦合 | 10 | 6.0 | 10 | 3 个高耦合文件 (基线 5) |
| 已废弃 API | 10 | **10.0** | 10 | 19 个 (基线 15) |
| 测试质量 | 10 | **10.0** | 10 | 5 脆弱+16 巨型 (基线 8) |
| 无测试包 | 5 | **5.0** | 5 | 5 个 (基线 3) |
| **总计** | **100** | **93.2** | 100 | |

**解读**: 45 分来自三个满分维度（巨型文件、any、双写）。完成 P0+P1 后，预期评分降至 **~48**（移除双写 15 分 + 降低 any 至 ~200 可省 10 分 + 清理 deprecated 5 分）。

---

## 7. 结论

OpenCode 的技术债务呈现**高度集中**的特征：93.2 分中 45 分来自三个满分维度。这不是一个"到处都有问题"的项目，而是一个在两个关键过渡期（Effect 迁移、v2 event system 迁移）中积累了集中债务的项目。

**三个核心事实**：

1. **v2 session 双写是系统性风险**。`Flag.OPENCODE_EXPERIMENTAL_EVENT_SYSTEM` 在 4 个文件中有 20 处引用，形成了一个全局分支点。每次 bug fix 都要同步 v1/v2 两条路径。这不是局部问题——它影响了 session 处理的核心路径。

2. **console zen 是可快速修复的类型安全黑洞**。3 个文件贡献了 273 次 `any`（console 包总量的 85%）。但 `google.ts` 已经证明了类型化转换是可行的（0 次 `any`）。这是一个有现成参考方案的修复。

3. **基础设施是健康的**。Effect 覆盖 55% 文件（核心业务层 100%）、测试 99.6% 通过率、Effect 依赖注入体系完整（66 Service + 66 Layer）、新代码（如 `data-migration.ts`）遵循规范的 Effect 模块结构。项目的架构基础是稳固的。

**推荐的投入顺序**：P0（v2 迁移）→ P1（console zen 类型化 + 废弃 API 清理）→ P2（测试回归修复 + 巨型文件拆分）。前两项完成后，债务评分预计从 93.2 降至 ~48，项目进入可控状态。
