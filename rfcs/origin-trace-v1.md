# origin.trace.v1 — 最小执行记录契约

状态：2026-09-09 v1 最小契约收口，三个策略已有执行证据；共享权威状态的并发与恢复尚未验收。优先顺序不变；Trace 与 authoritative state 稳定后再接 kill/resume。
规范只在本仓维护；实现和实际运行证据在 `D:/uking编程/ShadowOS = Harness OS/runtime/origin-trace/` 与 `demo/origin-trace/`。

## 边界

Agent 是可替换进程；本象维护唯一被接受的现实；Origin Trace 保存现实为什么这样变化。
Trace 是观察记录，不是第二个状态写入核心。现有 OriginEvent 原样嵌入 span 的 `source_event`，仍使用 `origin.event/0.1` 的事件类型与哈希链。
新增语义放在 `payload.trace_span` 扩展；verify/reject 记录为现有 tool.completed，commit 使用 object.committed 并保留南桥原始 action.result。
`authoritative_head` 是被观察的权威对象快照的 SHA-256，**不是事件链头，也不授予写权限**。缺少结束封口的文件不能进入验收。

## 数据

一份 `trace.jsonl`：首行为 `{record:"run", spec:"origin.trace.v1", run, tool_schema, assertions, state_before}`；
中间每行为 `{record:"span",span}`；末行为 `{record:"seal", state_after, side_effect_diff, evidence, authoritative_head, outcome, trace_hash}`。
组装后的内存对象具有 `spans[]`；每个 span 必须保留源事件。

- run：id、agent、model、task、started_at、execution、fault_injection、scope。
- span：id、kind（tool_call / agent_call / object_proposal / verify / commit / reject）、actor、start_ms/end_ms、tool、input/output 及各自 hash、approval、state_before/after、side_effect_diff、source_event。
- assertions：确定性判据 ID。gate 必须使用实现端认可的冻结策略，不能执行 Trace 自带代码，不能信任自报 passed。
- evidence：回读凭据及证明范围。最终输出在 COMMIT 产物快照及提案 CSV 中；REJECT 的候选不进入 accepted state。
- trace_hash：移除 trace_hash 与传输 record 字段后的完整内存对象 SHA-256，覆盖墙钟及源事件。不能证明记录者诚实，也不能替代签名或外部锚点。
- JSON 编码：键按字典序递归排序、数组保序、紧凑 UTF-8、SHA-256 十六进制；不支持 undefined/NaN/Infinity。只记录授权范围内的数据，凭据和隐藏推理不进入 Trace。

## v1 必须遵守的验收状态机

本节为规范要求，由实现的 `validate` 和各宿主登记的 `replay` 策略共同执行。单个 run 只有一个提案、一次 VERIFY、一个末尾决定；修订候选必须创建新 run，再 diff。多个事务、kill/resume、token 流均不进入本次契约。

| 阶段 | 绑定内容 | 对 accepted state 的影响 |
|---|---|---|
| PROPOSE（`object_proposal`） | 候选完整内容及 output_hash；本象策略含 transaction、expected_head | 不变 |
| VERIFY（`verify`） | input.proposal_hash 指向候选 output_hash；本象策略还绑定 expected_head、编译器源码 hash | 不变；记录 passed 与可复核 violations |
| COMMIT（`commit`） | 本象策略 input 同时绑定 expected_head、proposal_hash、verification_hash；保留唯一写核心的 action.result | 仅通过校验且写后回读一致才能出现；version 恰好 +1 |
| REJECT（`reject`） | 绑定同一提案及验证；output.reason 为稳定拒绝码 | 与 state_before 完全一致，side_effect_diff 为空 |

所有 span.state_before 必须接上上一 span.state_after；非 COMMIT 不能改变快照。封口 state_after 必须等于最后快照，authoritative_head 必须等于该快照的规范化 SHA-256。head 与事件链头分开；对象版本与 span 序号分开。

