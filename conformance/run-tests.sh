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

# ── C10 状态 vs 对话流（ShadowWork Bench v0.2：真实语料 + 真实模型）──
# 默认只跑 --dry-run（免费、离线）：验证语料真实、题目可构造、两臂预算对齐。
# 真打模型一次约 270 万输入 token，要花钱，所以必须显式 SHADOWWORK_LIVE=1。
# 「会悄悄花钱的 conformance 项」本身就是缺陷，这里把花钱做成显式开关。
say ""
say "── C10 State vs Transcript (ShadowWork Bench v0.2) ──"
V2="$ROOT/../2origin-harness/bench/shadowwork-bench-v2.mjs"
if [ -f "$V2" ] && command -v node >/dev/null 2>&1; then
  DRY=$(node "$V2" --dry-run 2>/dev/null)
  BUNDLE_N=$(printf '%s' "$DRY" | grep -oE 'arm 2origin +payload +[0-9]+' | grep -oE '[0-9]+$')
  TRANS_N=$(printf '%s' "$DRY" | grep -oE 'arm transcript +payload +[0-9]+' | grep -oE '[0-9]+$')
  REAL_T=$(printf '%s' "$DRY" | grep -cE '\.jsonl \([0-9]+ B\)')
  if [ -z "$BUNDLE_N" ] || [ -z "$TRANS_N" ]; then
    manual "C10" "bench v0.2 dry-run 无输出（缺学历语料或真实会话记录，见 bench/RESULTS-v2.md）"
  elif [ "$BUNDLE_N" != "$TRANS_N" ]; then
    fail "C10 预算对齐" "两臂 payload 不等长（$BUNDLE_N vs $TRANS_N）——对照不成立"
  elif [ "$REAL_T" -lt 1 ]; then
    fail "C10 语料真实性" "对照组没有真实会话记录，退化成自己生成的稻草人（正是 C9 的病）"
  elif [ "${SHADOWWORK_LIVE:-0}" = "1" ]; then
    OUT=$(node "$V2" --facts 40 --mc-facts 10 --max-tokens 8000 2>/dev/null)
    if printf '%s' "$OUT" | grep -q 'finish_reason=length'; then
      fail "C10" "有调用被 max-tokens 截断，该臂分数不可用——调大 --max-tokens 重跑"
    else
      pass "C10 真跑：$(printf '%s' "$OUT" | grep '同预算对照')"
    fi
  else
    pass "C10 结构检查通过（对照组 ${REAL_T} 份真实会话记录，两臂预算对齐 ${BUNDLE_N}B）—— 打模型需 SHADOWWORK_LIVE=1"
  fi
else
  manual "C10" "缺 shadowwork-bench-v2.mjs 或 node（见 2origin-harness/bench）"
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
