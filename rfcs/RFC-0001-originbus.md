# RFC-0001 — 本源总线 OriginBus

**Status:** Draft · Request for Comments
**Version:** 0.1
**Date:** 2026-08-08

> 这份 RFC 不是从架构图上推出来的，是被一个具体故障逼出来的：
> **南桥的授权模型完全正确，却一次也没生效——因为请求根本没到达南桥。**
>
> RFC-0006 定义了北桥和南桥**各自内部**的接口。OriginBus 定义的是它们**之间**、
> 以及它们与 Harness 之间的东西：谁有权决定、谁有判断依据、凭据怎么跨层传递。

---

## 1. 为什么需要总线（实测出血点）

2026-08-08，codex-cli 0.147.0，Windows：

| 观察 | 证据 |
|---|---|
| 南桥 MCP server 注册成功、握手成功 | `codex mcp get southbridge` 显示 enabled；会话 rollout 的工具清单里有 `southbridge_verify` |
| 每次 `tools/call` 返回 `user cancelled MCP tool call` | 两次 `codex exec` 输出 |
| **南桥 `audit.log` 零记录** | 最后一条是本地跑验证器的 09:06:57，两次 codex 运行（09:14、09:20+）无任何记录 |
| `-c approval_policy=never` 不覆盖 MCP 工具 | 同上两次运行 |
| execpolicy 只有 shell 的 `prefix_rule` | `grep -ic mcp ~/.codex/rules/default.rules` = **0** |
| 唯一能过闸的是全局关闸 | `codex exec --help`：`--approve-for-me` / `--dangerously-bypass-approvals-and-sandbox` |

审计零记录是铁证：**请求从未到达南桥。**

于是南桥那套已被 43 条判据验证过的分级授权（risk 三级 + `expect_sha256` + `confirm`），
在这个场景下**一次也没有机会执行**。

### 1.1 病根：决策权与判断依据不在同一层

```
模型 / Agent
     ↓
Harness 审批闸门   ← 有【决策权】（能拦），没有【判断依据】（不知道这动作 risk 多高）
     ↓ tools/call        ✗ 请求死在这里
影核 / 南桥        ← 有【判断依据】（risk 分级、批准凭据），没有【决策权】
     ↓
世界
```

**让被拦在门外的一方去解决"我为什么被拦"，是无解的。**

因此 RFC-0000 §8 证据 C 原文「这是南桥 / Trust Plane 的职责」需要修正为：

> **南桥负责生产风险信息，不负责授权决策。跨层的授权表达属于 OriginBus。**

---

## 2. OriginBus 是什么

OriginBus 是本源计算机的**系统互连层**。它不是一个进程，也不规定 transport
（local IPC / stdio / HTTP / MCP / JSON-RPC 都可以），它规定的是**跨层契约**。

```
                    Harness / Control Plane
                             │
        ┌────────────────────┴────────────────────┐
        │            OriginBus 本源总线            │
        │   State Lane（知）   ·   Action Lane（行） │
        │        ── Trust Lane（谁准了）──          │
        └────────┬───────────────────────┬────────┘
                 ↓                       ↓
          本象 / 本境                  影核 / 南桥
          World → AI                  AI → World
```

三条通道，前两条已有实现，第三条是本 RFC 的新增。

| 通道 | 方向 | 载荷 | 规范 | 实现状态 |
|---|---|---|---|---|
| **State Lane** | World → AI | `context.request` → `context.bundle` | RFC-0006 §1 | 已实现（bundle 编译器，含预算与丢弃声明） |
| **Action Lane** | AI → World | `action.intent` → `action.result` | RFC-0006 §2 | 已实现（risk/approval/evidence/幂等） |
| **Trust Lane** | 跨层，双向 | 授权凭据的表达与继承 | **本 RFC §3** | **未实现——头号阻塞** |

---

## 3. Trust Lane：本 RFC 的实质增量

### 3.1 三条已被实测排除的路

在定义之前先说清楚哪些路走过了、不通：

**① 全局关闸**（`--approve-for-me` / `--dangerously-bypass`）
一次性放开所有工具。与分级授权的主张直接矛盾——为了让 low 风险动作通过，
必须同时把 high 风险动作也放开。**已决定不采用**（RFC-0004 决策记录）。

**② MCP `annotations`**
MCP 2026-07-28 规范的 Tool 定义支持 `annotations`（描述工具行为的可选属性），
但规范同时写死：

> clients **MUST** consider tool annotations to be untrusted unless they come from trusted servers

两个问题：静态（per-tool，绑在工具定义上）而我们的 risk 是 per-call 算出来的
（取决于目标存不存在、是不是受保护路径）；且**默认不可信**。装不下。

**③ MCP `InputRequiredResult` + `elicitation/create`（MRTR 多轮往返）**
这个机制方向是对的：per-call、服务端发起、人在环。南桥完全可以用它表达
"这次是 medium 风险，我要你确认"。

**但它要求 `tools/call` 先到达 server。** codex 的闸门在那之前就拦了，
elicitation 永远没机会发出。

**结论：这不是标准缺失，是客户端实现缺失。** 不需要发明新协议去替代 MCP，
需要的是一层能在**现有 harness 闸门之下**工作的表达。

### 3.2 定义：授权凭据（authorization credential）

OriginBus 定义一类可跨层传递的凭据。凭据的核心性质是：

> **它证明的是"调用方做过某件事"，而不是"某人批准了调用方"。**

