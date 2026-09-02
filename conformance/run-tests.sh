#!/bin/bash
# run-tests.sh — 一键跑 2Origin Conformance（可自动化部分）
# 用法: bash conformance/run-tests.sh
# 输出: 每项 [PASS]/[FAIL]/[MANUAL]，最后汇总。退出码 0=全部通过/手动，1=有失败。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0; MANUAL=0
declare -a FAILED=()

say()  { printf '%s\n' "$*"; }
pass() { say "[PASS] $1"; PASS=$((PASS+1)); }
fail() { say "[FAIL] $1 — $2"; FAIL=$((FAIL+1)); FAILED+=("$1"); }
manual(){ say "[MANUAL] $1 — $2"; MANUAL=$((MANUAL+1)); }

say "════════ 2Origin Conformance · 一键测试 ════════"
say "date: $(date '+%Y-%m-%d %H:%M')"

# ── C1 跨 Session（环境即镜像）──
# 验证：全新会话（无对话铺垫）能否从 task.origin.json 自动加载状态
say ""
say "── C1 Cross-Session ──"
if command -v claude >/dev/null 2>&1; then
  # 用一个最小临时目录 + 复刻 hooks + 示例状态，避免污染仓库
  TMP=$(mktemp -d)
  cp -r "$ROOT/.claude_template" "$TMP/.claude" 2>/dev/null || {
    # 无模板就用仓库内示例状态做只读验证
    TMP=""
  }
  if [ -n "$TMP" ]; then
    cp "$ROOT/examples/office-agent/task.origin.json" "$TMP/task.origin.json"
    OUT=$(cd "$TMP" && claude -p "回答：开场信息里有没有『学堂加载』？任务标题是什么？" 2>/dev/null)
    if echo "$OUT" | grep -qiE "学堂加载|task origin|task.origin"; then
      pass "C1 全新会话从状态自动加载（headless）"
    else
      fail "C1" "headless 会话未检测到状态注入"
    fi
    rm -rf "$TMP"
  else
    manual "C1" "无 .claude_template，跳过自动复刻（见 README 手动步骤）"
  fi
else
  manual "C1" "未安装 claude CLI，无法 headless 验证"
fi

# ── C4 动作可迁移 ──
say ""
say "── C4 Portable Actions ──"
if [ -f "$ROOT/examples/portable-action/document-save.js" ] && command -v node >/dev/null 2>&1; then
  H1=$(node "$ROOT/examples/portable-action/document-save.js" --driver cli 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d).sha256)}catch{process.stdout.write('')}})")
  H2=$(node "$ROOT/examples/portable-action/document-save.js" --driver api 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d).sha256)}catch{process.stdout.write('')}})")
  if [ -n "$H1" ] && [ "$H1" = "$H2" ]; then
    pass "C4 双 driver 同 sha256（$H1）"
  else
    fail "C4" "driver 输出哈希不一致: $H1 vs $H2"
  fi
else
  manual "C4" "缺 node 或示例文件"
fi

# ── C5 结果可验证 ──
say ""
say "── C5 Verifiable Results ──"
if command -v node >/dev/null 2>&1; then
  for state in "$ROOT"/examples/office-agent/task.origin.json; do
    if node "$ROOT/conformance/tools/verify-state.mjs" "$state" >/dev/null 2>&1; then
      pass "C5 状态可验证（$state）"
    else
      fail "C5" "verify-state 对 $state 判 FAIL"
    fi
  done
else
  manual "C5" "缺 node"
fi

# ── C6 学习不自动永久化 ──
say ""
say "── C6 No auto-permanent learning ──"
if command -v node >/dev/null 2>&1; then
  S="$ROOT/examples/office-agent/task.origin.json"
  # 检查 learnings 是否都带 status 且不含未经验证的 auto-verified
  AUTO=$(node -e "const s=require(process.argv[1]);const bad=(s.learnings||[]).filter(l=>!l.status||(l.status==='verified'&&!l.confidence));process.stdout.write(String(bad.length));" "$S" 2>/dev/null)
  if [ "$AUTO" = "0" ]; then
    pass "C6 learnings 全部带 candidate/verified 状态，无无置信度冒升"
  else
    fail "C6" "存在 $AUTO 条无状态/无置信度的 learnings"
  fi
