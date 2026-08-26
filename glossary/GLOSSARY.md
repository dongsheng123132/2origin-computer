# 术语映射表（Glossary）v1

> 真源文件：`glossary/terms.yaml`（机器可读，CI 消费）。本 README 是人读版。
> 铁律：**每个新术语必须登记在这里并指向一个已存在的宿主（repo/schema/crate 文件）；没有宿主的词一律标 `UNIMPLEMENTED`。** 未登记的名词不允许出现在任何仓的代码与文档里。
> 改动流程：只能 PR 到本仓（2origin-computer），其他仓只读引用；改一条 = version +1。

## 五原语 × 现有资产总览

| 原语 | 中文名 | 一句话定义 | 宿主（现有零件） | 状态 |
|---|---|---|---|---|
| signal | 信号 | 带来源、时间、隐私等级的「世界发生了什么」 | 本象 Observation/Claim；envelope `kind`+`provenance` | PARTIAL |
| capability | 能力 | 一个器官可声明的、可验证的规范动作 | 影核 action-parity 规范动作；dsh-capability-receipt | PARTIAL |
| lease | 租约 | 临时的、条件化的、可撤销的能力使用权；委托链上权限只减不增 | dsh principal-binding + policy-waiver 零件 | PARTIAL |
| receipt | 回执 | 可离线验证的「谁在什么授权下干了什么、结果如何」 | dsh audit-bundle / lineage / decision-effect | PARTIAL |
| work | 工作接力 | 任务带 verified state 跨模型/跨机续命：Work→Checkpoint→Handoff | task-passport `task.origin.json`（schema 冻结） | PARTIAL |
| realm | 域 | 插件的隔离世界：能力作用域+配置作用域+退出即消失 | （无） | **UNIMPLEMENTED** |

## 支撑术语

| 术语 | 定义 | 宿主 | 状态 |
|---|---|---|---|
| envelope | 统一对象信封：所有重要对象共用的审计/同步/验证外壳 | `schemas/envelope.schema.json` | IMPLEMENTED |
| principal | 主体：一切授权和责任的最终归属者（人，或人所委托的节点） | dsh principal-binding | PARTIAL |
| verified fact | 已验证事实：被观察/测试证实过的 claim，不是会话里说过的话 | `task.origin.json` 的 `facts[].claim+verified+source` | IMPLEMENTED |
| trust lane | 授权凭证通道：`trust.credential` / proof_of_read | 2origin-harness `lib/verify.js` 等 | IMPLEMENTED |
| golden trace | 黄金轨迹：跨仓共享的事件序列 fixture，任何实现改动必须重放一致 | （待建 `conformance/traces/`） | UNIMPLEMENTED |
| organ | 器官：提供 signal 与 capability 的设备/进程/传感器 | （概念来自设计笔记，kernel API 未建） | UNIMPLEMENTED |
| plugin | 插件：内核之外的一切（模型/记忆/UI/自动化）皆可替换拔除 | DSH 生态先例；kernel 侧未建 | UNIMPLEMENTED |

## 反例（什么是错的）

- 把「长期记忆」「情感陪伴」「推荐系统」当内核概念 —— 它们是插件。
- 同一概念在各仓另起名字（如把 Work 写成 Session、把 Lease 写成 Token）—— 抓到即回本表裁决。
- 只有哲学定义没有代码宿主的词 —— 不允许进入任何仓。

## 版本

- v1 · 2026-08-26 · 初版登记：五原语+7 支撑术语。signal/work 的宿主映射为初判，待各仓 owner 复核。
