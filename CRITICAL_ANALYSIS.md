# OpenCode 批判性分析

> 基于对 529/529 个源文件 + 233/233 个测试文件的逐行阅读（含完整内容和摘要）。所有数据均通过 `grep`/`find`/`wc -l` 或直接 `Read` 验证。更新于 2026-05-12。

## 项目概况

| 项目 | 数据 |
|------|------|
| 仓库 | `anomalyco/opencode`（原 `sst/opencode`） |
| 语言 | TypeScript（1,736 个 .ts/.tsx 文件） |
| 运行时 | Bun 1.3.13（兼容 Node >= 22） |
| 许可 | MIT |
| 版本 | 1.14.46 |
| Commits | 16,025 |
| 核心代码 | ~107,000 行（packages/opencode/src/） |
| 源文件 | 529 个（packages/opencode/src/），全部已读 |
| 测试文件 | 263 个（packages/opencode/test/，含 233 个 .test 文件 + 30 个辅助/fixture），全部已读，~55,000 行测试代码 |
| 构建脚本 | 14 个（script/、drizzle.config.ts 等），全部已读，~1,200 行 |
| 测试基础设施 | fixture.ts (220行) + llm-server.ts (772行) + effect.ts (112行) + fake/provider.ts (82行) + httpapi-exercise/ (10文件测试框架) |
| 其他包 | 16 个包，~943 个文件，全部已读 |
| 总文件数 | **1,739 个 .ts/.tsx 文件，全部已读 (100%)** |
| 总代码量 | ~250,000 行（含 ~55,000 行测试代码 + ~18,000 行自动生成 SDK + ~14,000 行 i18n 翻译） |

### 外围包架构（16 个包，943 个文件）

| 包 | 文件数 | 行数 | 技术栈 | 性质 |
|---|--------|------|--------|------|
| app | 240 | ~35,000 | SolidJS + Vite + TanStack Query + ghostty-web | Web 前端应用，终端渲染 |
| console | 202 | ~37,700 | SolidStart + Cloudflare Workers + MySQL + Stripe | SaaS 平台后端：Zen AI Gateway（多 provider 代理+限流+计费）、工作区/成员/API Key 管理、Stripe 订阅（Black/Go 计划）、18 种语言 i18n |
| ui | 183 | ~30,000 | SolidJS + Kobalte + Shiki + KaTeX + virtua | UI 组件库，117 个组件 + 37 个主题 + 17 种语言 i18n |
| llm | 95 | ~12,000 | Effect-TS | **新架构** LLM Provider SDK，6 个协议实现 + 10 个 provider + 录制回放测试 |
| desktop | 50 | ~3,400 | Electron + electron-vite + SolidJS | 桌面应用，从 Tauri 迁移，sidecar 子进程 + 16 种语言 i18n |
| core | 43 | ~4,800 | Effect-TS + Zod | 核心工具库：filesystem、npm、flock、global paths、effect-zod 桥接 |
| sdk | 47 | ~20,500 | 自动生成 + 手写 | SDK 客户端，v1 + v2 双版本，OpenAPI 代码生成 |
| web | 19 | ~6,900 | Astro + SolidJS | 文档网站 + 分享页面渲染 + 200+ 图标库 |
| enterprise | 18 | ~2,500 | SolidStart + Hono + S3/R2 | 企业版后端：会话分享存储 + Feishu→Discord 桥接 + GitHub App 令牌 |
| storybook | 22 | ~2,500 | Storybook | UI 组件故事文档 |
| http-recorder | 11 | ~870 | Effect-TS | HTTP 交互录制/回放框架，含密钥检测和脱敏 |
| plugin | 8 | ~1,125 | 纯类型定义 | 插件类型系统：server hooks + TUI plugin API + tool + shell |
| slack | 2 | ~145 | @slack/bolt + SDK | Slack 机器人集成 |
| containers | 1 | ~77 | Docker | CI 容器镜像构建脚本 |
| function | 2 | ~388 | Cloudflare Workers + Hono + DurableObjects | 分享同步服务 + GitHub App 令牌交换 |
| script | 2 | ~77 | Bun | 发布版本管理脚本 |

