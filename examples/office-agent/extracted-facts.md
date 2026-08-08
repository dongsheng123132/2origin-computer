# office-agent · extracted-facts.md — STEP-A artifact

> 从 `source-note.md`（12 条全球 harness 最佳实践）提炼的结构化 facts。本文件是 `task.origin.json` 声明的 artifact，也是 STEP-B（Codex）接续的输入。

| # | 事实（claim） | verified | source |
|---|---|---|---|
| 1 | 模型≈CPU，Harness≈运行时/OS；文件系统=持久内存 | true | Lilian Weng, Harness Engineering |
| 2 | 评测从单任务转向长循环稳定性（LoopsBench） | true | arXiv 2608.00267 |
| 3 | 训练 Harness Engineer 读 failure 出 patch | false（需 RL） | Harness-R1, arXiv 2608.02276 |
| 4 | Harness 按任务动态组装（Experience Bank） | true | MemoHarness, arXiv 2607.14159 |
| 5 | 任务结束经验不结束（procedural repair） | true | Living-Harness, arXiv 2607.26598 |
| 6 | 跨 Agent 交换 Harness 改进不交换数据 | true | EvolveNet, arXiv 2608.04968 |
| 7 | 长期保存 State+Verified Facts，不是聊天记录 | true | LongHorizon-Harness, arXiv 2608.01964 |
| 8 | 跨 5 模型保持同一 Harness | true | OneDayAgent, arXiv 2608.05013 |
| 9 | 榜单从 Model 变 Model×Harness | true | HarnessOpt-Bench, arXiv 2608.06301 |
| 10 | 最强 Skill-Use 分数仅 0.613 | true | Skill-Use Benchmark, arXiv 2608.04828 |
| 11 | 只换 orchestration：Token -38% 成本 -41% | true | arXiv 2607.06906 |
| 12 | 小模型+好 Harness 达大模型 89.7% 性能 | true | arXiv 2607.08938 |

**元数据**：STEP-A 产物 · 交接对象给 STEP-B（Codex）。
