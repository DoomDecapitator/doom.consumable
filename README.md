# doom.consumable

统一的「物品使用」框架：**消耗 / 放置 / 丢弃 / 伪耐久条回复 / 鱼竿右键**都在这里，
通过物品身上的 `minecraft:custom_data.dc` 声明，不需要改包。

- 交付对象：地图作者、其它数据包作者（把本包当库用）
- 测试入口：`/function doom.test:consumable`（逐套件报告）
- 依赖：`doom.library`（缓存 / 读写 API）、可选 `doom.log`（并发自检哨兵会上报 E201）

---

## 一、物品契约（`dc` 字段）

放在物品组件 `minecraft:custom_data.dc` 里。示例见 `loot_table/items/*.json`。

| 字段 | 取值 | 含义 |
|---|---|---|
| `detect` | `"consume"` / `"place"` | **必需**：走哪条检测链（吃东西 / 方块放置） |
| `type` | `"limited"` / `"infinite"` | **必需**：有限次数 / 无限 |
| `max_uses` / `current_uses` | int | 有限次数的上限与已用次数（配 `max_damage` 显示耐久条，见 lint C4） |
| `remainder` | 物品 id | 耗尽后给回的物品 |
| `depleted` | `"disable"` / `"vanish"` | 耗尽后的处置（缺省 = disable） |
| `on_use_damage` | int | 每次使用时给自己造成的伤害 |
| `recover` / `recover_ticks` | `1b` / int | 伪耐久条：参与回复 / 每格回复所需 tick（默认 10） |
| `discardable` / `discard_cooldown` | `1b` / int | 可丢弃 / 丢弃冷却（默认 60） |

运行时字段（包自己写，别手填）：`resync`（槽位同步戳）、`rb_cd`（单件回复倒计时）、
`rod_locked`（鱼竿禁用标记）。

> 给作者：契约的键名审计工具是 `node tools/doomtest/dc_keys.mjs`（拼错键 / 契约漂移一览）。

### 1.1 引擎事实：`consume_seconds` 填 0 会跳过 `using_item`（**本包已支持，但仍默认写 0.05**）

`minecraft:consumable.consume_seconds` 的 codec 用 `ExtraCodecs.NON_NEGATIVE_FLOAT`（**0 是合法值**），
而 0 会让 `Consumable.use()` 走**另一条分支**（源码 `Consumable.java`）：

```java
boolean hasDuration = this.consumeTicks() > 0;          // consumeTicks() = (int)(consumeSeconds * 20)
if (hasDuration) { player.startUsingItem(hand); return InteractionResult.CONSUME; }   // 进入"使用中"态
else             { this.onConsume(level, player, stack); … }                          // 0 ⇒ 当场消耗
```

⇒ **填 0 = 瞬间消耗**（实测：`consume_seconds:0` 的金苹果单击一次就被消耗、`consume_item` 触发），
但它**跳过了 `startUsingItem`** ⇒ ① **`using_item` 触发器不发火**；② 因此"使用前快照"（`core/pre_save`）不会写。

**旧版本（≤2026-09-30）因此不支持 0 秒物品**（表现为"右键直接消失、不计数也不恢复"，lint 规则 C5 曾按 error 拦）。
**2026-10-01 起已支持**，机制是给消耗奖励补拍快照：

```mcfunction
# core/mark_consumed（consume_item 的奖励函数）
advancement revoke @s only doom.consumable:consume
function doom.consumable:core/pre_save        # ← 关键：在此刻补拍使用快照
scoreboard players set @s dc.consume_timer 1  # ← 1 tick 后 process_usage_wrapper 照旧处理
```

之所以可行，是实测确认了**触发时序**：`consume_item` 的奖励函数**早于"扣减"执行** —— 被调用的那一刻手上
还是**刚被消耗的那件**（`count=N` 未减）。于是 1 tick 后 `process_usage_wrapper` 的差分（N → N-1）照常成立，
0 秒物品与普通物品**走同一条链**。顺带根治了一个真 bug：快照必定来自"这一次消耗"，不可能再拿
"上一次起手却没消耗"留下的旧快照张冠李戴（wrapper 另有 `age ≤ 2` 的新鲜度守卫兜底）。