expected_head 必须接上本次初始快照；唯一的记录例外是 `REJECT / STALE_HEAD`，此时策略必须重新算出前置条件确实失败。不能把字段级 stale-write 警告理解成拥有覆盖权。验证失败不得调用写核心；写入失败或回读不一致保留未封口记录，不伪造成功 COMMIT。

JSONL 的三种外层记录字段是封闭集合：run 行只能含上述六个字段；span 行只能含 record、span；seal 行只能含上述七个字段。每个字段必需，禁止 seal 重新定义 run、spec、assertions 或 spans。嵌套的任务/工具参数/证据属于策略数据，不能提供可执行代码或编译器路径。未知策略不能 gate 通过。

`validate.ok` 只证明记录结构和哈希自洽；`replay.ok` 只证明能够完成离线重算；`gate.ok` 才表示策略验收通过。不得把合法记录了 REJECT 等同于产物通过验收。本象策略额外返回 conforms：符合状态机的 REJECT 可为 true，而 accepted 与 gate.ok 仍为 false。旧 CSV/诊断策略的断言数组及 accepted 语义保持兼容，不改历史 Trace 字节。

## 本象验收策略：benxiang-acceptance-v1

复用已通过原诊断 gate 的真实 Hermes/Codex/DSH 报告，先回读 report.md 比较 hash，再建立单写者隔离 world.json。初始对象 `report:regression` 含 status=candidate、artifact_sha256、bug_fix_claim=false。允许提交 status=accepted，必须维持证据 hash，且不能将 bug_fix_claim 改为 true。该策略只验收报告，不把文中待验证假设升级为根因事实。

PROPOSE.output = `{transaction, expected_head}`；transaction 含 transaction_id（等于 run.id）、state_changes、assertions=[]。该 profile 只接受上述对象及字段、显式 from/to、无重复字段写；不接受 creates、未知断言或任意额外事务字段。更广的领域能力由后续冻结策略承载，不修改本次 wire contract。

VERIFY 直接调用现有本象 `compiler/commit-compiler.mjs` 的 validateTransaction；通过后才调用 applyTransaction。不是另写一套 fold。该 profile 将核心的警告也视为拒绝；COMMIT 保留编译器产生的 journal/provenance。落盘只经现有南桥，携带旧 world 文件字节 hash，并立即回读；Trace 只记录结果，不是第二个状态写者。

run.task.compiler 钉住 commit-compiler.mjs 和其唯一依赖 constraints.mjs 的实际源码 SHA-256。记录源码 hash 不等于认证代码来源；本地宿主通过已配置仓路径加载可信核心，禁止从 Trace 的任意路径加载模块。replay/gate 发现源码漂移返回 COMPILER_FINGERPRINT_MISMATCH，运行期间漂移同样拒绝。当前本象仓存在其他会话的未提交改动，记录绑定实际字节，不声称绑定到一个干净发布版本。

稳定拒绝码包括 STALE_HEAD、TRANSACTION_SCHEMA、DUPLICATE_FIELD_WRITE、BENXIANG_VERIFICATION_FAILED；具体本象违规保留在 VERIFY.output.violations。冻结 gate 判据为 compiler_pinned / proposal_bound / compiler_verdict / decision_bound / accepted_state / write_readback。

实际证据在实现仓 `demo/origin-trace/acceptance-20260909-{bad,good,stale}/`：显式假修复声明 REJECT；修正后 COMMIT；陈旧 head REJECT。三次都是复用历史真实模型产物的本地编译器执行，不能标成三次新的模型运行。新策略由 CLI 注册，本轮浏览器不装本象编译器、不宣称验收该策略。

边界：world.json 的初始化 v0 是基线；对象 diff 只涵盖该世界里的 accepted 对象，不包含 Trace/审计。此处字节前置条件与回读仅证明隔离单写者样例，不证明共享权威状态线性一致、多文件原子提交、崩溃恢复或跨进程恰好一次执行。hash 能检测篡改不等于记录者诚实；这些边界不因 gate 通过而消失。

