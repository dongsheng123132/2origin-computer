// load-state.mjs — SessionStart hook
// 学堂「BIOS 加载学历」：开会时找项目里最新的 task.origin.json，
// 把状态摘要以 additionalContext 注入对话开头，让 AI 从状态续上而不是问用户。
// 约定：exit 0 + 输出 { hookSpecificOutput: { hookEventName, additionalContext } }
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const projectDir = path.resolve(here, '..', '..'); // .claude/hooks -> 项目根

const SKIP = new Set(['.claude', 'node_modules', '.git', '.svn']);

function findStateFiles(dir, depth = 0) {
  if (depth > 5) return [];
  let out = [];
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return []; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (SKIP.has(e.name)) continue;
      out = out.concat(findStateFiles(full, depth + 1));
    } else if (e.name === 'task.origin.json') {
      out.push(full);
    }
  }
  return out;
}

function emit(ctx) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: ctx }
  }));
}

let newest = null, newestMtime = 0;
try {
  for (const f of findStateFiles(projectDir)) {
    const m = fs.statSync(f).mtimeMs;
    if (m > newestMtime) { newestMtime = m; newest = f; }
  }
} catch { /* ignore */ }

if (!newest) { emit(''); process.exit(0); }

let state;
try { state = JSON.parse(fs.readFileSync(newest, 'utf8')); }
catch { emit(''); process.exit(0); }

const facts = (state.facts || []).filter(f => f.verified)
  .map(f => `- ${f.claim}${f.source ? `（${f.source}）` : ''}`).join('\n');
const nextSteps = (state.next_steps || []).map((s, i) => `${i + 1}. ${s}`).join('\n');
const relPath = path.relative(projectDir, newest);

const ctx = [
  `[学堂加载 · 上次任务状态]`,
  `任务：${state.title || '(未命名)'}`,
  `目标：${state.goal || ''}`,
  `当前状态：${state.current_state || ''}`,
  `已验证事实：`,
  facts || '（暂无）',
  `下一步：`,
  nextSteps || '（暂无）',
  `完整状态文件：${relPath}`,
  `—— 请基于以上状态续上任务，不要重新问用户「任务是什么」。`
].join('\n');

emit(ctx.slice(0, 9000)); // additionalContext >1万字自动落盘，主动截断保险
process.exit(0);
