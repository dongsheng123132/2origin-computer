# RFC-0007：主体委托租约（delegation-lease/0.1）

## 状态

Candidate。此 RFC 的正式名只在其判据存在时有效；参考实现与反向判据在 ShadowOS 的
`southbridge/delegated-email-core.mjs` 和 `southbridge/verify-delegated-email.mjs`。

## 问题

`task.origin` 能交接工作，`lease` 已声明“权限只减不增”，但尚无一个可运行对象回答：
哪个主体将哪项能力授给哪个逻辑代理、在哪些承载实例上生效、何时须本人确认、怎样撤销。

本 RFC 不把模型、聊天记录或“像某个人的程度”当作身份。它只定义可判定的委托边界。

## 对象

唯一格式是 [`schemas/delegation.lease.schema.json`](../schemas/delegation.lease.schema.json)。

- `principal.id`：授权与责任的最终归属。不规定认证实现；生产环境须由外部身份根签发。
- `grantee.shadow_id`：逻辑代理身份；`carrier_ids` 是本次明确可承载它的实例。换模型/复制实例不会自动加入。
- `capabilities`：允许的 Action ID；委托链下游只能取子集。
- `confirmation_required`：高风险动作的额外门槛。具备 `email.send` 不表示能无确认发送。
- `status=revoked` + `revocation`：终态。所有 carrier 在每次高风险动作提交前必须重新读取它。

## 最小状态机

`active -> revoked`，不可反向。到期与撤销同样拒绝动作；续期必须签发新 lease，不能改回旧对象。

动作允许当且仅当：

```text
lease active 且未到期
∩ carrier_id 已列入 lease
∩ action_id 已列入 capabilities
∩ （action 不在 confirmation_required 或存在绑定该 effect 的本人确认）
```

这是一条运行时闸门，不是 UI 约定。任务护照只能携带 lease 引用，不能带来更大的权力。

## 范围与非目标

v0.1 的可运行参考场景是“代拟邮件”：代理可 `email.draft`，`email.send` 需要确认；发送为
落盘 carrier mock，绝不连接 SMTP、API key 或真实收件人。测试中的 `principal`/approval 是
明确标为 `test_only` 的本地证据，**不是**生产身份认证或电子签名。

生产实现另需不可伪造身份根、签名、密钥隔离、撤销分发和外部时间锚；不得把本 RFC 的 demo
当成已解决这些问题的声明。

## 一致性要求

符合本 RFC 的实现至少须证明：

1. 未确认发送零写入；
2. 未列入的 carrier 被拒绝；
3. lease 撤销后发送被拒绝且发送物不变；
4. 同一幂等键不能造成第二次发送；
5. 每次准许或拒绝都有可观察审计记录；
6. 执行体不能自行将 lease 或 approval 认定为有效。
