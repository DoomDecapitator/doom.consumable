// .github/tools/check_dist.mjs —— 发行物可复现性检查。
//
//   node .github/tools/check_dist.mjs           # 检查
//   node .github/tools/check_dist.mjs --write   # 重新打 zip 并更新 SHA256SUMS.txt
//
// 查三件事：
//   ① zip 与包体逐字节一致 —— 解 zip，逐文件与仓库里的包体比对。
//      为什么：玩家从 Releases 下的 zip，和他在网页上点开的源码必须一样。
//      不一致说明有人改过一边忘了另一边，或者手工动过 zip。
//   ② sha256 与 SHA256SUMS.txt 一致 —— 每个 zip 重算一遍，与清单里那串比对。
//   ③ 清单覆盖完整 —— dist/ 里每个 zip 都要在 SHA256SUMS.txt 里有一行。
//      为什么：README 写了「dist/ 里每个 zip 的 sha256 都写在 SHA256SUMS.txt」。
//      漏一行，玩家校验时会跳过它、拿到坏文件也不知道。
//
// zip 的形态（与原产物一致）：仅文件条目、无目录条目、顶层前缀 doom.schedule/。
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';

const ROOT = process.env.DOOM_ROOT ? path.resolve(process.env.DOOM_ROOT) : path.resolve(import.meta.dirname, '..', '..');
const DIST = path.join(ROOT, 'dist');
const WRITE = process.argv.includes('--write');

// zip ↔ 包体目录 的对应关系（包体 = 仓库根：白名单顶层文件 + data/**）
const PACK_TOP_FILES = ['pack.mcmeta', 'README.md', 'LICENSE', 'CHANGELOG.md'];
const PAIRS = [
  ['doom.consumable-v0.1.0-beta.2.zip', ROOT],
];

/* ---------- 最小 ZIP 读取器 ---------- */
function readZip(file) {
  const buf = fs.readFileSync(file);
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0 && i > buf.length - 66000; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('不是 zip（找不到 EOCD）');
  const count = buf.readUInt16LE(eocd + 10);
  let off = buf.readUInt32LE(eocd + 16);
  const entries = new Map();
  for (let i = 0; i < count; i++) {
    const method = buf.readUInt16LE(off + 10);
    const csize = buf.readUInt32LE(off + 20);
    const nlen = buf.readUInt16LE(off + 28);
    const elen = buf.readUInt16LE(off + 30);
    const clen = buf.readUInt16LE(off + 32);
    const lho = buf.readUInt32LE(off + 42);
    const name = buf.toString('utf8', off + 46, off + 46 + nlen);
    entries.set(name, { method, csize, lho });
    off += 46 + nlen + elen + clen;
  }
  const data = (name) => {
    const e = entries.get(name);
    if (!e) return null;
    const nlen = buf.readUInt16LE(e.lho + 26);
    const elen = buf.readUInt16LE(e.lho + 28);
    const start = e.lho + 30 + nlen + elen;
    const raw = buf.subarray(start, start + e.csize);
    return e.method === 0 ? Buffer.from(raw) : zlib.inflateRawSync(raw);
  };
  return { names: [...entries.keys()], data };
}

const walk = (d, rel = '') => {
  const out = [];
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const q = path.join(d, e.name);
    const r = rel ? rel + '/' + e.name : e.name;
    if (e.isDirectory()) out.push(...walk(q, r));
    else out.push(r);
  }
  return out;
};

let errors = 0;
const err = (msg) => { errors++; console.log('  ❌ ' + msg); };

console.log('=== ① zip 与包体逐字节一致 ===');
for (const [zipName, srcDir] of PAIRS) {
  const zipPath = path.join(DIST, zipName);
  if (!fs.existsSync(zipPath)) { err('缺 ' + zipName); continue; }
  if (!fs.existsSync(srcDir)) { err('缺包体目录 ' + path.relative(ROOT, srcDir)); continue; }

  const z = readZip(zipPath);
  const top = z.names[0].split('/')[0] + '/';
  const inZip = new Map();
  for (const n of z.names) {
    if (n.endsWith('/')) continue;
    if (!n.startsWith(top)) { err(zipName + ' 有不带顶层前缀的条目 ' + n); continue; }
    inZip.set(n.slice(top.length), z.data(n));
  }
  // 包体 = 白名单顶层文件 + data/**（不是整个仓库根，否则会把 .github/dist/docs 算进去）
  const src = [];
  for (const f of PACK_TOP_FILES) if (fs.existsSync(path.join(srcDir, f))) src.push(f);
  if (fs.existsSync(path.join(srcDir, 'data'))) src.push(...walk(path.join(srcDir, 'data'), 'data'));
  const missing = src.filter((f) => !inZip.has(f));
  const extra = [...inZip.keys()].filter((f) => !src.includes(f));
  let diff = 0;
  for (const f of src.filter((x) => inZip.has(x))) {
    if (!inZip.get(f).equals(fs.readFileSync(path.join(srcDir, f)))) { diff++; err(zipName + ' 内容不同: ' + f); }
  }
  if (missing.length) err(zipName + ' 缺 ' + missing.length + ' 个文件: ' + missing.slice(0, 3).join(', '));
  if (extra.length) err(zipName + ' 多 ' + extra.length + ' 个文件: ' + extra.slice(0, 3).join(', '));
  if (!missing.length && !extra.length && !diff) console.log('  ✅ ' + zipName + '（' + src.length + ' 文件逐字节一致）');
}

console.log('\n=== ② sha256 与 SHA256SUMS.txt 一致 ===');
const sumsPath = path.join(DIST, 'SHA256SUMS.txt');
if (!fs.existsSync(sumsPath)) {
  err('缺 SHA256SUMS.txt');
} else {
  const listed = new Map();
  for (const l of fs.readFileSync(sumsPath, 'utf8').trim().split('\n')) {
    const [h, f] = l.trim().split(/\s+/);
    if (h && f) listed.set(f, h);
  }
  for (const [f, h] of listed) {
    const p = path.join(DIST, f);
    if (!fs.existsSync(p)) { err('清单列了但文件不在: ' + f); continue; }
    const real = crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
    if (real !== h) err(f + ' 的 sha256 对不上（清单 ' + h.slice(0, 12) + '… 实际 ' + real.slice(0, 12) + '…）');
    else console.log('  ✅ ' + f);
  }

  console.log('\n=== ③ 清单覆盖完整 ===');
  const zips = fs.readdirSync(DIST).filter((f) => f.endsWith('.zip'));
  const notListed = zips.filter((f) => !listed.has(f));
  const notFile = [...listed.keys()].filter((f) => !zips.includes(f));
  if (notListed.length) err('这几个 zip 没列进 SHA256SUMS.txt: ' + notListed.join(', '));
  if (notFile.length) err('清单里这几行没有对应文件: ' + notFile.join(', '));
  if (!notListed.length && !notFile.length) console.log('  ✅ ' + zips.length + ' 个 zip 全部在清单里');
}

console.log('\n' + (errors ? '❌ ' + errors + ' 个问题' : '✅ 全部通过'));
if (!WRITE && errors) console.log('（改完重跑本脚本；要重算 sha256 就加 --write）');
process.exit(errors ? 1 : 0);
