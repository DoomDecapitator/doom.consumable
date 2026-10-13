# 变更日志 · doom.consumable

> **口径**：namespace `doom.consumable`（统一的"物品使用"框架：消耗 / 放置 / 丢弃 / 伪耐久回复 / 鱼竿右键 / 射击 / 投掷）。
> `pack_format` 81，`supported_formats` 48–82，并显式写出 `min_format` / `max_format`（1.21.11 起是强制字段）。
> 依赖 `doom.library`（可选 `doom.log`）。
> 自动化回归 = `doom.test:consumable`（**9 个套件 / 175 断言**，逐套件报告）；
> 判定**必须**用 RCON 直读计分板 `#pass/#fail/#calls dt.test`（套件用 `tellraw` 上报，**不进服务端日志**）。
>
> ✅ **2026-10-12 起 175/175 全绿**。此前长期挂着的那 1 条失败是**夹具缺陷**，已修（见 B3）。

---

## 2026-10-13 · v0.1.0-beta.2 —— 新增离线静态门 + 修一处宏行缺陷

### 🟢 B5 —— `api/block_cd_config` 的最后一条 tellraw 缺 `$` 前缀

**症状**：`function doom.consumable:api/block_cd_config {tag:"…",seconds:30,…}` 执行后，
回执里的 `$(tag)` / `$(seconds)` **按字面量原样打印**，不显示实际参数。

**根因**：该行是宏行（同一函数 L18–L22 都用 `$` 前缀），唯独最后一条 `tellraw` 漏了 `$`
⇒ Brigadier 不做宏替换。**不影响加载**（不是加载期错误），只是回执文本错。

**修**：给该行补 `$` 前缀。

### 🟢 新增 `.github/` 离线静态门（CI）

三个 Node 脚本 + 一个 GitHub Actions workflow，本机 < 2s、不需要 Minecraft：

| 脚本 | 查什么 |
|---|---|
| `check_leak.mjs` | 泄漏扫描（本机绝对路径 / 开发物标识）+ 仓库顶层白名单 |
| `check_pack.mjs` | 每个 `.json` 可解析 + 每个 `.mcfunction` 行级合法性 + 函数引用闭包 |
| `check_dist.mjs` | `dist/` 的 zip 与工作树**逐字节一致** + sha256 与 `SHA256SUMS.txt` 一致 + 清单覆盖完整 |

门规则按**真机实测**校准（不是照抄范本）：

- `~-N` / `~-0.5` **合法**，只有 `~+N` 被 Brigadier 拒（`Expected double`）⇒ 规则收窄为 `/~\+\d/`
- `\` 行尾续行的**行首缩进**是排版、合法 ⇒ 双空格规则改测 `line.trim()`
- `#$(tag)` 是宏标签选择器、不是行尾注释 ⇒ `#` 剥离字符类补 `$`
- 跨包引用（`doom.library` / `doom.log`）本仓查不到 ⇒ 加 `EXTERNAL` 放行名单

### 🟢 仓库卫生

- 新增 `.gitignore`（本地产物白名单）与 `.gitattributes`（`* -text`：包体内有 2 个 CRLF 文件，
  必须原样保留，否则 zip 不再逐字节一致）
- `pack.mcmeta` 的 description 从 `8.5` 更正为 `8.6`

---

## 2026-10-12 · 鱼漂夹具修复 + mcmeta 字段补齐（回归全绿）

### 🔴 B3 —— 用例 G 的夹具改成真抛竿（此前它一直在报假失败）

**症状**：`consumable_rod` 用例 G 的第 1 条断言「前置：鱼漂已生成」**必然失败**，
整套件 16 条断言里永远挂着 1 条红；其余 8 个套件全绿。

**根因**：夹具用 `summon minecraft:fishing_bobber` 造鱼漂。而鱼漂在本版本是 **`noSummon` 实体**，
**不存在任何 summon 途径**：

| 手段 | 结果 |
|---|---|
| `summon minecraft:fishing_bobber` | `Can't summon entity of type minecraft:fishing_bobber` |
| `execute summon minecraft:fishing_bobber` | 同上 |
| Scarpet `spawn('fishing_bobber', …)` | `= null` |
| 对照 `minecraft:arrow` / 雪球 / 末影珍珠 / 鸡蛋 | 全部成功 |