> 端到端实测（金苹果，单击一次）：`0 秒 limited` → `uses 3→2→1→用尽`；`0 秒 infinite` → 被写回手上 ✓。

**本包约定仍默认写 `consume_seconds: 0.05`（= 1 tick）** —— 手感几乎一样，但保留 1 tick 的**可见使用态**
（`using_item` 与 `consume_item` 两个钩子都响），也避免别人误以为"这物品没被检测到"。
确有"完全无使用态"需求时填 0 亦可；lint 规则 **C5** 已从 `error` 降为 `warn`（只作提醒）。

> 实测对照（金苹果，单击一次 / 持续 2 秒）：
> `0.0s` 单击 → `using_item 0 · consume_item 1` · `0.05s` 单击 → 都不动 ·
> `0.05s` 持续 → `using_item 5 · consume_item 5`（1 tick 一次）。
> 注：普通食物在**饱食度满**时不消耗（除非 `can_always_eat`），做试验请用金苹果或药水。

---

## 二、鱼竿右键接口（2026-09-27 建；**2026-10-01 重设计并端到端验证**）

### 2.1 为什么需要专门的接口

原版鱼竿的"使用"**没有**现成的进度触发器：`item_used_on_block` 不认它（不跟方块交互）、
`using_item` 也不认它（没有"使用中"时长）、`consume_item` 更不认它（不是消耗品）。
香草图书馆《常用右键检测》里那三招（胡萝卜钓竿 / 交互实体 / `consumable` 组件）在鱼竿上都用不了：
胡萝卜钓竿要先换成胡萝卜钓竿那件物品、交互实体是另一个实体、`consumable` 组件的使用行为会被
`FishingRodItem` 自己的 `use` 覆盖掉。

本接口用三条互相补位的信号把鱼竿右键"显形"：

| 信号 | 来源 | 拿到什么 |
|---|---|---|
| ① 统计事件 | 记分板 `dc.rod_use`（准则 `minecraft.used:minecraft.fishing_rod`） | **只代表"抛竿"**（源码实锤：`awardStat` 只在 `FishingRodItem.use` 的抛竿分支，收杆分支零统计） |
| ② 状态机 | 玩家分数 `dc.rod_state`（0 未抛竿 / 1 钓鱼中） | 现在是不是"在钓" |
| ③ 鱼漂归属 | 实体 `minecraft:fishing_bobber` + 包内 tag `dc_rod_own_<UUID[0]>` | **这是谁的**鱼漂；它一消失就是一次"收杆"（手动收杆 / 断线 / 被外力消灭都算） |

> **1.21.6 的鱼漂存档里没有 `Owner` 字段**（真机实锤：只有 `Pos/Motion/UUID/Rotation/Tags/Air/…`），
> 所以归属不能靠 NBT 反查，只能**抛竿时主动打标**：`cast_ok` 把玩家 `UUID[0]` 写进
> `dc.rod_uid`，再给本刻新出现、离自己最近的鱼漂打 `dc_rod_own_<uid>`。
> 旧版"靠 `Owner:[I;…]` 匹配"的实现**在 1.21.6 是死代码**（静默失败），已删除。

成功钩取（钓上物品 / 拉回实体）另外接进度触发器 `minecraft:fishing_rod_hooked`。
rod 谓词用**子集匹配**（源码实证的写法：`predicates` 与 `items` **同级**）：

```json
"rod": {
  "items": ["minecraft:fishing_rod"],
  "predicates": { "minecraft:custom_data": { "dc": { "rod": 1b } } }
}
```