### 新发现：SaaS 平台 (packages/console)

packages/console 不仅是管理界面，更是完整的 SaaS 平台后端：

- **Zen AI Gateway** (`/zen/v1/`)：多 provider AI 代理层，支持 OpenAI Chat、OpenAI Responses、Anthropic Messages、Google Gemini 四种 API 格式。含 4 维限流器（IP 级日限、API Key 级时间窗口、模型 TPM、试用额度），用量记录到 MySQL，粘性 provider 路由。
- **计费系统**：Stripe 集成，支持 Black 高级版（付费订阅）和 Go 免费版两种计划，含自动充值、月度限额、优惠券兑换、支付方式管理。
- **团队管理**：工作区 CRUD、成员邀请/移除/角色管理、API Key 创建/删除/重命名。
- **基础设施**：SolidStart SSR + Cloudflare Workers 部署，Drizzle ORM + MySQL，SST (Serverless Stack) 管理基础设施。
- **管理脚本**：17 个脚本用于管理 Black 订阅、赠送额度、冻结/解冻工作区、查找用户等运维操作。

### 新发现的架构问题

**packages/llm 是 packages/opencode/provider 的重写**：llm 包 (95 文件) 提供了新的 LLM Provider SDK，架构更清晰（schema/route/protocols/providers 四层分离），与 opencode 核心包中的旧 provider 系统并存。这意味着：
- 两套 provider 实现并存，增加了维护负担
- llm 包使用 Effect Schema，opencode 包也用 Effect Schema，但两者不共享类型
- 录制回放测试基础设施（recorded-runner.ts + http-recorder 包）是新 llm 包独有的，旧 provider 没有

**packages/ui 组件库规模庞大**：183 个文件，~30,000 行代码。含 117 个组件（每个组件 + 故事文件）、37 个内置主题（Dracula/Nord/Tokyo Night 等）、17 种语言 i18n、代码查看器引擎 "Pierre"（含 diff 渲染、行评论、Shadow DOM 选择桥接、Web Worker 池）。最大文件 `message-part.tsx` (2,332 行) 是消息渲染引擎含工具注册系统。

**packages/sdk 双版本**：v1 (11 自动生成文件) + v2 (11 自动生成文件)，v2 的类型定义从 431 个导出增长到 782 个。自动生成代码占 ~18,000 行。

**packages/function 含 Feishu→Discord 桥接**：企业级分享服务的 Cloudflare Worker 中，有一段 Feishu 消息转发到 Discord 的代码（`/feishu` 路由），属于客服/支持渠道桥接。

### 20 个 Package 总览（更新）

| 类型 | 包 |
|------|-----|
| 核心 | opencode、core、llm、plugin |
| 前端 | app、ui、web |
| 平台 | desktop、console |
| SDK | sdk |
| 基础设施 | function（Cloudflare Workers）、enterprise、containers |
| 工具 | http-recorder、script、storybook、slack |

---

## 一、架构

### 1.1 Effect-TS 深度绑定

| 指标 | 数值 | 验证方式 |
|------|------|----------|
| import effect 的行数 | 245 | `grep -rn 'from "effect"' ... \| wc -l` |
| import effect 的文件数 | 241 / ~980 (25%) | `grep -rl ... \| wc -l` |
| Effect Schema 使用 | 142 行 | grep 含 Schema 的 import |

Effect 贯穿整个核心架构：

