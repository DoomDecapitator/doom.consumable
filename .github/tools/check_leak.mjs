// .github/tools/check_leak.mjs —— 泄漏守门 + 仓库顶层结构守门。
//
//   node .github/tools/check_leak.mjs                       # 扫仓库根（默认 <本文件>/../..）
//   DOOM_GIT=<git 完整路径> node .github/tools/check_leak.mjs   # 本机 git 不在 PATH 时
//   DOOM_ROOT=<仓库根> node .github/tools/check_leak.mjs        # 检查另一个克隆
//   DOOM_TOP=off node .github/tools/check_leak.mjs              # 只做泄漏扫描，跳过顶层结构
//
// 两条守门：
//   ① 泄漏扫描：不得出现本机绝对路径、开发物标识、第三方素材标识。
//      为什么：玩家向仓库里出现 `C:\Users\...` 或某次实验的夹具名，等于把开发机的断面直接公开。
//   ② 顶层白名单：仓库顶层只允许下面 ALLOW 里列的那几项。
//      为什么：2026-09-29 有过一次 shell 反引号被展开、在顶层误建垃圾文件的事故，
//      当时一次 `git add -A` 把 9 个垃圾文件混进了 doom.nats 仓库。从此顶层结构也过门。
//
//   顶层允许：README.md · LICENSE · CHANGELOG.md · .gitignore · .gitattributes
//            · pack.mcmeta · data/ · dist/ · docs/ · .github/
//   未跟踪但躺在工作目录里的可疑条目：只警告（下一次 `git add -A` 就会被带进仓库）。
//
// 为什么放在 .github/tools/ 而不是 src/tools/：
//   本包是手写 mcfunction，没有生成器，README 明确写了「仓库里没有 src/」。
//   门禁脚本属于 CI 的附属物，放 .github/ 下不改变仓库形态，也不会被打进发行 zip。
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const GIT = process.env.DOOM_GIT || 'git';
const ROOT = process.env.DOOM_ROOT ? path.resolve(process.env.DOOM_ROOT) : path.resolve(import.meta.dirname, '..', '..');

// ① 泄漏模式
const IDS = [
  /[A-Za-z]:[\\/]Users[\\/]/i,            // 本机绝对路径（Windows）
  /\/c\/Users\//i,                        // 本机绝对路径（Git Bash 形态）
  /Downloads[\\/]datapack/i,              // 本机工作区名
  /_work[\\/](mcserver|ports)/i,          // 本机测试台路径
  /_run_schedule\.mjs/i,                  // 真机验收脚本（在 _work/ports，不进玩家向仓库）
  /_matrix_lib\.mjs/i,                    // 验收套件依赖
  /mineflayer/i,                          // 测试台依赖
  /doom\.schedule-multi/i,                // 多版本构建目录（开发物）
  /thirdparty-rig/i,                      // 实验用第三方 rig 素材标识
  /\brigns\d*/i,
  /\bbdengine\b/i,
  /All-Rights-Reserved/i,                 // 第三方许可标识（本项目用的是 MIT）
];
// 本文件正文里就写着上面这些正则 ⇒ 自己跳过
const SELF = ['.github/tools/check_leak.mjs'];

// ② 顶层白名单
const ALLOW = new Set(['README.md', 'LICENSE', 'CHANGELOG.md', '.gitignore', '.gitattributes',
  'pack.mcmeta', 'data', 'dist', 'docs', '.github']);
// 二进制/生成物跳过文本扫描
const SKIP_EXT = /\.(zip|png|jpg|jpeg|gif|webp|ico|pdf|jar|dat|mca)$/i;

const git = (args) => execFileSync(GIT, args, { cwd: ROOT, encoding: 'utf8' });
let files = [];
const top = new Set();
const topDirty = new Set();
try {
  files = git(['-c', 'core.quotepath=false', 'ls-files']).split('\n').filter(Boolean);
  for (const f of files) top.add(f.split('/')[0]);
  for (const l of git(['status', '--porcelain', '--untracked-files=all']).split('\n')) {
    if (!l.startsWith('?? ')) continue;
    topDirty.add(l.slice(3).replace(/^"|"$/g, '').split('/')[0]);
  }
  for (const d of topDirty) top.add(d);
} catch (e) {
  console.error('（不在 git 仓库里 / 找不到 git：' + String(e.message).split('\n')[0] + ' ⇒ 改用全目录扫描）');
  const walk = (d, out = []) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { if (e.name === '.git') continue; const q = path.join(d, e.name); if (e.isDirectory()) walk(q, out); else out.push(path.relative(ROOT, q).split(path.sep).join('/')); } return out; };
  files = walk(ROOT);
  for (const e of fs.readdirSync(ROOT)) top.add(e);
}

let bad = 0;

// ① 泄漏
const hits = [];
for (const rel of files) {
  if (SELF.includes(rel)) continue;
  if (SKIP_EXT.test(rel)) continue;
  if (!/\.(md|json|mjs|js|mcfunction|txt|yml|yaml|mcmeta|mcdoc)$/.test(rel) && !rel.startsWith('.git')) continue;
  let t = '';
  try { t = fs.readFileSync(path.join(ROOT, rel), 'utf8'); } catch { continue; }
  for (const re of IDS) if (re.test(t)) hits.push([rel, String(re)]);
}
if (hits.length) {
  bad += hits.length;
  console.log('❌ 泄漏检查：' + hits.length + ' 处');
  for (const [f, why] of hits.slice(0, 20)) console.log('  ' + f + ' :: ' + why);
} else {
  console.log('✅ 泄漏检查：0 处（' + files.length + ' 个已跟踪文件里无本机绝对路径 / 无开发物标识）');
}

// ② 顶层结构
if (process.env.DOOM_TOP === 'off') {
  console.log('⏭  顶层结构检查：已按 DOOM_TOP=off 跳过');
} else {
  const stray = [...top].filter((t) => t && !ALLOW.has(t) && !topDirty.has(t)).sort();
  const dirty = [...topDirty].filter((t) => t && !ALLOW.has(t)).sort();
  if (dirty.length) {
    console.log('⚠️  顶层结构（未跟踪，只警告）：' + dirty.length + ' 个顶级条目没被提交但躺在工作目录里 —— 别 `git add -A`');
    for (const s of dirty.slice(0, 20)) console.log('  ' + s + '  (未跟踪)');
  }
  if (stray.length) {
    bad += stray.length;
    console.log('❌ 顶层结构：' + stray.length + ' 个**已提交**的顶级条目不在白名单里');
    for (const s of stray.slice(0, 20)) console.log('  ' + s);
    console.log('  白名单：' + [...ALLOW].sort().join(' / '));
  } else {
    console.log('✅ 顶层结构：' + [...top].filter((t) => t && ALLOW.has(t)).length + ' 个顶级条目全在白名单内（扫描 ' + files.length + ' 个已跟踪文件）');
  }
}

process.exit(bad ? 1 : 0);