这个区别是关键。"批准"需要一个能弹窗的人；"证明"是无头 agent 自己拿得出的。

已验证的第一个凭据类型：

```json
{
  "kind": "trust.credential",
  "type": "proof_of_read",
  "target": "demo/x.md",
  "value": "<sha256 of target's current content>"
}
```

语义：**"证明你读过当前内容"**。

- 无头 agent 读得了文件、算得出 hash → 它能自己出示
- 没读过就想覆盖的 agent → 出示不了
- hash 过期（别人改过了）→ 自动拒绝，顺手解决静默覆盖

参考实现即影核的 `expect_sha256`，已被 43 条判据验证（正确 hash 放行、过期 hash 被拒、
被拒时磁盘未变）。**它比"你被批准了"强，因为它可核验、可离线出示、且会随世界变化自动失效。**

### 3.3 Harness Adapter：授权翻译的责任方

RFC-0000 §9 把 Harness 列为"可替换、不重新发明"，Harness Adapter 只被当作**接入/兼容**用。
实测证明它还必须承担 **Trust 职责**：

> **Adapter 负责把 OriginBus 的授权表达，翻译成目标 harness 的闸门认得的形式。**

这不是设想。已经发生过一次，只是当时没被命名：

| | |
|---|---|
| 故障 | codex 的 MCP 闸门整体堵死，南桥零记录 |
| 处置 | 加一条不经过该闸门的通道 —— CLI 驱动（shell），与 MCP 驱动共用同一个动作核心 |
| 结果 | Hermes（第三个 harness）经 CLI 落盘成功：`status=done risk=low approval=auto`，磁盘 24 字节 sha256 与自报一致，审计里 `southbridge_cli` 2 条、`southbridge_mcp` 0 条 |

**南桥 CLI 就是第一个 Harness Adapter。** 它没有降低任何授权要求——risk 分级、
批准凭据、写后观察、审计全部照跑，且与 MCP 通道判决字节级一致（parity 已验证）——
它只是换了一条 harness 认得的路把请求送进去。

因此 Adapter 的合规要求是：

1. **不得降级授权**：Adapter 换的是传输通道，不是判决规则。同一动作经不同 Adapter 必须得到相同 `action.result`（可用 parity 测试证明）。
2. **必须标记通道**：`actor` 字段记录请求从哪条通道进来（如 `southbridge_cli` / `southbridge_mcp`），否则跨层排查无从下手——**上面那次定责正是靠审计里的通道计数完成的**。
3. **不得使用全局关闸**：绕过 harness 闸门的方式必须是"走另一条它本来就信任的路"，不是"把它的闸门关掉"。

---

## 4. 一核多影：为什么 Adapter 不是过早抽象

RFC-0004 §5 曾**明确拒绝**"一核多影"的驱动抽象，理由是当时只有 1 个 driver，属过早抽象。

同日推翻，理由是实测：MCP 通道被整体堵死，第二条通道有了存在的必要。

**判据没变，证据变了。** 过早抽象的判据是"有没有第二个真实用例"，不是"有没有对称美"。
这条记在这里，是为了让后来者知道：本架构里每一个抽象层都必须能指出**逼出它的那个故障**。

```
        动作核心（风险判级 · 批准规则 · 写后观察 · action.result）
         ↑                              ↑
    MCP Adapter                    CLI Adapter          ← 只管传输与呈现
```

**Adapter 不得自己判风险、不得自己决定 status。**

---

## 5. 未决问题（诚实清单）

1. **凭据类型只有一个。** `proof_of_read` 只适用于"目标有可读的当前内容"的动作。
   启动进程、发消息、调外部 API 没有可读的"当前内容"，出示不了这类凭据。
   第二个凭据类型应该长什么样，**没有实测支撑，不猜。**

2. **凭据的传递链未实现。** 目前凭据是调用方直接给南桥的（一跳）。真正的
   "跨层继承"——Harness 收到凭据、理解其含义、据此决定放不放行——**没有任何
   harness 支持，也没法单方面实现。**

3. **codex 的 MCP 闸门仍未解。** 那是 harness 侧的 per-server 授信缺失。
   我们能做的是拿这份 RFC + 一个跑通的参考实现去推，而不是等。

4. **Adapter 的 parity 只在两条通道之间验过。** 第三条（HTTP）出现时，
   parity 测试需要扩展到 N 条，当前的两两比对写法不一定够。

---

## 6. Conformance 关联

本 RFC 为 RFC-0000 §7 的 Conformance 增加一条候选项（**尚未纳入正式清单，因为
本 RFC 的 §3.2 之外部分还没有实现**）：

> **C8（候选）— 授权可跨通道**：同一动作经不同 Harness Adapter 提交，
> 得到相同的 risk 判级与相同的 `action.result` 判决；且审计能定位通道责任。

现状：影核参考实现已满足（三场景两通道判决字节级一致 + 审计按 actor 分组可查），
但**只在一个实现上验过**，不足以定为正式 Conformance 项。

---

## 7. 与现有标准的关系

- **不替代 MCP。** MCP 的 `elicitation` / MRTR 是 Trust Lane 在 MCP transport 上的
  正确落地方式，本 RFC 推荐实现方优先使用它，而不是自造一套 RPC。
- **本 RFC 补的是 MCP 覆盖不到的那半格**：当 harness 的闸门位于 server 之上、
  且只有全局开关时，授权表达如何仍然成立。

---

**License:** Apache-2.0