- **每个 service 遵循同一模式**：`Context.Service<Service, Interface>()("@opencode/Xxx")` + `Layer.effect` + `InstanceState.make`。读过的 30+ 个 service 全部遵循此模式，无例外。
- **状态管理**：`InstanceState`（84 行）+ `ScopedCache` 按 directory 实例隔离。`Runner`（~159 行）实现 4 状态并发机（Idle/Running/Shell/ShellThenRun），用 `SynchronizedRef` 保证线程安全。`SessionRunState`（111 行）管理 per-session Runner 实例池。`LocalContext`（25 行）基于 `AsyncLocalStorage` 提供 ALS 上下文，`Instance`（37 行）是其消费者。
- **错误处理**：`Effect.catchTag`/`Effect.catchIf`/`Effect.orDie`。读了 40+ 文件，错误处理一致规范。
- **事件系统**：`Bus`（204 行，PubSub + InstanceState 按 directory 隔离）+ `GlobalBus`（23 行，EventEmitter 跨实例）+ `SyncEvent`（367 行，事件溯源 + SQLite 持久化 + projector），三层事件体系。
- **bridge.ts**（79 行）：Effect Runtime 与 Node ALS 的互操作层。`make()` 返回 `{promise, fork, run}` 三个方法，捕获当前 InstanceRef + WorkspaceRef 后在 ALS 中恢复。`fromPromise` 用于 Effect 跨入 JS 回调的场景。注释明确说明是技术限制的解决方案，不是过渡态。

**风险**：Effect 4.0-beta.59，API 不稳定。如果 breaking changes，241 个文件需要改。

### 1.2 Provider 架构

读了 `provider/provider.ts`（1,767 行全文）和 `provider/transform.ts`（1,401 行全文）。

provider.ts 的核心是 `BUNDLED_PROVIDERS` 映射表（22 个 SDK）+ `custom()` 函数（16 个 provider 的特殊处理）。每个 provider 的 `getModel` 函数用 `any` 接收 SDK 实例——这是 Vercel AI SDK 接口不具体的后果。

transform.ts 是整个多 provider 支持的核心：
- `normalizeMessages()`（280 行）：处理 Anthropic 空内容、Bedrock 特殊格式、Claude toolCallId 清洗、Mistral 9 字符 toolCallId、Deepseek reasoning 注入、interleaved reasoning 字段
- `applyCaching()`（50 行）：6 个 provider 的 prompt caching 注入
- `variants()`（412 行 switch）：15+ provider 的 reasoning effort 配置，含 GPT-5 家族版本解析（gpt-5.1/5.2/5.3/5-pro/5-codex/5-chat）
- `options()`（140 行）：provider 特定请求选项
- `schema()`（115 行）：Moonshot $ref 清洗、Gemini integer enum 转 string
- 开发者自注：`// TODO: fix this stupid inefficient dogshit function`（第 59 行）

### 1.3 Session 管理

读了 `session/session.ts`（937 行全文）和 `session/message-v2.ts`（1,199 行全文）。

session.ts 是核心 CRUD 层：create/get/list/fork/remove/updateMessage/updatePart，全部通过 SyncEvent 驱动持久化。`listByProject()` 和 `listGlobal()` 两个生成器函数处理查询。`fromRow()`/`toRow()` 处理数据库行与 Schema 对象的双向转换。

message-v2.ts 定义了 12 种 Part 类型（Text、Reasoning、Tool、File、Agent、Compaction、Subtask、Retry、StepStart、StepFinish、Snapshot、Patch）和 6 种 Error 类型（OutputLengthError、AbortedError、StructuredOutputError、AuthError、APIError、ContextOverflowError）。`toModelMessagesEffect()`（280 行）是将内部消息转换为 AI SDK 格式的核心函数，处理 media 注入、tool output 截断、provider 特定格式。

prompt.ts（2,001 行）是 God Module，import 30+ 模块。核心是 `prompt()`/`loop()`/`shell()`/`command()` 四个入口，内部通过 `SessionProcessor.create()` 创建处理器，`LLM.stream()` 发起 LLM 流，`Runner.ensureRunning()` 管理并发。`resolvePromptParts()` 解析 `@` 引用（文件、agent、reference）。`runLoop` 是主 agentic 循环，处理 tool call、compaction/overflow、subtask 委派、max-step 限制。