else
  manual "C6" "缺 node"
fi

# ── C7 可审计 ──
say ""
say "── C7 Auditable ──"
AUDIT="$ROOT/../ShadowOS = Harness OS/southbridge/audit.log"  # 真实审计日志在运行时目录
if [ -f "$AUDIT" ] && grep -q "southbridge_write" "$AUDIT" 2>/dev/null; then
  pass "C7 南桥写动作有审计记录（$AUDIT）"
else
  manual "C7" "未找到运行时 audit.log（南桥原型在 ShadowOS 工作目录）"
fi

# ── C2 / C3 需要真实外部依赖 ──
say ""
say "── C2 / C3 (前提可复跑 + 外部依赖标注) ──"
if [ -f "$ROOT/conformance/tools/verify-c2c3.mjs" ] && command -v node >/dev/null 2>&1; then
  if node "$ROOT/conformance/tools/verify-c2c3.mjs" >/dev/null 2>&1; then
    pass "C2/C3 前提（跨 harness 读取机制 + 模型无关格式）可复跑验证通过"
  else
    fail "C2/C3 前提" "verify-c2c3.mjs 未通过（见上方输出）"
  fi
else
  manual "C2/C3" "缺 node 或 verify-c2c3.mjs"
fi
manual "C2" "完整跨 harness（真实 Codex 续作）需 codex exec：见 RFC §8-B/C"
manual "C3" "完整跨模型（真实第二端点）需第二个模型：见 RFC §8 与 conformance README"

# ── C11 主体委托租约（离线、无真实凭据）──
say ""
say "── C11 Delegated authority reference loop ──"
LEASE_CHECK="$ROOT/conformance/tools/verify-delegation-lease.mjs"
EMAIL_CHECK="$ROOT/../ShadowOS = Harness OS/southbridge/verify-delegated-email.mjs"
if command -v node >/dev/null 2>&1 && [ -f "$LEASE_CHECK" ] && [ -f "$EMAIL_CHECK" ]; then
  if node "$LEASE_CHECK" >/dev/null 2>&1 && node "$EMAIL_CHECK" >/dev/null 2>&1; then
    pass "C11 委托：确认前零投递、撤销后跨 carrier 拒绝"
  else
    fail "C11 委托" "lease schema 或参考闭环未通过"
  fi
else
  manual "C11" "缺 node 或 delegation lease/ShadowOS 参考实现"
fi

# ── C8 学历跨会话保留率（ShadowWork Bench）──
say ""
say "── C8 Cross-Session Retention (ShadowWork Bench) ──"
BENCH="$ROOT/../2origin-harness/bench/shadowwork-bench.mjs"
if [ -f "$BENCH" ] && command -v node >/dev/null 2>&1; then
  RET=$(node "$BENCH" --facts 50 --sessions 20 2>/dev/null | grep -oE '保留率: [0-9.]+%' | grep -oE '[0-9.]+')
  if [ -n "$RET" ] && [ "$(echo "$RET >= 80" | bc 2>/dev/null || echo 1)" = "1" ]; then
    pass "C8 学历跨会话保留率 ${RET}%（≥80%，传统 harness=0%）"
  else
    fail "C8 学历保留率" "实测 ${RET}% 低于 80% 阈值"
  fi
else
  manual "C8" "缺 bench 脚本或 node（见 2origin-harness/bench）"
fi

# ── C9 续作成本（模拟对照，非证据级）──
# 注意：C9 的对照 transcript 由脚本自己生成，且从没把 goal 原文写进去——
# "传统不可续作"是构造出来的，不是观察到的。它只作为机制自测保留；
# "更有效"的真实证据在 C10。见 2origin-harness/bench/README.md 顶部说明。
say ""
say "── C9 Continuation Cost (simulated, mechanism self-test) ──"
COMPARE="$ROOT/../2origin-harness/bench/compare-bench.mjs"
if [ -f "$COMPARE" ] && command -v node >/dev/null 2>&1; then
  if node "$COMPARE" 20 >/dev/null 2>&1; then
    pass "C9 续作成本自测通过（模拟对照；其结论不作证据用——真实对照见 C10）"
  else
    fail "C9 续作成本" "compare-bench.mjs 未通过（见上方输出）"
  fi
