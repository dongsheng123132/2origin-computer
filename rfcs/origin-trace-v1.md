# origin.trace.v1 — 最小执行记录契约

状态：2026-09-09 实验版。优先顺序不变；Trace 与 authoritative state 稳定后再接 kill/resume。
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
