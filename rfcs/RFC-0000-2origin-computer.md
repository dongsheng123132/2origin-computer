# RFC-0000 — 本源计算架构 2Origin Computer Architecture

**Status:** Draft · Request for Comments
**Version:** 0.1
**Date:** 2026-08-08
**Author:** U-King

> 我们不造模型，我们想造一台 AI 计算机。
> 模型是 CPU，但 CPU 从来不等于一台计算机。

**Principle:** Model is replaceable. State survives. Actions are portable. Learning compounds.
**中文：模型可换，状态不丢，动作可迁移，经验会复利。**

---

## 1. Goal

本架构定义一种面向 AI Agent 的**持久计算机架构**（Persistent AI Computer Architecture）。

它不定义模型，不替代 MCP、A2A 或任何特定 Harness（Agent Runtime）。它定义的是更高一层的问题：

> **一台 AI 计算机，如何拥有模型无关、Harness 无关的持久状态、世界表示、动作系统和习得循环。**

一台符合本架构的机器必须允许 DeepSeek、GPT、Claude、Kimi 或未来模型作为可替换计算单元运行，而不丢失该机器已积累的环境、项目、技能与经验。

---

## 2. 核心洞察：为什么需要"AI 计算机"而不是"又一个 Agent"

今天的 Agent 栈已经有很好的零件：

- **模型**（DeepSeek / GPT / Claude）—— CPU
- **Context Window** —— RAM
- **MCP / A2A** —— 外设总线 / 进程间通信
- **Harness**（Claude Code / Codex / OpenHands）—— 内核 / 调度

但它们拼不出"一台计算机"，因为缺的是把它们装成一整台机器的**主板、硬盘、驱动和操作系统**。

现代 Agent 的普遍痛点是：

> **今天教会，明天忘记。这个任务学会，下一个 Session 又从小学一年级开始。**

原因：Agent 保存的是**聊天记录**（影子），不是**对象状态**（本象）。状态是"世界此刻是什么"，聊天记录是"谁说过什么话"。AI 看到的永远是影，不是对象本身。

---

## 3. 术语与层

### 3.1 总架构

| 层 | 对应 PC | 本体系 | 职责 |
|---|---|---|---|
| 智力 | CPU | 模型（可替换） | 推理、规划 |
| 工作内存 | RAM | Context Window | 当前思考 |
| 长期存储 | SSD + 文件系统 | **本境 Benjing** | 这台 AI 学会的一切 |
| 世界表示 | 显卡/场景图 | **本象 Benxiang** | 把世界变成 AI 可计算的对象 |
| I/O | 南桥 + 驱动 | **影核 ActionParity** | 改变世界（GUI/CLI/API/设备） |
| 系统互连 | 南北桥总线 | **OriginBus 本源总线** | 三条通道：State（知）/ Action（行）/ Trust（谁准了） |
| 内核/启动 | BIOS + Kernel | **Harness**（可替换） | 调度、上下文、工具 |
| 适配 | 芯片组驱动 | **Harness Adapter** | 把 OriginBus 的授权表达翻译成目标 harness 认得的形式 |
| 自学习 | 系统服务 | **学堂 Academy** | 经验沉淀成本境"学历" |
| 整机 | PC | **U-King** | 第一台参考实现 |

> **OriginBus 原先只被定义为"北桥"（把状态编译进 Context）。**
> 2026-08-08 实测发现它还必须覆盖 Action 与 Trust 两条通道——因为南桥的授权模型
> 在 harness 闸门面前**一次也没生效过**（请求根本没到达南桥）。见 [RFC-0001](RFC-0001-originbus.md)。

### 3.2 一句话分工

> **本象保存世界，本境保存成长，影核改变世界。**
> **北桥负责知（Know What），南桥负责行（Do What），Trust Lane 负责"凭什么准"（Who Says So）。**

---

## 4. 完整任务闭环

本架构要求任何"完成任务"必须走完整闭环，缺一不可：

```text
Observe → Think → Act → Verify → Learn
```

```
① BOOT        Harness 启动 → 挂载本境 → 加载项目/环境
② OBSERVE     本象读取世界状态 → 北桥筛选 → 装入 Context
③ THINK       模型推理 → 产生计划
④ ACT         Harness 调度 → 南桥 → 影核 → 现实世界
⑤ VERIFY      再次经本象观察 → 确认是否真成功（不是 exit code=0）
⑥ LEARN       学堂分析轨迹 → 经验/SOP/Skill → 写回本境
⑦ NEXT BOOT   AI 比上次更懂这台机器
```

### 关键约束：Verify 不是看工具返回值