> **写法依据（1.21.6 源码，不是猜的）**：`ItemPredicate.CODEC` 的第三个字段是
> `DataComponentMatchers.CODEC.forGetter(ItemPredicate::components)` —— **没有 `optionalFieldOf("components")` 包装**，
> 于是 `DataComponentMatchers` 自己的两个字段（`components` = 整组件精确匹配 / `predicates` = 部分匹配）
> 被**摊平到 ItemPredicate 这一层**。`predicates` 的键是**组件谓词类型 id**（如 `minecraft:custom_data`），
> 值走 `CustomDataPredicate.CODEC` = `NbtPredicate.CODEC` = `TagParser.LENIENT_CODEC`，即**裸 NBT**，
> 语义是 **NBT 子集匹配**（`dc` 里多别的键也命中）。
> **反例（会解析失败，千万别写）**：`{"components":{"predicates":{…}}}` —— `components` 是"组件类型 → 值"的
> **精确匹配**映射，它会把 `predicates` 当成组件类型名去查注册表，报
> `Unknown registry key … data_component_type: minecraft:predicates`。
>
> `rod/catch` 顶部另有一条 `if data … dc{rod:1b}` 守卫作**双保险**：谓词被改错时还能兜住。
> 本项目在 1.21.5 → 1.21.6 迁移时就曾被静默改错过一次，特征是**功能整体失效但没有任何报错**。

### 2.2 怎么给自己的鱼竿接上

1. 物品加一个字段就行：`minecraft:custom_data.dc.rod = 1b`（完整示例：`loot_table/items/test_rod.json`）
2. 需要扩展就在回调标签里写逻辑（见 2.6）；需要"用不了"就选 2.4 的三个入口之一
3. 拿到测试鱼竿：`/function doom.consumable:test/give_rod`；现场核对：`/function doom.consumable:test/probe_rod`

### 2.3 鱼竿专用字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `rod` | `1b` | **必需**：标记这件物品参与接口（没有它，接口完全不理它） |
| `rod_locked` | `1b` | 运行时禁用标记（`api/rod_disable` 写、`api/rod_enable` 清） |
| `rod_clear_durability` | `1b` | 成功钩取后把耐久清空（满格）—— "使用后耐久清空"这类需求写这一个字段即可 |
| `rod_button` | `1b` | **按钮模式**：一次右键 = 抛竿后立刻收回（只发 `on_rod_cast`，不发 `on_rod_reel`）—— 把鱼竿当"触发型物品"用 |
| `rod_deny_message` | string | 被否决时显示的文本（红色，裸文本不带引号） |
| `rod_deny_sound` | string | 被否决时播放的音效 id，例 `minecraft:block.note_block.bass` |

### 2.4 禁用（什么时候不能用鱼竿）—— 三个入口

| 入口 | 形式 | 适用 |
|---|---|---|
| 静态名单 | 物品标签 `#doom.consumable:rod_locked` | 某几件鱼竿（或整个 `minecraft:fishing_rod`）永久不能用 |
| 动态开关 | `api/rod_disable` / `api/rod_enable` | 状态跟着**物品**走，可随时开关 |
| 条件钩子 | 函数标签 `#doom.consumable:rod_gate` | 按**玩家状态**判断（血量、区域、效果……）：在里面 `scoreboard players set #rod_deny dc.temp 1` 即否决 |

**两道防线**（为什么这么设计）：

- **软否决**：原版没有"使用前"钩子，所以接口在**同一个服务器 tick 内**把刚抛出来的鱼漂收回
  （玩家交互包在 tick 最前处理、本逻辑在 tick 后段运行）⇒ 玩家看不到鱼漂、拿不到任何产物，等效"没抛"。
- **硬禁用**：被禁用的鱼竿会自动挂上 `minecraft:use_cooldown`（时长 `#rod_lock dc.cfg` 秒，默认 10，到期自动续）
  ⇒ 原版直接拦住"使用"，热键栏显示灰条 —— 玩家**看得见**"现在不能用"。

### 2.5 API 一览（对外可用，参数必须写全）

| 函数 | 参数 | 作用 |
|---|---|---|
| `doom.consumable:api/rod_durability` | `{value:<int>}` | 设置手持鱼竿的 `damage`（**0 = 满耐久**） |
| `doom.consumable:api/rod_durability_add` | `{value:<int>}` | 加减损耗（可负；不会低于 0） |
| `doom.consumable:api/rod_disable` | — | 禁用执行者手上的鱼竿（写 `rod_locked` + 挂冷却） |
| `doom.consumable:api/rod_enable` | — | 解除禁用（清 `rod_locked` 与 `use_cooldown`） |
| `doom.consumable:api/rod_reel` | — | 强制收回执行者自己的鱼漂（打断钓鱼，无回调） |
| `doom.consumable:api/rod_casting` | — | 查询执行者是否在钓：结果写进 `#casting dc.temp`（1 = 正在） |