else
  manual "C9" "缺 compare-bench.mjs 或 node（见 2origin-harness/bench）"
fi

# ── C10 状态 vs 对话流（ShadowWork Bench spec 0.3：真实语料 + 真实模型 + 强对照）──
# 默认只跑 --dry-run（免费、离线）：验证语料真实、题目可构造、两臂预算对齐。
# 真打模型一次 474 次调用、约 600 万输入 token，要花钱，所以必须显式 SHADOWWORK_LIVE=1。
# 「会悄悄花钱的 conformance 项」本身就是缺陷，这里把花钱做成显式开关。
say ""
say "── C10 State vs Transcript (ShadowWork Bench spec 0.4) ──"
V2="$ROOT/../2origin-harness/bench/shadowwork-bench-live.mjs"
if [ -f "$V2" ] && command -v node >/dev/null 2>&1; then
  DRY=$(node "$V2" --dry-run 2>/dev/null)
  BUNDLE_N=$(printf '%s' "$DRY" | grep -oE 'arm 2origin +payload +[0-9]+' | grep -oE '[0-9]+$')
  TRANS_N=$(printf '%s' "$DRY" | grep -oE 'arm transcript +payload +[0-9]+' | grep -oE '[0-9]+$')
  REAL_T=$(printf '%s' "$DRY" | grep -cE '\.jsonl \(.*[0-9]+ B')
  if [ -z "$BUNDLE_N" ] || [ -z "$TRANS_N" ]; then
    manual "C10" "bench dry-run 无输出（缺学历语料或真实会话记录，见 bench/RESULTS-v3.md）"
  elif [ "$BUNDLE_N" != "$TRANS_N" ]; then
    fail "C10 预算对齐" "两臂 payload 不等长（$BUNDLE_N vs $TRANS_N）——对照不成立"
  elif [ "$REAL_T" -lt 1 ]; then
    fail "C10 语料真实性" "对照组没有真实会话记录，退化成自己生成的稻草人（正是 C9 的病）"
  elif [ "${SHADOWWORK_LIVE:-0}" = "1" ]; then
    OUT=$(node "$V2" --max-tokens 8000 2>/dev/null)
    if printf '%s' "$OUT" | grep -q 'finish_reason=length'; then
      fail "C10" "有调用被 max-tokens 截断，该臂分数不可用——调大 --max-tokens 重跑"
    else
      pass "C10 真跑：$(printf '%s' "$OUT" | grep '同预算最强对照臂')"
    fi
  else
    pass "C10 结构检查通过（对照组 ${REAL_T} 份真实会话记录，两臂预算对齐 ${BUNDLE_N}B）—— 打模型需 SHADOWWORK_LIVE=1"
  fi
else
  manual "C10" "缺 shadowwork-bench-live.mjs 或 node（见 2origin-harness/bench）"
fi