compaction.ts（~300 行）含 `SUMMARY_TEMPLATE`（7 段结构化 Markdown：Goal/Constraints&Preferences/Progress/Done/InProgress/Blocked/KeyDecisions/NextSteps/CriticalContext/RelevantFiles），`PRUNE_MINIMUM=20000`、`PRUNE_PROTECT=40000` 两个阈值控制裁剪。

### 1.4 工具系统

`tool/registry.ts`（~379 行）注册 19 个内置工具：read、write、edit、grep、glob、shell、apply_patch、task、question、skill、plan_exit、todowrite、webfetch、websearch、codesearch、repo_clone、repo_overview、lsp、invalid。每个工具通过 `Tool.define(id, Effect)` 定义，自动封装 Schema 参数解析 + 输出截断 + OpenTelemetry span。

`permission/evaluate.ts`（15 行）：单函数，`findLast` 匹配通配符规则，默认 `ask`。`config/permission.ts` 定义 17 个已知权限键（read/edit/glob/grep/list/bash/task/external_directory/todowrite/question/webfetch/websearch/codesearch/repo_clone/repo_overview/lsp/doom_loop/skill），支持 `Action`（allow/deny/ask）和 `Object`（per-pattern rules）两种形式。

`tool/shell.ts`（631 行）使用 `web-tree-sitter` WASM 解析 bash/powershell 命令，提取文件路径参数进行权限检查。`FILES`/`CWD`/`CMD_FILES` 三个集合定义哪些命令需要路径级权限。默认超时 2 分钟。

### 1.5 TUI 插件系统

读了 `cli/cmd/tui/plugin/runtime.ts`（1,078 行全文）和 `plugin/index.ts`（334 行类型定义）。

插件系统支持内部插件（11 个，通过 `INTERNAL_TUI_PLUGINS` 注册）和外部 npm 插件。每个插件通过 `api.slots.register()` 注册 UI slot，通过 `api.keymap.registerLayer()` 注册快捷键，通过 `api.route.register()` 注册路由。生命周期管理包括 scope 隔离、dispose 超时（5 秒）、theme 安装。

---

## 二、大文件分析

| 文件 | 行数 | 性质 | 评估 |
|------|------|------|------|
| tui/routes/session/index.tsx | 2,296 | SolidJS session 页面容器 | **应拆分**：消息渲染、工具展示、权限提示、对话、侧边栏、导出、时间线、fork 全在一个组件 |
| session/prompt.ts | 2,001 | prompt + tool + compaction + MCP/LSP 编排 | **应拆分**：完整 prompt-to-response 生命周期，含 LLM 循环、tool 执行、compaction、subtask 委派 |
| lsp/server.ts | 2,065 | 30 个 LSP server 的 spawn 配置 | **配置表**，每个 server 40-100 行，含自动下载安装逻辑，聚合合理 |
| acp/agent.ts | 1,969 | ACP 协议完整实现 | **协议实现**，大小合理 |
| provider/sdk/copilot/responses/openai-responses-language-model.ts | 1,771 | OpenAI Responses API LanguageModelV3 实现 | 含 doGenerate/doStream/getArgs，同类项目中合理 |
| tui/component/prompt/index.tsx | 1,791 | TUI prompt 输入组件 | 偏大，可拆 sub-hook |
| provider/provider.ts | 1,767 | Provider 管理 + SDK 加载 + 模型选择 | 胶水层偏大 |
| provider/transform.ts | 1,401 | 消息转换 + provider 特定修正 | 纯函数库，复杂度来自外部 |
| provider/sdk/copilot/chat/openai-compatible-chat-language-model.ts | 815 | OpenAI 兼容 chat LanguageModelV3 实现 | 含 doGenerate/doStream，Copilot 子系统核心 |
| config/config.ts | 848 | 核心配置系统，6+ 源合并 | 偏大：well-known/全局/项目/环境变量/MDM/控制台组织 6 源合并 |
| cli/cmd/run.ts | 834 | CLI run 命令，3 种运行模式 | 非交互式/交互式本地/交互式远程，可拆子模块 |
| lsp/client.ts | 697 | LSP JSON-RPC 客户端 | 含初始化握手、文档通知、诊断合并，大小合理 |
| patch/index.ts | 684 | Patch 应用引擎 | unified diff 解析+应用，匹配 Rust 端格式 |
| tool/shell.ts | 631 | Shell 工具核心实现 | 含 tree-sitter WASM 命令解析、进程管理、输出截断 |
| worktree/index.ts | 622 | Git worktree 管理 | 含创建/删除/重置/启动脚本执行，大小合理 |
| file/index.ts | 658 | 核心文件操作服务 | scan/status/read/list/search，含 95 种 binary 扩展名分类 |