> 全部要求**执行者是玩家本人**（写回靠 `item replace entity @s …`）。
> 宏函数（带 `{…}` 的那两个）**必须带参数**：缺参数时整次调用会被静默放弃（引擎行为，本项目已钉）。

### 2.6 回调标签（第三方挂载点）

| 标签 | 触发时机 |
|---|---|
| `#doom.consumable:on_rod_cast` | 抛竿放行（每抛一次恰好 1 次） |
| `#doom.consumable:on_rod_reel` | 钓鱼结束且玩家仍手持鱼竿（手动收杆 / 断线 / 鱼漂被外力消灭） |
| `#doom.consumable:on_rod_catch` | 成功钩取（钓上物品 / 拉回实体）—— catch ⊂ reel：钩取后紧接着也会发一次 reel |
| `#doom.consumable:on_rod_denied` | 抛竿被否决 |

> `api/rod_reel` 是**中断语义**：它收回鱼漂但**不发** `on_rod_reel`（调用方自己知道是自己干的），
> 且不触发耐久/掉落/拉实体等原版收杆副作用。

### 2.7 记分板（只读参考 / 可调）

| 目标 | 含义 |
|---|---|
| `dc.rod_use` | 准则统计，每玩家"**抛竿**"累计次数（接口的事件源；收杆不计数） |
| `dc.rod_prev` | 接口内部用：上一 tick 的 `dc.rod_use`（别手改） |
| `dc.rod_state` | 0 = 未抛竿，1 = 钓鱼中 |
| `dc.rod_uid` | 接口内部用：玩家 `UUID[0]`（归属标签的钥匙，抛竿时缓存） |
| `dc.rod_catch` | 成功钩取累计次数 |
| `#rod_lock dc.cfg` | 锁定鱼竿续期的冷却秒数（默认 10） |

### 2.8 原版行为与坑（作者实测/官方来源）