⇒ 不是参数问题、不是位置问题、不是场地问题，**是实体类型层面的拒绝**。
（此前文档把成因写成"无头服务器上独立 summon 的实体同 tick 后即消失"——那是另一条已知行为，
不是这里的原因。1.21.6 那次"修好了"是巧合，2 秒后消失的规律只适用于可 summon 的实体。）

**修**：夹具改用**唯一的合法来源——真抛竿**，并把 G 段拆成两拍：

- 第一拍 `doom.test:suite/consumable_rod_cast`：`player <名字> use` 真抛竿，然后 `schedule … 2t`
- 第二拍 `doom.test:suite/consumable_rod_deny[_at]`：三条断言 + 套件收尾

**为什么要拆两拍**：真抛竿产生的鱼漂**要到第 2 刻才可读**（实测 t+1t 不存在、t+2t 起存在），
而 `doom.test` 的既有套件约定是**同步执行、不等待 tick**。

**两条实测约束**：

- Carpet 的 `/player` **只认名字字面量**，`@s` / `@p` / `@e[…​]` 一律 `Expected whitespace to end one argument`。
  它**可以**在函数体内调用，前提是那一行本身处在 `execute as <玩家>` 上下文里。
- `rod/tick` 每刻都会给所有鱼漂补 `dc_rod_seen`，所以"本刻新抛"只能靠**先 `tag … remove dc_rod_seen`** 模拟。

**结果**：`consumable_rod` **16/16**，全套件 **175/175**。

### 🔴 B4 —— `pack.mcmeta` 补 `min_format` / `max_format`（1.21.11 起是强制字段）

**症状**：`/reload` 时每个包刷一条 ERROR，而**包照样加载、函数照样跑**：

```
Couldn't load file/doom.consumable pack metadata: Pack declares support for version
newer than 81, but is missing mandatory fields min_format and max_format
```

**根因**：本包（以及同期一批 doom 包）写的是 `supported_formats: {min_inclusive: 48, max_inclusive: 82}`。
`max_inclusive` 声明到 **82**，比 1.21.11 的 **81** 新，于是游戏要求必须**同时**写出
`min_format` / `max_format` 这两个新字段。

**修**：补上 `"min_format": [48, 0]` 与 `"max_format": [82, 0]`，**声明范围一个字没改**。

**真机取证**（同一台 1.21.11，逐个变体 `reload` 后读日志）：

| 写法 | 结果 |
|---|---|
| 只有 `pack_format` | 不报错 |
| `supported_formats{48,82}`（无 min/max） | **ERROR** |
| `supported_formats{48,82}` + `min_format[48,0]` + `max_format[82,0]` | 不报错 |
| `supported_formats{48,81}`（不越界） | 不报错 |
| 只有 `min_format[48,0]` / `max_format[81,0]`，无 `supported_formats` | **另一种 ERROR**：`Pack declares support for format 48, but game versions supporting formats 17 to 81 require a supported_formats field` |

⇒ **两个字段组都要在**：旧字段（`supported_formats`）供旧版本读，新字段（`min_format` / `max_format`）供新版本读。
**只写新字段会让旧版本读不到支持区间。**

### 🟡 顺带修掉的两处回归工具盲区（不在包内，在 `_work/consumable-work/`）

1. **加载错误的判据漏了第 9 类**。旧正则只有 8 类，不含 `Couldn't load … pack metadata`，
   于是 B4 这种"包照跑但报错"的情况**在判定里恒为 0 命中**，历次"8 类加载错误 = 0"是**假阴性**。
2. **日志切片用错了单位**。偏移取自 `statSync().size`（**字节**），切片却用 `readFileSync(f,'utf8')`
   的**码元下标**；日志含中文时两者差 1.3 KB 量级，切片位置整个错位，这是上面那类报错读不到的**另一半原因**。
   正确写法：`readFileSync(f).subarray(offset).toString('utf8')`。

### 套件用例数订正