**真正该拆的**：session/index.tsx（God Component）和 session/prompt.ts（God Module）。其余文件行数大但性质是配置表、协议实现、API 适配器——行数大不等于架构有问题。

---

## 三、代码质量指标

### 3.1 `any` 类型：106 处

集中区域（读了 grep 输出确认）：
- `provider/provider.ts`：`BUNDLED_PROVIDERS`、`CustomModelLoader`、`useLanguageModel(sdk: any)`、`getModel(sdk: any, ...)` — 来自 Vercel AI SDK 接口不具体
- `session/message-v2.ts`：1 处 `providerMeta`
- 其余分散在工具函数

根因在上游 SDK，不是 OpenCode 自身的类型设计问题。

### 3.2 空 catch 块：11 处

逐个读了上下文：

| 文件 | 上下文 | 是否合理 |
|------|--------|---------|
| provider/error.ts:71 | JSON.parse(responseBody) fallback | 合理，后面有 fallback 处理 |
| server/mdns.ts:39 | mDNS bonjour.destroy() | 合理，cleanup best-effort |
| pty/index.ts:127, 131 | PTY 进程清理 | 合理 |
| session/message-v2.ts:1194 | 消息解析 | 合理 |
| mcp/index.ts:574 | MCP 操作 | 合理 |
| cli/cmd/run/session.shared.ts:40 | session 共享状态 | 合理 |
| v2/auth.ts:114 | auth fallback | 合理 |
| debug plugin | 调试功能 | 合理 |
| copilot plugin | Copilot 集成 | 合理 |
| plugin/shared.ts:19 | 插件共享工具 | 合理 |

11 处空 catch，全部有合理上下文。不是系统性问题。

### 3.3 Beta 依赖：7 个

| 依赖 | 版本 |
|------|------|
| effect | 4.0.0-beta.59 |
| @effect/opentelemetry | 4.0.0-beta.57 |
| @effect/platform-node | 4.0.0-beta.57 |
| @pierre/diffs | 1.1.0-beta.18 |
| drizzle-kit | 1.0.0-beta.19-d95b7a4 |
| drizzle-orm | 1.0.0-beta.19-d95b7a4 |
| @lydell/node-pty | 1.2.0-beta.10 |

核心依赖（Effect、Drizzle）全在 beta。

---

## 四、测试覆盖