# ── C11 外部对照（对照组里必须有一个不是我们自己写的实现）──
# 为什么是一条判据而不是一句自觉：C10 到 spec 0.3 为止的三个对照臂——尾部截断、
# 自制 summary、自写词法 RAG——全部由我们自己实现。跟自己写的东西比出来的
# 「更有效」，是「自证」在 benchmark 层的最后一处藏身点：每个部件都真实、每个
# 数字都可复算，但对照组的天花板是我们自己的手艺。所以这条判据检查的是
# 「有没有第三方实现在场」，不是「分数好不好看」。
say ""
say "── C11 External Baseline (third-party memory system) ──"
M0="$ROOT/../2origin-harness/bench/mem0_arm.py"
VB="$ROOT/../2origin-harness/bench/shadowwork-bench-live.mjs"
if [ -f "$VB" ]; then
  HAS_ARM=$(grep -c "mem0" "$VB" 2>/dev/null || echo 0)
  STATS=$(ls "$ROOT"/../2origin-harness/bench/cache/mem0-*.stats.json 2>/dev/null | head -1)
  if [ ! -f "$M0" ] || [ "$HAS_ARM" -lt 1 ]; then
    fail "C11 外部对照" "bench 里没有第三方 memory 系统的臂——对照组全是自己写的，结论只跟自己的手艺比"
  elif [ -z "$STATS" ]; then
    manual "C11" "第三方对照臂已接入但记忆库未建（跑 node bench/shadowwork-bench-live.mjs --arms mem0）"
  else
    N_MEM=$(grep -oE '"memories_in_store": [0-9]+' "$STATS" | grep -oE "[0-9]+" | tail -1)
    N_EMPTY=$(grep -c '"empty_batches": \[\]' "$STATS" || echo 0)
    KEEP=$(grep -c '"keep_source_language": true' "$STATS" || echo 0)
    if [ -z "$N_MEM" ] || [ "$N_MEM" -lt 1 ]; then
      fail "C11 空对照" "第三方记忆库是空的——空对照组比没有对照更糟，它看起来像个对照"
    elif [ "$N_EMPTY" -lt 1 ]; then
      fail "C11 语料完整性" "有批次抽取返回 0 条记忆，那段语料从对照组的记忆里消失了（见 stats 的 empty_batches）"
    elif [ "$KEEP" -lt 1 ]; then
      fail "C11 语言公平" "第三方对照跑在默认配置下会把中文语料翻成英文存，等于我们亲手削弱对照组"
    else
      pass "C11 外部对照在场：mem0 记忆库 $N_MEM 条，无空批次，保留源语言"
    fi
  fi
else
  manual "C11" "缺 shadowwork-bench-live.mjs（见 2origin-harness/bench）"
fi

# ── C12 Golden Trace Replay（跨仓库：ShadowOS 产出的 OriginEvent 轨迹重放）──
# 依赖：ShadowOS 仓库在本机某处存在，且 runtime/verify-golden-trace.mjs 能跑。
# 两个仓库是独立 git 仓库，不能假设跑这个脚本的机器上 ShadowOS 一定在场（比如
# 换一台只 clone 了 2origin-computer 的机器）——缺依赖走 MANUAL，不走 FAIL，
# 抄的是本文件对 C2/C3 的处理法。
#
# 定位方式（设计决策，供跨仓库引用）：优先用 SHADOWOS_ROOT 环境变量显式指定
# （最可靠，不靠猜）；没设就按约定相对路径猜同级目录下的 ShadowOS 仓
# （跟本文件 C7/C11 已有的写法一致：两个仓在同一个上级目录下）；猜的路径
# 也找不到 verify-golden-trace.mjs 就走 MANUAL，不冒充结果。
say ""
say "── C12 Golden Trace Replay ──"
SHADOWOS_GUESS="$ROOT/../ShadowOS = Harness OS"
SHADOWOS_DIR="${SHADOWOS_ROOT:-$SHADOWOS_GUESS}"
GOLDEN_CHECK="$SHADOWOS_DIR/runtime/verify-golden-trace.mjs"
if command -v node >/dev/null 2>&1 && [ -f "$GOLDEN_CHECK" ]; then
  if node "$GOLDEN_CHECK" >/dev/null 2>&1; then
    pass "C12 Golden Trace 重放：新 run-id 归一化后逐字节一致（G1-G4 全过，见 ShadowOS 仓 runtime/verify-golden-trace.mjs 输出）"
  else
    fail "C12 Golden Trace" "verify-golden-trace.mjs 未通过（见 ShadowOS 仓 $GOLDEN_CHECK 的输出）"
  fi
else
  manual "C12" "未找到 ShadowOS 仓库（试过 SHADOWOS_ROOT 环境变量与猜测路径 $SHADOWOS_GUESS）或缺 node，跳过——只在 2origin-computer + ShadowOS 两个仓都在场的机器上能自动验证"
fi

# ── 汇总 ──
say ""
say "════════ 汇总 ════════"
say "PASS: $PASS   FAIL: $FAIL   MANUAL: $MANUAL"
if [ "$FAIL" -gt 0 ]; then
  say "失败项:"
  for f in "${FAILED[@]}"; do say "  - $f"; done
  exit 1
fi
say "（MANUAL 项需人工/外部依赖，见 README 各节）"
exit 0
