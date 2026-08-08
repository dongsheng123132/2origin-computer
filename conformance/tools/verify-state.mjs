// verify-state.mjs — C5 结果可验证：通过观察现实验证，不是信 exit code
// 读 task.origin.json，检查：
//   1. 声称的 artifacts[] 是否真实存在（观察现实文件系统）
//   2. facts[] 里 verified:true 的 claim 是否都有 source（可信度）
//   3. next_steps 与 current_state 是否自洽（完成度）
// 输出真正的 VERIFY 结论，不信任任何「我说我完成了」。
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(here, '..');

const statePath = process.argv[2] || path.join(ROOT, 'demo/task1/task.origin.json');

function main() {
  if (!fs.existsSync(statePath)) { console.error('❌ 状态文件不存在:', statePath); process.exit(1); }

  let s;
  try { s = JSON.parse(fs.readFileSync(statePath, 'utf8')); }
  catch (e) { console.error('❌ 状态文件解析失败:', e.message); process.exit(1); }

  const report = { id: s.id, passed: [], failed: [], missing: [] };

  // CHECK 1: artifacts 真实存在（以状态文件所在目录为基准解析）
  const stateDir = path.dirname(path.resolve(statePath));
  for (const a of (s.artifacts || [])) {
    const p = path.isAbsolute(a) ? a : path.resolve(stateDir, a);
    if (fs.existsSync(p)) report.passed.push(`artifact存在: ${a}`);
    else report.failed.push(`artifact缺失: ${a}`);
  }

  // CHECK 2: verified facts 必须有 source
  for (const f of (s.facts || [])) {
    if (f.verified && !f.source) report.failed.push(`verified fact 缺 source: ${f.claim.slice(0,40)}`);
    else if (f.verified) report.passed.push(`fact 有source: ${f.claim.slice(0,30)}`);
  }

  // CHECK 3: next_steps 自洽性——current_state 提到"完成"的不能还在 next_steps
  const cs = s.current_state || '';
  const completedMentions = cs.includes('完成') || cs.includes('验收通过') || cs.includes('绿');
  if (completedMentions && (s.next_steps || []).length > 0) {
    // 可能已完成但还有后续，不武断判失败，给 warning
    report.missing.push(`提示: current_state 似已完成，但 next_steps 仍有 ${s.next_steps.length} 项`);
  }

  // SUMMARY
  const total = report.passed.length + report.failed.length;
  console.log(`\n═══ VERIFY: ${s.id} ═══`);
  console.log(`目标: ${s.goal || '(无)'}`);
  console.log(`current_state: ${s.current_state || '(无)'}\n`);
  console.log(`✅ 通过 ${report.passed.length} 项:`);
  report.passed.forEach(x => console.log(`   • ${x}`));
  if (report.failed.length) {
    console.log(`\n❌ 失败 ${report.failed.length} 项:`);
    report.failed.forEach(x => console.log(`   • ${x}`));
  }
  if (report.missing.length) {
    console.log(`\n⚠️ 待确认 ${report.missing.length} 项:`);
    report.missing.forEach(x => console.log(`   • ${x}`));
  }

  const verdict = report.failed.length === 0 ? '✅ VERIFIED (通过现实观察确认)' : '❌ NOT VERIFIED';
  console.log(`\n判决: ${verdict}`);
  process.exit(report.failed.length === 0 ? 0 : 1);
}

main();