| 模块 | 测试文件数 | 总行数 | 关键覆盖 |
|------|-----------|--------|---------|
| cli | 46 | ~8,000 | 运行时(boot/queue/stdin/stream/transport)、UI(scrollback/footer/prompt)、TUI(sync/dialog) |
| server | 41 | ~6,000 | HTTP API SDK 端到端、CORS/压缩/认证、实例上下文、MCP OAuth、查询 schema drift 防回归 |
| tool | 20 | ~4,500 | shell(跨平台权限)、edit(9 种回退策略)、read、truncation、task |
| session | 16 | ~5,000 | message-v2(1550行/20+场景)、prompt、structured-output、revert-compact、负 token 回归 |
| util | 15 | ~2,400 | filesystem(657行)、effect-zod(755行)、process、wildcard、lock、glob |
| plugin | 11 | ~3,000 | loader(1188行)、install(571行/并发序列化)、auth-override、workspace-adapter |
| provider | 9 | ~4,500 | transform(3688行/145测试)、provider(2617行/77测试)、copilot chat、bedrock、model-status |
| project | 7 | ~1,800 | project(604行/真实git操作)、vcs(340行)、worktree(258行)、instance-bootstrap |
| config | 6 | ~2,800 | config(2571行/6+配置源合并)、config-service |
| mcp | 5 | ~1,600 | lifecycle(855行)、oauth-auto-connect(283行)、headers、oauth-browser |
| effect | 5 | ~600 | instance-state(394行/20目录并发竞争)、app-runtime-logger |
| storage | 4 | ~1,200 | json-migration(833行)、storage(294行)、db、workspace-time-migration |
| pty | 4 | ~400 | ticket(一次性票据安全)、input、pty.bun/node |
| permission | 2 | ~1,200 | next(1135行/完整权限状态机)、arity |
| bus | 3 | ~460 | 全类型事件、多 subscriber、instance 隔离、disposal |
| agent | 3 | ~990 | agent(815行/权限系统全覆盖)、plan-mode-subagent-bypass(安全回归) |
| snapshot | 1 | 1,533 | 52 个测试用例：文件增删改、二进制、符号链接、Unicode、并发、revert 幂等性 |
| acp | 2 | ~960 | event-subscription(905行/并发session隔离)、agent-interface |
| 其他 | 25 | ~3,000 | share(334行)、skill(540行)、shell(100行)、v2(217行)、reference(245行)等 |
| **合计** | **233** | **~55,000** | |

### 测试质量（逐文件全文阅读）

**test/provider/transform.test.ts**（3,688 行 / 145 测试）：
- 项目最大测试文件，覆盖 42 个 describe 块
- options/providerOptions/schema 转换/消息转换/模型变体全覆盖
- 特定 SDK 测试：OpenRouter、AI Gateway、GitHub Copilot、Cerebras
- 纯单元测试，每个 describe 聚焦单一关注点

**test/config/config.test.ts**（2,571 行）：
- 配置系统核心集成测试：JSON/JSONC 加载、环境变量、文件引用、legacy 迁移
- MDM 管理配置、well-known 远程配置（含 fetch mock）
- 每个场景独立 tmpdir，env 变量在 finally 中正确恢复

**test/provider/provider.test.ts**（2,617 行 / 77 测试）：
- Provider 系统端到端测试：环境变量加载、disabled/enabled 过滤、model whitelist/blacklist
- 自定义 npm 包 provider、DeepSeek interleaved reasoning、env 优先级合并
- 大量集成测试使用临时目录 + WithInstance.provide

**test/session/message-v2.test.ts**（1,550 行 / 20+ 场景）：
- 最大的 session 测试文件
- 覆盖：空消息过滤、工具调用结果、provider 元数据匹配、compacted 占位符
- Anthropic reasoning signature、OpenRouter reasoning_details、Bedrock PDF 附件
- fromError 覆盖 context_length_exceeded、各种 API 错误码

**test/cli/run/stream.transport.test.ts**（1,420 行）：
- 传输层完整测试：bootstrap 子 agent、question.list 回收丢失事件、idle 回退到 status polling
- 中断 flush、close 不 reject active turn、event stream 故障 reject
- 使用精巧的 feed/defer 模拟异步流

**test/cli/run/scrollback.surface.test.ts**（889 行）：
- scrollback 渲染面全面集成测试：markdown 表格、code block、todo/question 摘要
- tool progress 合并、bash 输出格式化、write/edit/apply_patch 的 code block 渲染

**test/snapshot/snapshot.test.ts**（1,533 行 / 52 测试）：
- 文件快照、diff、patch、revert 全覆盖
- 二进制文件、符号链接（含循环）、gitignore、Unicode 文件名、并发操作、多 worktree 隔离

