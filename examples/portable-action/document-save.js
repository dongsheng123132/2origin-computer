// document-save.js — C4 动作可迁移演示
// 同一动作 `document.save`，两种 driver 实现，结果必须一致。
//   - CLI driver:  argv --driver cli
//   - API driver:  argv --driver api
// 动作层不依赖底层实现（这就是影核 ActionParity 的最小演示）。
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));

// ---- 动作核心：document.save（与 driver 无关）----
function documentSave(content, targetPath) {
  fs.writeFileSync(targetPath, content, 'utf8');
  const data = fs.readFileSync(targetPath, 'utf8');
  const sha = createHash('sha256').update(data).digest('hex');
  return { targetPath, bytes: data.length, sha256: sha };
}

// ---- CLI driver：用命令行写（传统 I/O 通道）----
function cliDriver(content, target) {
  return documentSave(content, target);
}

// ---- API driver：用函数调用写（高速 I/O 通道）----
function apiDriver(content, target) {
  return documentSave(content, target);
}

// ---- 北桥：告诉 CPU 此刻该用哪个 driver ----
function northbridge(driver) {
  // 北桥负责"知"：决定用哪个通道。这里按入参选，可扩展为按延迟/成本路由。
  return driver === 'api' ? apiDriver : cliDriver;
}

const driverName = process.argv[2]?.split('=')[1] || 'cli';
const content = `这是 document.save 动作的测试内容。\ndriven by: ${driverName}\n`;
const target = path.join(here, `out-${driverName}.md`);

const fn = northbridge(driverName);
const result = fn(content, target);

console.log(JSON.stringify(result, null, 2));