- `use_cooldown` **对鱼竿有效**（Mojira [MC-275882](https://mojira.dev/MC-275882) 报的就是鱼竿的冷却行为），
  但**不拦方块交互**（[MC-275796](https://mojira.dev/MC-275796)）—— 与本接口无关，鱼竿不跟方块交互。
- 鱼竿只在**收杆且钩到东西**时掉耐久，空收杆不掉（相关现象见 [MC-101033](https://mojira.dev/MC-101033)）；
  所以"用一次掉一点耐久"这类规则请写在回调里调用 `api/rod_durability_add`。
- `fishing_rod_hooked` 只在**成功钩取**时触发（钓上物品 / 拉回实体），空收杆不触发。
- 鱼漂消失 ≠ 玩家收杆：死亡 / 换维度 / 超时都会让它消失。接口用"自己的鱼漂没了 ⇒ 状态自愈"处理，
  但**只要玩家此刻还手持鱼竿**就判为一次真收杆（发 `on_rod_reel`）；没手持则静默归零（不发回调）。
- `api/rod_reel` 靠鱼漂身上的 tag `dc_rod_own_<uid>` 定位（**不是** NBT `Owner` 字段 ——
  1.21.6 的鱼漂存档里根本没有这个字段）。tag 在抛竿那一刻打上，随实体走。
- 边界：把鱼漂抛进**未加载（非实体 tick）区块**时归属打标会落空 ⇒ 会出现一次"抛竿后 1 刻的幽灵收杆"。
  真人视距 ≥2 时不会遇到（这是假人测试环境的产物）。

### 2.9 参考

- 香草图书馆《常用右键检测》（CR_019）：<https://vanillalibrary.mcfpp.top/datapack-index/resources/dust/3/常用右键检测.html>
  —— 三种通用右键检测法（胡萝卜钓竿 / 交互实体 / `consumable` 组件），**都不适用于鱼竿**，原因见 2.1。
- 官方结构：`minecraft:fishing_rod_hooked` 触发器的条件为 `entity`（被拉回的实体或鱼漂）、
  `item`（钓到的物品）、`rod`（用的鱼竿）。

---

## 三、测试与自检

| 命令 | 作用 |
|---|---|
| `/function doom.test:consumable` | 跑全部物品套件（含 `consumable_rod`：契约字段 / 四条 API / 闸门 / 状态机） |
| `/function doom.consumable:test/give_rod` | 拿一把测试鱼竿 |
| `/function doom.consumable:test/probe_rod` | 打印 `dc.rod_use` / `dc.rod_state` / `dc.rod_catch` 与鱼漂 NBT |
| `node tools/doomtest/lint.mjs` | 静态检查（含宏参数、守卫判据等规则） |
| `node tools/doomtest/dc_keys.mjs` | `dc` 契约键名审计（拼错键 / 契约漂移） |

**自动化覆盖情况（2026-10-01 真机 E2E，假人 + RCON）**：抛竿/收杆/连续 3 轮计数/按钮模式/api 强收/自愈
共 **11/11 断言通过**；钓获路径三杆矩阵（dc 杆 / 原版杆 / dc 杆带额外键）**3/3 通过**——
含"原版杆不发 `on_rod_catch`"这条**反向闸门证明**。全量报告见 `doom.nats/reports/研究-rod接口重设计-20261001.md`。

**尚未被自动化覆盖**（需要真人操作，用 `probe_rod` 核对）：物品标签 `#doom.consumable:rod_locked`
的实际拦截手感、真人视距下的钓鱼体感。

---

## 四、方块冷却设备（2026-10-01 新增）

给「一个方块」做使用冷却。原版没有方块组件 —— 冷却只存在于物品（`use_cooldown` 组件）与玩家侧，
所以这里用**挂在方块上的 marker 实体**当设备：配置与到期刻都存在它身上（跨 reload / 重启存活）。

### 4.1 三十秒上手

1. 站在目标方块上，执行 `function doom.consumable:api/block_cd_place` ⇒ 该方块装上设备；
2. 之后任何人对它做「方块交互」都会过闸：
   · 已到期 ⇒ 触发 `#doom.consumable:on_block_use`（第三方在这里做真正的效果）；
   · 冷却中 ⇒ 触发 `#doom.consumable:on_block_denied`（读 storage `doom.consumable:ctx block.left` = 剩余 tick）；
3. 状态 / 立即就绪 / 移除：`api/block_cd_status` · `api/block_cd_reset` · `api/block_cd_remove`。

### 4.2 设备字段（marker 的 `data.dc`）

| 键 | 含义 |
|---|---|
| `cd_seconds` | 冷却秒数（默认 5） |
| `cd_ready` | 下次可用的游戏刻（0 = 随时可用；放行时写回 now + seconds*20） |
| `cd_key` | 设备名，回调里从 storage `doom.consumable:ctx block.key` 读 |
| `cd_count` | 已激活次数（模块累加，便于观测或做次数限制） |
| `cd_deny_msg` / `cd_deny_sound` | 可选：否决时的聊天栏文本 / 音效 |

### 4.3 入口与外部钩子

- 入口进度：`block_use.json`（`item_used_on_block`）+ `block_use_empty.json`（`default_block_use`，空手也管）
  ⇒ 两条都指向 `doom.consumable:block/entry`。
- 钩子：`#doom.consumable:block_gate`（写 `#block_deny dc.temp 1` 即强制否决）·
  `#doom.consumable:on_block_use` · `#doom.consumable:on_block_denied`。

### 4.4 怎么找到「被交互的那个方块」

原版触发器**不给奖励函数**方块坐标（条件里的 `location` 只用于过滤，函数读不到）⇒
`block/entry` 用「从**眼睛**沿视线每 0.25 格推进、最多 20 步（5 格）」的射线找设备。

⚠ 必须 `anchored eyes`：`run function` 的上下文是玩家**脚底**，直接用会从脚底射出，
几格之外就落到设备下方 —— 开发时实测踩过（守卫通过、却永远命中不了，hit 恒 0）。
⚠ 射线只认本包设备、**不认墙**：隔着墙 5 格内的设备也会被认到（本模块是「设备闸门」，不是物理射线判定）。

### 4.5 能力边界（诚实说明）

方块交互没有「使用前钩子」⇒ **方块自己的行为已经发生了**（箱子开了、按钮按了）。
本模块只做「冷却判定 + 回调」；要不要撤销 / 惩罚 / 换方块状态，由回调决定。
若要「根本按不动」，数据包层面做不到，只能靠方块自身状态（例如 `setblock` 换成另一种方块）。

> 实测（2026-10-01 · 14 断言全绿）：物品路径首次放行（`cd_ready` 差 61 tick ✓、`cd_count` 1→2）·
> 冷却中再交互否决 ✓ · 等 3.5 秒后再放行 ✓ · 外部闸门强制否决 ✓ · 空手路径同样进闸 ✓ ·
> `reset` / `remove` API ✓。两条入口进度的触发都实测过：`item_used_on_block`（放火把）与 `default_block_use`（空手扳拉杆）。

### 4.6 冷却态外观：直接换方块（可选，2026-10-01 追加）

设备可以声明两个方块形态，模块会在冷却开始/结束时自动 `setblock`：

| 字段 | 含义 |
|---|---|
| `cd_block_ready` | 就绪时的方块状态串，例 `minecraft:lever[face=floor,powered=false]` |
| `cd_block_cooling` | 冷却中的方块状态串，例 `minecraft:lever[face=floor,powered=true]` |

时间线：放行 ⇒ 换 `cooling` · 到期 ⇒ `block/tick_restore`（每 5 tick 扫一遍设备）换回 `ready` ·
被否决 ⇒ **重新按回 `cooling`** · `api/block_cd_remove` ⇒ **无条件**换回 `ready` 再删设备。

⚠ 两个坑（2026-10-01 实测）：

1. **方块自身的交互会改自己的状态**（拉杆 `powered`、活板门 `open`…）⇒ 否决时必须重按一次，
   否则外观会说谎（显示「就绪」而逻辑仍在冷却）。
2. 移除设备**不能**复用「到期换回」的逻辑（它带到期判定）⇒ 没到期就删会留下永久冷却态；
   所以 `api/block_cd_remove` 用 `block/force_ready`（无条件的那个）。

> 📄 **技术档案**（设计·引擎取证·41 断言实测·踩坑清单·移植指引·可选扩展）：
> `docs/技术档案-方块冷却闸门-20261001.md`

### 4.7 原型与调试（2026-10-01 追加）

- `api/block_cd_demo` —— 一条命令：[脚下那块方块] 换成拉杆 + 装设备（5 秒冷却 + 否决提示）。
  ① 右键 ⇒ 拉杆抬起、开始冷却 ② 冷却中再右键 ⇒ 被否决（拉杆被按回）③ 5 秒后自动放下 ④ 拆掉用 `api/block_cd_remove`。
- `api/block_cd_debug` —— 16 格内每台设备打状态粒子（**绿=就绪 / 红=冷却中**）+ 打印统计与每台明细。
- `api/block_cd_status|reset|remove` —— 单台设备的状态 / 立即就绪 / 移除。

> **关于「对齐模型」**：`item_model` / `custom_model_data` 是**物品**组件（物品靠它们换外观）；
> **方块**没有组件通道 —— 方块的样子由资源包的 `assets/<ns>/blockstates/<方块>.json` 按**方块状态**决定。
> 所以「方块冷却换外观」的标准做法就是本节的形态切换：挑一个**带布尔状态**的原版方块当载体
> （拉杆 `powered` / 铜灯 `lit` / 活板门 `open` …），资源包里给两个状态各自配模型 ⇒ 视觉与逻辑都对齐。
> 数据包本身**不能新增方块**，只能在这些已存在的状态之间切换。

> 实测（同日 · 15 断言全绿）：demo 一条命令搭起来 · 右键 ⇒ 方块变冷却态 ✓ · 冷却中再右键 ⇒ 否决且方块被按回冷却态 ✓ ·
> 6 秒后自动回到就绪态 ✓ · 冷却结束后可再次激活 ✓ · `debug` 无报错 ✓ · `remove` 先换回就绪态再删 ✓。