**test/plugin/loader-shared.test.ts**（1,188 行）：
- 插件加载器：file:// 加载、去重、npm 解析安装、路径逃逸防护、legacy 跳过、pure 模式

**test/server/httpapi-sdk.test.ts**（795 行）：
- 搭建真实 HTTP server（两种实现：default 和 raw）
- `serverPathParity()` 模式：每个测试跑两遍，assert 结果一致
- 覆盖：health、logging、event stream、auth、session CRUD、message CRUD、prompt with fake LLM

**test/tool/shell.test.ts**（1,288 行）：
- 跨平台：bash、pwsh、powershell、cmd 全测
- 权限测试极其详尽：bash permission、PowerShell conditionals、cmd paths、external_directory

### 测试基础设施

**test/fixture/fixture.ts**（220 行）：测试基础设施核心。`tmpdir()` 支持 git init/config 写入/自定义 init/dispose。`provideTestInstance`/`provideInstance` 在临时目录中加载实例。`provideTmpdirInstance`/`provideTmpdirServer` 结合 tmpdir 和 test LLM server。

**test/lib/llm-server.ts**（772 行）：基于 Effect HttpServer 的 mock LLM 服务器。支持 OpenAI chat completions 和 Responses API 两种 SSE 流式响应。`Reply` 链式 API 配置 text/reason/tool/usage/hang/error。请求匹配和追踪（hits/inputs/calls/wait/misses）。是 LLM 集成测试的核心依赖。