"工具返回 success" ≠ 任务成功。必须通过本象重新观察现实状态验证（State Diff）。

### 关键约束：Learning 必须先 candidate 后 verified

任何经验都不能因为一次成功就自动成为永久事实。状态机：

```text
candidate → reviewed → verified → deprecated / superseded
```

---

## 5. 状态格式（本象最小集）

所有重要对象用统一 Envelope：

```json
{
  "spec": "2origin/0.1",
  "kind": "task.origin",
  "id": "2o:task:001",
  "version": 1,
  "scope": "project:demo",
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "goal": "...",
  "current_state": "...",
  "facts": [{ "claim": "...", "verified": true, "source": "..." }],
  "decisions": [{ "what": "...", "why": "..." }],
  "actions": [{ "verb": "...", "status": "done" }],
  "artifacts": ["..."],
  "verification": "...",
  "next_steps": ["..."],
  "learnings": [{ "lesson": "...", "confidence": 0.9, "status": "candidate" }]
}
```

铁律：
- **facts 必须带 verified**：没验证的不叫事实，叫假设。
- **不存聊天记录，存 State + Facts**：聊天记录是影，本象是对象本身。
- **learning 先 candidate 后 verified**：一次成功不是永久真理。

---

## 6. 学习循环（学堂 / Academy）

```text
完成任务 → 记录 trajectory → 结果验证 → 总结成功/失败
→ 抽象 SOP → 判断是否长期保存 → 写入本境 → 生成/更新 Skill → 下次自动调用
```

学堂是可迁移的 **AI 学籍**（AI Transcript）。模型可以更换，学籍继续存在。

---

## 7. Conformance（符合本架构的最低标准）

一个实现只有在满足以下所有能力后，才可称为 **2Origin Compatible**：

1. **跨 Session 保留状态**：关闭会话再打开，任务靠 State 续上，不靠聊天记录重放。
2. **跨 Harness**：换 Harness（Claude Code ↔ Codex ↔ OpenHands）后状态仍可用，无追问续作。
3. **跨模型**：换模型后状态仍可用，学历不丢。
4. **动作可迁移**：同一 Action 可由不同 Driver（API/CLI/GUI/设备）执行。
5. **结果可验证**：任务执行后通过本象观察现实结果验证，不是只看 exit code。
6. **经验不自动永久化**：学习必须先 candidate 后 verified。
7. **可审计**：所有关键动作、经验晋升、策略变更具有审计记录。

---

## 8. 已验证证据（2026-08-08 首测）

> 首测即通过 = 架构正确的验证信号（非刻意调参打榜的结果）。

### 证据 A — 跨 Session（cross-session）✅
- 独立全新 Claude Code 会话（`claude -p`，无任何对话铺垫）
- 通过 SessionStart hook 自动收到 `task.origin.json` 摘要
- **准确报出任务标题与目标**，无需用户重述

### 证据 B — 跨 Harness（cross-harness）✅
- Claude Code 干 STEP-A（提炼 12 条事实 → `extracted-facts.md`，更新状态）
- Codex（`codex exec`）只凭 `task.origin.json` + facts **零追问续作** STEP-B
- 会话日志证实 Codex 从未问"任务是什么"

### 证据 C — 发现的瓶颈（写权限）**【已修正两处，2026-08-08 晚】**

- ~~Codex 沙箱只读时正文落盘被策略拦截~~ **归因错误**。当日复测：本机 codex 的
  Windows 沙箱 runner 本身是坏的（`CreateProcessAsUserW failed: 5`，连只读 `Get-Date`
  都起不来）。真正拦住写的是 harness 的**工具审批闸门**，不是沙箱策略——铁证是
  南桥 `audit.log` **零记录**：请求从未到达南桥。
- 表明跨 harness 真正缺的不是状态格式，而是 **OriginBus Trust 层的统一写授权** ✅ 这句成立
- ~~这是"南桥" / Trust Plane 的职责~~ **归属错误**。南桥的授权模型完全正确却一次也没生效，
  因为它是**被拦的一方**——有判断依据（risk 分级）但没有决策权。
  **正确归属：南桥负责生产风险信息；跨层的授权表达属于 OriginBus 的 Trust Lane，
  落地责任在 Harness Adapter。** 见 [RFC-0001 本源总线](RFC-0001-originbus.md)。
- **已解一半**：加一条不经过该闸门的通道（CLI Adapter），Hermes 经它落盘成功，
  两条通道判决字节级一致。仍未解：codex 的 per-server 授信（harness 侧）。

---

## 9. 与现有标准的关系