`consumable_shot` 实测 **55** 条（此前文档写 51），全套件合计 **175**（此前写 171）。

---

## 2026-10-05 · P0-1 投掷链 + P0-2 连发弹匣 + 回归套件

### 🔴 B1 —— 用户可见的行为修复（**此前副手射击链完全失效**）

**症状**：主手拿的不是 `detect:"shot"` 武器、只有**副手**拿时，射击**毫无反应** ——
不扣次、不写回、不报错、**静默失效**（玩家视角是"这把弓坏了/没反应"）。

**根因**：`ctx.shot.main` 是布尔载荷（`1b`=主手 / `0b`=副手），但 **5 个文件共 15 处**写成
`if data storage doom.consumable:ctx shot.main` —— 这是**存在性**判定，而该键**恒为 1b 或 0b 二者之一**
⇒ 条件**永远为真** ⇒ `unless`（副手）那一支是**死代码**。

| 文件 | 处数 |
|---|---|
| `shot/process_one.mcfunction` | 2 |
| `shot/writeback.mcfunction` | 4 |
| `shot/depleted.mcfunction` | 2 |
| `shot/depleted_disable.mcfunction` | 4 |
| `shot/depleted_normal.mcfunction` | 4 |

**修**：改为**值判定** `shot{main:1b}`（`1b` 走 `if`，`0b` 走 `unless`）。
**真机取证**：修复前副手 `current_uses = 5`（没动）→ 修复后 `= 4`（正确扣次并写回副手）。
**由谁发现**：新增的 `consumable_shot` 套件用例 **K1**。
⇒ **这条 bug 此前零断言覆盖，没有套件就永远发现不了**（且它是静默的，只能靠断言抓）。

### 🟡 B2 —— `ctx.shot` 残渣清理（卫生，非功能）

没有发生射击的 tick 会在共享 storage 里留下 `doom.consumable:ctx.shot = {main:1b}` 常驻。
**当前无功能影响**（`tick_one` 每刻都会在派发前重写它），但 `ctx` 是**跨包共享**命名空间，
残渣会误导别人的诊断；且一旦给 `process_one` 加别的入口就会变成真 bug。
**修**：`shot/tick_one` 收尾无条件 `data remove … shot`（幂等）。
**由谁发现**：套件用例 A2 / B2 / D2。

### 🟢 新功能 A —— `detect:"throw"`：投掷物消耗链（P0-1）

支持 **雪球 / 鸡蛋 / 末影珍珠 / 经验瓶** 四种原版投掷物，字段语义与 `detect:"shot"` **完全一致**。

- **事件源 = 原版统计准则** `minecraft.used:minecraft.{snowball,egg,ender_pearl,experience_bottle}`。
  > ★ **实测更正一个流传的判断**：曾以为"原版**没有** `used:snowball`、必须自造事件源"——**不成立**。
  > 真机三连证：① `scoreboard objectives add … minecraft.used:minecraft.snowball` **创建成功**；
  > ② 假玩家持雪球连按 5 次 ⇒ 计分板 **5**、背包 16→11（**真的计数**）；
  > ③ 对照组 `minecraft:stick` 连按 3 次 ⇒ **0**（证明是**投掷语义专属**，不是泛化右键计数）。
  > ⇒ 投掷物**直接复用 shot 链的结构**即可，不需要实体检测 / 进度变体。
  > （Ragecraft IV 的 `@e[type=snowball]` + tag 分派是给**地图自己 summon 的弹幕**用的 ——
  > 那些雪球不经过玩家投掷、自然没有 stat，与"玩家扔出去扣次"是两个问题。）
- **跨版本核对（2026-10-05 实测）**：四个准则在 **1.21.5 / 1.21.9 / 1.21.11 / 26.3** 上**全部可创建** ✓
- 新增：`function/throw/`（11 文件）· 回调标签 `#doom.consumable:on_throw`
  · 示例 `loot_table/items/{limited,infinite}_snowball.json` · `limited_ender_pearl.json`
- ⚠️ 投掷物**扔出后原版即把物品从手里拿走**（最后一颗直接消失）⇒ `depleted_disable`/`depleted_normal`
  开头加了"手上还有那件 dc 物品"的守卫，防止中转体**凭空造出一颗投掷物**。

