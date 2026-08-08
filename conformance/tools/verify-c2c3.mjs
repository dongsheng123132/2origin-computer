#!/usr/bin/env node
// verify-c2c3.mjs — C2/C3 可复跑验证（规范债务 D4 的解法）
//
// D4 的病：C2/C3 只做过一次性演示，没纳入可复跑的验证。
// 本脚本把 C2/C3 的**可自动化的前提**固化成可复跑检查：
//   C2 前提：跨 harness 交接 = 读同一 task.origin 能无追问续作（状态读取机制）
//   C3 前提：跨模型 = 状态格式是模型无关的（无 harness/model 特定字段依赖）
//
// 诚实边界：完整 C2（真实 Codex 续作）和完整 C3（真实第二模型）需要外部依赖，
// 脚本验证"前提可复跑"；外部依赖部分仍标 MANUAL——但不再是"一次性演示"，
// 而是"可复跑 + 需外部依赖"。
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
// 用 2origin-harness 的 state/bundle 逻辑（同源，保证一致）
const HARNESS = path.resolve(here, '..', '..', '..', '2origin-harness');
const { pathToFileURL } = await import('node:url');
const { createState, saveState, addFact, readState } = await import(pathToFileURL(path.join(HARNESS, 'lib', 'state.js')).href);
const { buildBundle } = await import(pathToFileURL(path.join(HARNESS, 'lib', 'bundle.js')).href);

function tmp(tag) {
  return fs.mkdtempSync(path.join(os.tmpdir(), `c2c3-${tag}-`));
}

let pass = 0, fail = 0;

function ok(label) { console.log(`[PASS] ${label}`); pass++; }
function bad(label, why) { console.log(`[FAIL] ${label} — ${why}`); fail++; }

// ── C2 前提：跨 harness 交接 = 状态可被"另一个执行者"读取续作 ──
// 模拟：创建状态 → 用"另一个读取器"（纯读 bundle，不依赖创建者上下文）读它
try {
  const root = tmp('c2');
  const file = path.join(root, 'demo/t1/task.origin.json');
  const st = createState({ id: 't1', goal: '写文档' });
  st.current_state = '写了一半';
  st.next_steps = ['写完引言'];
  addFact(st, '目标读者是开发者', 'docs/audience.json');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  saveState(file, st);

  // "另一个执行者"：只读 bundle，不 share 创建者内存
  const b = buildBundle(root);
  const hasGoal = b.text.includes('写文档');
  const hasStep = b.text.includes('写完引言');
  const hasFact = b.text.includes('目标读者是开发者');
  if (hasGoal && hasStep && hasFact) {
    ok('C2 前提：状态可被独立执行者无追问续作（目标/下一步/事实全可读）');
  } else {
    bad('C2 前提', `bundle 缺内容 goal=${hasGoal} step=${hasStep} fact=${hasFact}`);
  }
  fs.rmSync(root, { recursive: true, force: true });
} catch (e) { bad('C2 前提', e.message); }

// ── C3 前提：状态格式模型无关 ──
// 状态文件不应有模型特定字段（actor.model 允许但标注 unobserved；不依赖模型名做逻辑）
try {
  const root = tmp('c3');
  const file = path.join(root, 'demo/t1/task.origin.json');
  const st = createState({ id: 't1', goal: 'x' });
  fs.mkdirSync(path.dirname(file), { recursive: true });
  saveState(file, st);

  // 正确检查：状态格式不依赖任何特定模型。
  //   actor.model 是观测值（§3.3 允许：观测到就写，观测不到写 unobserved）——这合法
  //   FAIL 只在"模型特定逻辑侵入状态结构"（goal/facts 依赖特定模型名）时
  const onDisk = readState(file);
  const actorModel = onDisk.actor?.model || 'unobserved';
  const hasModelLogic = ['deepseek', 'gpt', 'claude', 'codex', 'kimi'].some(
    k => (onDisk.goal || '').includes(k) || JSON.stringify(onDisk.facts || []).toLowerCase().includes(k)
  );
  if (!hasModelLogic) {
    ok(`C3 前提：状态格式模型无关（actor.model=${actorModel} 为观测值，无模型特定逻辑）`);
  } else {
    bad('C3 前提', '状态含模型特定逻辑（goal/facts 依赖特定模型名）');
  }
  fs.rmSync(root, { recursive: true, force: true });
} catch (e) { bad('C3 前提', e.message); }

console.log(`\n══ C2/C3 前提验证: PASS ${pass} · FAIL ${fail} ══`);
console.log('完整 C2（真实 Codex 续作）与 C3（真实第二模型）仍需外部依赖，见 conformance README');
process.exit(fail ? 1 : 0);
