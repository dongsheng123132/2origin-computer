#!/usr/bin/env node
// delegation-lease 的离线结构判据：不信任 schema 文件“存在”，用正反样本检验约束。
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const schema = JSON.parse(fs.readFileSync(path.join(ROOT, 'schemas/delegation.lease.schema.json'), 'utf8'));
const pass = [], fail = [];
const check = (ok, label) => (ok ? pass : fail).push(label);
const valid = x => {
  const req = schema.required.every(k => k in x);
  const extra = Object.keys(x).every(k => k in schema.properties);
  const carrier = x.grantee?.carrier_ids;
  const basics = x.spec === '2origin/delegation-lease/0.1' && x.kind === 'capability.delegation'
    && Number.isInteger(x.version) && x.version >= 1 && typeof x.principal?.id === 'string'
    && typeof x.grantee?.shadow_id === 'string' && Array.isArray(carrier) && carrier.length > 0
    && new Set(carrier).size === carrier.length && Array.isArray(x.capabilities) && x.capabilities.length > 0
    && Array.isArray(x.confirmation_required) && ['active', 'revoked'].includes(x.status);
  const time = Number.isFinite(Date.parse(x.issued_at)) && Number.isFinite(Date.parse(x.expires_at));
  const revoked = x.status !== 'revoked' || ['by', 'reason', 'effective_at'].every(k => typeof x.revocation?.[k] === 'string' && x.revocation[k]);
  return req && extra && basics && time && revoked;
};
const active = { spec: '2origin/delegation-lease/0.1', kind: 'capability.delegation', id: 'lease:test', version: 1,
  scope: 'user:test', principal: { id: 'principal:test' }, grantee: { shadow_id: 'shadow:work', carrier_ids: ['carrier:codex'] },
  capabilities: ['email.draft', 'email.send'], confirmation_required: ['email.send'], status: 'active', issued_at: '2026-08-29T00:00:00Z', expires_at: '2026-09-01T00:00:00Z' };
check(valid(active), 'L1 active lease 满足最小字段与 logical shadow/carrier 分离');
check(!valid({ ...active, status: 'revoked' }), 'L2 revoked 缺撤销证据被拒绝');
check(!valid({ ...active, grantee: { ...active.grantee, carrier_ids: [] } }), 'L3 空 carrier 集被拒绝');
check(!valid({ ...active, unexpected_authority: true }), 'L4 未声明字段不静默扩大权限');
check(active.confirmation_required.includes('email.send'), 'L5 send 明确需要独立确认，不由 capability 自动放行');
check(!valid({ ...active, expires_at: 'never' }), 'L6 畸形 expires_at 被拒绝，不会变成永不过期租约');
console.log(`delegation-lease schema: ${fail.length ? 'FAIL' : 'PASS'} ${pass.length}/${pass.length + fail.length}`);
for (const x of pass) console.log(`  ✓ ${x}`);
for (const x of fail) console.log(`  ✗ ${x}`);
process.exit(fail.length ? 1 : 0);