## 首个可执行策略：csv-summary-v1

三次真实模型调用分别承担 Planner、Researcher、Verifier。输入为公开合成账目，汇总任务实际执行。
角色间传递前一步输出；Verifier 意见不能代替确定性核心验证。核心重算分类汇总及 CSV 格式，再决定是否调用既有南桥 doWrite。
当前 actor 是角色标签，真实模型 ID 和 API response ID 单独记录，不声称接通 Hermes/Codex/DSH 三宿主。

对象快照范围只有本次隔离运行的 `result.csv`。初始 `{version:0,objects:{}}`；拒绝后不变；提交后 v1，保存回读 hash 与字节数。
Trace、审计和请求文件是观测材料；模型 API 计费不在对象 diff 范围。该范围必须在 run.scope 明示。
现有南桥是唯一产物写者，本版只测试新文件，不声明共享对象并发 CAS、跨文件事务或进程故障恢复已完成。

八项 gate：三角色回执、调用顺序、工具参数契约、审批范围、候选符合输入、先验证后决定、状态转换、对象副作用数量。
坏样本显式把 Researcher 输出的一个总额加一，再交 Verifier 和确定性核心；必须得到 REJECT，不能把它描述为模型自然出错。
正确样本移除注入并重新调用三个角色。每次用新 run id，禁止覆盖旧记录。

`validate` 验结构、哈希与链；`replay` 离线重算判据及状态；`gate` 将失败转为非零退出码；`diff` 按角色/动作/出现次数对齐，比较参数、结果与状态。
这里的 replay 不重新执行模型、不重放外部副作用，不声称能确定性复现模型采样。未知策略拒绝 gate，不能凭自己声明的新断言放行。

## 同一 Trace 契约的真实诊断策略（2026-09-09）

新增 `regression-diagnosis-v1` 任务策略，不新增 Trace 协议版本。Collector/Hermes、Diagnostician/Codex、Reviewer/DSH 是三个实际宿主进程；角色与 `output.host`、观测模型字段分开。模型字段无可靠来源时为 `unobserved`。
源输入为绑定仓库里的 B5.1b、E1d 代码片段及先前失败摘要，记录源文件 hash、行号与片段 hash。交接通过 `input.handoff_hash` 绑定上一结果，并记录实际交接文本。候选报告必须引用输入中真实存在的逐字片段，且独立 Reviewer 明确认可。
权威对象范围为新建隔离 `report.md`；COMMIT 是诊断报告验收，不是根因证实或 Bug 修复验收。检查三宿主不重复、进程真实成功退出、交接完整、引用一致、复核通过、先验证再提交及写后回读。对原 CSV 策略保持兼容。
实时进度为旁路 `progress.jsonl`，只能用于未完成阶段的 UI 提示，不进入 accepted state。UI 只展示完整记录行，封口前没有验收通过；封口后通过共享 replay 重算。CLI/界面均不将播放操作变成重新执行模型或写入世界。kill/resume 仍后置。

## 参考与答辩引用

- AgentReplay trace contract：https://github.com/anzal1/agentreplay/blob/main/docs/TRACE_SPEC.md 。借鉴冻结 tool 边界、验收及回归思路，没有替换本象核心、没有宣称 wire-compatible。
- Canvas 工程参考：https://github.com/shusingh/agent-replay 。本实现借鉴 Canvas 与 Worker 分工，代码独立实现；未移植其代码，未复现其 50k spans / 6.9ms 性能声明。
- Where Reliability Lives：https://arxiv.org/abs/2609.03192 （2026-09-02）。结论只适用于作者设计世界；2,581 次 completion claim 中没有 false claim，不能把该数据说成主动假完成攻击通过了拦截测试。本实验另用显式错误候选验证 REJECT。
