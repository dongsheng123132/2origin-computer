# 2Origin Computer Architecture

**本源计算架构 · An open architecture for persistent AI computers.**

> 我们不造模型，我们想造一台 AI 计算机。
> 模型是 CPU，但 CPU 从来不等于一台计算机。

**Status:** Draft · Request for Comments · v0.1
**License:** Apache-2.0
**原理:** Model is replaceable. State survives. Actions are portable. Learning compounds.

**中文：模型可换，状态不丢，动作可迁移，经验会复利。**

---

## 问题

今天的 Agent 栈有很好的零件：模型（CPU）、Context Window（RAM）、MCP（总线）、Harness（内核）。

但它们拼不出**一台计算机**，因为缺的是把零件装成整机的**主板、硬盘、驱动和操作系统**。

最普遍的痛点是：

> **今天教会，明天忘记。这个任务学会，下一个 Session 又从小学一年级开始。**

因为 Agent 保存的是**聊天记录**（影子），不是**对象状态**（本象）。

---

## 架构：一台 AI 计算机

| 层 | 对应 PC | 本体系 | 职责 |
|---|---|---|---|
| 智力 | CPU | **模型**（可替换） | 推理 |
| 工作内存 | RAM | **Context Window** | 当前思考 |
| 长期存储 | SSD | **本境 Benjing** | 这台 AI 学会的一切 |
| 世界表示 | 显卡 | **本象 Benxiang** | 世界 → AI 可计算的对象 |
| 动作 I/O | 南桥+驱动 | **影核 ActionParity** | 改变世界 |
| 高速总线 | 北桥 | **OriginBus** | 状态 → Context |
| 内核 | BIOS+Kernel | **Harness**（可替换） | 调度 |
| 自学习 | 系统服务 | **学堂 Academy** | 经验沉淀为学历 |
| 整机 | PC | **U-King** | 第一台参考实现 |

> **本象保存世界，本境保存成长，影核改变世界。**
> **北桥负责知，南桥负责行。**

完整闭环：`Observe → Think → Act → Verify → Learn`

---

## 已实测验证（2026-08-08 · 首测）

> 首测即通过 = 架构正确的验证信号（非刻意调参打榜）。

### ✅ 跨 Session —— 关窗再开，任务续上
独立全新 Claude Code 会话（`claude -p`，零铺垫），通过 SessionStart hook 自动收到 `task.origin.json` 摘要，**准确报出任务标题与目标**。

### ✅ 跨 Harness —— 换引擎，学历不丢
Claude Code 干一半（提炼 12 条事实）→ Codex（`codex exec`）只凭 `task.origin.json` + facts **零追问续作**。会话日志证实 Codex 从未问"任务是什么"。

### ⏳ 已知限制：无头 Harness 的写权限
Codex 沙箱只读（`-s workspace-write` 也未落盘，apply_patch 未暴露）。结论：**跨 harness 真正缺的不是状态格式，是 OriginBus Trust 层的统一写授权**——这是"南桥"的职责，已列为下一版必建组件。

---

## 仓库结构

```text
2origin-computer/
├── README.md              ← 你在这
├── rfcs/
│   └── RFC-0000-2origin-computer.md   ← 完整架构 + Conformance 标准
├── schemas/               ← 状态格式 JSON Schema（task.origin 等）
├── examples/              ← 参考实现示例
├── conformance/           ← 符合性测试清单
├── LICENSE                ← Apache-2.0
└── TRADEMARKS.md          ← 商标边界
```

---

## 怎么参与

- 读 [RFC-0000](rfcs/RFC-0000-2origin-computer.md)
- 从讨论点（第 10 节）挑一个：本境分层 / 北桥 Context 编译 / 南桥写权限 / 学堂晋升门槛
- 提 Issue 或 PR

## 商标

U-King、2Origin、本象、本境、影核、学堂、OriginBus 为商标，见 [TRADEMARKS.md](TRADEMARKS.md)。代码 Apache-2.0 开源，商标不随代码授权。