- **不替代 MCP**（工具/数据连接）、**A2A**（Agent 互操作）、**Harness**（运行时）
- 本架构是更高一层：**如何把它们装成一台会长期工作、越用越会的计算机**
- 实现可用 MCP / A2A / 任意 Harness 作为底层 transport，无冲突

---

## 10. 讨论点（Request for Comments）

1. 本境（持久状态）的分层：SQLite 事实源 + 文件快照 + 可选向量索引，是否足够？
2. 北桥 Context 编译（相关性与 Token 预算）该有怎样的标准接口？
3. ~~南桥写权限（Trust/Approval）的最小安全模型怎么定？~~ **已答，见 RFC-0006 §2（南桥内部）
   + RFC-0001 §3（跨层）。** 结论：最小安全模型不是"批准"，是**可核验的凭据**——
   `proof_of_read`（"证明你读过当前内容"），无头 agent 自己拿得出，且随世界变化自动失效。
4. 学堂经验晋升的人工审核门槛，哪些该自动、哪些该人工？
5. **【新】Trust Lane 的第二种凭据长什么样？** `proof_of_read` 只适用于"目标有可读的
   当前内容"的动作。启动进程 / 发消息 / 调外部 API 出示不了它。**暂无实测支撑，不猜。**
6. **【新】协议文本的单一真相源怎么定？** 同一套南桥语义目前散在三处且已漂移
   （本仓库 RFC-0006 §2 / ShadowOS 的 RFC-0004 / 2origin-harness 实现），
   `spec` 字段相同但内容不同。见 §11。

**相关 RFC**：
[RFC-0001 本源总线 OriginBus](RFC-0001-originbus.md)（State / Action / **Trust** 三通道 · 授权凭据 · Harness Adapter 责任）·
[RFC-0005 本境协议 v0.2](RFC-0005-benjing-v0.2.md)（content_hash 乐观锁 / source 可复核 / actor provenance / bundle 编译）·
[RFC-0006 北桥接口 & 南桥 Trust 模型](RFC-0006-northbridge-southbridge.md)（context.request→bundle / 风险分级+批准）

---

## 11. 已知的规范债务（诚实清单）

本架构的铁律之一是「facts 必须带 verified」。同一条铁律适用于规范本身：**声明了但没有
机制保障的，要写在这里，不要装作已经做到。**

| # | 债务 | 实测证据 | 归属 |
|---|---|---|---|
| D1 | **同一协议有三份不一致的文本**：南桥语义散在 RFC-0006 §2 / ShadowOS 的 RFC-0004 / 2origin-harness 实现。RFC-0006 §2.3 的 `action.result` 没有 `replayed` / `diverged` / `footprint`，而 ShadowOS 参考实现有且已验证 | `grep -rn "replayed\|diverged\|footprint\|idempotency" 2origin-harness` **命中 0 个文件**；两份 RFC-0005 diff 出 231 行差异（6895 vs 15384 字节），`spec` 字段却相同 | 未定 —— 需要一个 spec registry：谁是 normative source，实现如何声明自己符合哪一版 |
| D2 | **C6「经验不自动永久化」是形式检查冒充生命周期检查**。现行判据只查 learnings 有没有 `status` 和 `confidence` | 构造一条 `{status:"verified", confidence:0.99}` 的 learning（从没当过 candidate）→ 现行 C6 判 `bad=0`，**通过** | 学堂 / Learning Plane：需要记录**晋升事件**（何时从 candidate 变 verified、凭什么），否则无从区分"验证过的"和"一上来就写 verified 的" |
| D3 | **Trust Plane 在 schema 里是空洞**。`envelope.schema.json` 的 `permissions` 字段注释写着"读写权限边界（Trust Plane）"，实际是 `additionalProperties: true` | 见 `schemas/envelope.schema.json` | RFC-0001 Trust Lane 落地后回填；在那之前**不要在文档里声称有 Trust Plane** |
| D4 | **C2/C3 未纳入一键验证**。`conformance/run-tests.sh` 只自动化了 C1/C4/C5/C6/C7 | 脚本内 `C[0-9]` 去重结果 = C1 C4 C5 C6 C7 | 需要可复跑的跨 harness / 跨模型验证，否则这两条只是一次性演示 |

> D2 与本境 v0.1 已实测的一个缺陷是**同一个病**：当时 `verify-state` 的 CHECK2 把 9 条
> source 全换成一句胡话，判决仍是 VERIFIED——**存在性检查冒充验证**。
> 修法也应当相同：判据要能被"故意造假"打穿，才算判据。

---

**License:** Apache-2.0
**版权/商标:** U-King 与 2Origin 为商标，见 TRADEMARKS。