### 🟢 新功能 B —— `dc.mag`：连发弹匣 / 无限弩（P0-2）

给弩加 `mag:1b` ⇒ 射完**自动重上膛**，配合 `arrow_refund` 补背包箭 = 半自动无限连发。

- **实现**：`item modify` + `item_modifier/shot_recharge.json`。
  因为写入值是**常量**（`charged_projectiles:[1 支箭]`），可**直接改玩家手持物品**，
  **不需要** `item_display` 中转体（对比 `writeback`：值要运行时算，只能走中转体）。
- ⚠️ **踩坑提醒（已写进代码注释）**：`item modify entity @s $(slot) …` **加载不过**
  （`Unknown slot '$(slot)'`）—— 槽位参数是**解析期字面量**，宏替换在其之后。
  **它与 `item replace` 不可类推**（后者能收宏）。现按 main/off 分支写死槽位。
- **边界（已断言）**：没有 `mag` 的弩**不会**被重上膛；`limited` 弩**耗尽那一发**不补膛。
- 示例：`loot_table/items/repeating_crossbow.json`（含专属 `cooldown_group`，避免连带冷却所有弩）。

### 🟢 新功能 C —— `consumable_shot` 回归套件（55 断言，此前 **零覆盖**）

覆盖：三武器各自扣次与写回 · 同 tick stat 跳变只扣一次 · 三种耗尽模式 ·
`infinite`/`limited` × `arrow_refund` · **反向闸门**（弓的 stat 不推动弩、鸡蛋的 stat 不推动雪球）·
副手兜底 · 连发弹匣（含两条反向闸门）· 四种投掷物各自的事件源 · 两个回调挂载点 · `ctx` 残渣卫生。

### 🟢 其他

- `README.md` 新增 §五（射击链与投掷链），契约表补 `detect:"shot"/"throw"`、`arrow_refund`、`mag`。
- `__load__.mcfunction` 新增 8 个 objective（4 准则 + 4 prev）；`tick.mcfunction` 挂入 `throw/tick`。

---

## 2026-10-01 · 方块冷却闸门

- 方块级使用冷却（`api/block_cd_*`）：挂在方块上的 marker 设备，配置与到期刻存它身上（跨 reload / 重启存活）。
- 冷却态换外观：在带布尔状态的原版方块（拉杆 `powered` / 铜灯 `lit` …）之间切换。
- 41 断言全绿（核心 14 + 扩展 12 + 视觉 15）。技术档案：`docs/技术档案-方块冷却闸门-20261001.md`。

## 2026-09-30 ~ 10-01 · 鱼竿接口重设计 + 弓扩展

- 鱼竿右键接口（`dc.rod`）：四条 API + 闸门 + 状态机 + 按钮模式 + 借用/归还链路重做。
  真机 E2E **11/11**；钓获三杆矩阵 **3/3**；5 假人同刻齐抛隔离 **21/21**。
- 弓/弩/三叉戟射击链（`dc.detect:"shot"`）：stat 差分事件源 + 扣次/写回/耗尽三模式 + `arrow_refund`。
  **当时无断言覆盖**（本轮的 `consumable_shot` 已补上，并借此抓到 B1）。

## 2026-09-27 · 恢复落点守卫 + 回复条状态跟物品走

- `restore/guard` + `put_anywhere`：恢复写入前判占用 —— 修「**频繁切换物品使用会吞物品**」。
- 伪耐久条计时状态从**玩家分数**改为**跟着物品自己走**（`dc.rb_cd`）——
  修「两件同时在身上时条会串台/跳变」。
- 鱼竿接口首版（`dc.rod`）。

## 2026-09-20 ~ 09-26 · 放置链时序 + disable 语义

- `core/snapshot_hand` 快照优先：修「**按住右键连续放置每次少一件**」（读的是消耗后而非消耗前的手）。
- 耗尽分支清手持与缓存写入的**顺序**修正：修「**耗尽后物品不消失、耐久条卡在 1/5、可以无限吃**」。
- `disable` 三类物品（consume / place / 其它）的"做到最死"语义分别定稿。