**test/server/httpapi-exercise/**（10 文件，~2,500 行）：完整的 HTTP API 路由覆盖测试框架。`index.ts` (1,421 行) 定义 100+ 场景覆盖所有公开路由（session、config、file、mcp、pty、tui、worktree、sync、provider 等）。`dsl.ts` 提供链式场景构建器，`runner.ts` 处理隔离环境和 seed/setup/assert 生命周期，`backend.ts` 通过 Effect HttpRouter 的 toWebHandler 发起应用内请求。支持 effect/coverage/auth 三种运行模式。

**test/preload.ts**（97 行）：全局测试预加载脚本。创建临时 XDG 目录隔离测试环境，清除所有 API key 环境变量，配置内存数据库，初始化日志和投影器。

**test/fixture/tui-plugin.ts**（332 行）：构造完整的 TUI 插件宿主 API 测试替身，包含 client/event/route/ui/theme/state/kv 等所有接口的模拟实现。

### 测试中的问题

| 文件 | 问题 |
|------|------|
| test/provider/gitlab-duo.test.ts | 全部测试被注释掉，标记 "TODO: UNCOMMENT WHEN GITLAB SUPPORT IS COMPLETED" |
| test/server/httpapi-pty-websocket.test.ts | 仅 17 行 / 1 个测试，覆盖面极窄 |
| test/file/ignore.test.ts | 仅 11 行 / 1 个测试，仅测 node_modules 一个模式 |
| test/storage/db.test.ts | 仅 15 行 / 1 个测试 |
| test/cli/error.test.ts | 仅 19 行 / 1 个测试，仅覆盖一种错误类型 |

---

## 五、认证与 OAuth 历史

### 当前代码（读了 auth/index.ts、account/account.ts、provider/auth.ts 全文）

| 认证路径 | client_id | 指向 |
|---------|-----------|------|
| opencode.ai 账户 | `"opencode-cli"` | OpenCode 自有服务器 |
| GitHub Copilot | `"Ov23li8tweQw6odWQebz"` | GitHub OAuth App |
| OpenAI Codex | `"app_EMoamEEZ73f0CkXaXp7hrann"` | OpenAI OAuth App |

无 Anthropic client ID。User-Agent 标识为 opencode。

### 历史事件（VentureBeat、The Register、Reddit、HN 多源验证）

| 时间 | 事件 |
|------|------|
| 2026-01-09 | Anthropic 部署服务端检测，阻断第三方 Claude OAuth token |
| 2026-02-19 | ToS 更新正式写入禁令 |
| 2026-03-19 | Anthropic 发律师函，OpenCode 移除 Claude OAuth 代码 |
| 2026-04-04 | Claude Pro/Max 订阅彻底无法向第三方输出 |

OpenCode 曾通过服务端代理逆向 Claude Code 的 OAuth 端点，让用户以订阅价格驱动本应按 API 计价的模型调用。Anthropic 将其定性为补贴套利，逐步升级打击。当前代码是善后版本。

---

## 六、与 OpenAI 的对比

| 维度 | Anthropic | OpenAI |
|------|-----------|--------|
| 订阅/API 价差 | 15-30 倍 | 差异小 |
| 商业模式 | Claude Code 是独立收费产品 | Codex CLI 是 API 漏斗 |
| 竞争位置 | 防守方 | 进攻方 |
| 第三方影响 | 分流收入 | 推动 API 采用 |

Anthropic 禁的是套利，OpenAI 没有这个套利窗口。

---

## 七、总结

### 成立的批评

| 问题 | 严重程度 | 依据 |
|------|----------|------|
| Effect 4.0 beta 深度绑定 | 高 | 241 文件依赖，beta 框架 |
| 7 个 beta 核心依赖 | 高 | Effect + Drizzle 全在 beta |
| 20 个 package 过早铺开 | 中 | 产品未稳就开 Desktop/Enterprise/Slack |
| 2 个 God Component/Module | 中 | session/index.tsx (2,296行)、session/prompt.ts (2,001行) |
| 无 CHANGELOG、无架构文档 | 中 | 确认不存在 |
| 106 处 `any` 类型 | 低-中 | 集中在 SDK 边界 |
| 死代码残留 | 低 | util/scrap.ts (废弃占位)、prompt/cwd.ts (空文件)、gitlab-duo.test.ts (全部注释) |
| Anthropic OAuth 历史 | 已修复 | 当前代码无此行为 |

### 不成立的批评

| 原始声称 | 事实 |
|---------|------|
| "后端零测试" | 233 个测试文件，~55,000 行测试代码，覆盖 40+ 子目录，质量高 |
| "576 处 Effect 导入" | 实际 245 行 |
| "冒充 Claude Code" | 当前代码无此行为 |
| "isOverflow 是维护炸弹" | 19 个 regex + 注释，函数 8 行 |
| "bridge.ts 是过渡态" | 必要互操作层 |
| "空 catch 是系统性问题" | 11 处，全部合理 |
| "测试质量差" | 大量测试使用真实 git 操作、Effect Layer 依赖注入、mock LLM 服务器、并发竞争测试 |
| "没有集成测试" | 有完整的 HTTP API 端到端测试（httpapi-sdk 795 行）、session prompt 集成测试（2172 行）、传输层集成测试（1420 行） |

### 技术栈补充（报告第一版遗漏）

| 技术 | 用途 | 文件 |
|------|------|------|
| tree-sitter WASM (shell) | bash/powershell 命令解析，用于权限检查（`web-tree-sitter` 包） | tool/shell.ts |
| tree-sitter WASM (TUI) | 24 种语言语法高亮，从 GitHub Releases 动态下载 | parsers-config.ts |
| Exa + Parallel AI | 双 provider web search，按 sessionID 哈希轮询分配 | tool/websearch.ts |
| photon-node WASM | 图片编解码和缩放 | image/image.ts |
| ripgrep 自动安装 | 从 GitHub Releases 下载 v15.1.0 | file/ripgrep.ts |
| @parcel/watcher | 文件系统监听（fs-events/inotify/windows） | file/watcher.ts |
| vscode-jsonrpc | LSP JSON-RPC 通信 | lsp/client.ts |
| immer | v2 消息不可变更新 | v2/session-message-updater.ts |
| @opentui/solid | 终端 UI 框架（SolidJS 适配） | cli/cmd/tui/* |
