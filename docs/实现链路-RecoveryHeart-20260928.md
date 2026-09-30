# Recovery Heart「耐久恢复」实现链路

> 包：`packs/doom.consumable`（命名空间 `doom.consumable`）
> 目标环境：Minecraft Java 1.21.6+ Fabric（项目定位见 `AGENTS.local.md:11`）
> 包元数据：`pack.mcmeta` 写的是 `pack_format: 81`、`supported_formats: 48–82`、描述 `§6Doom Consumable §eC1 8.5§r - §fMarker Proxy`
> 目录结构：`data/doom.consumable/{advancement,function,loot_table,tags}` + `data/minecraft/tags/{function}`。**本包没有 `predicate/` 目录**（全仓 `find` 确认）。
> 方法：**纯静态阅读**（逐文件 `grep`/`read`，未启动游戏、未运行 `doom.test`）。凡推断/未验证处均已显式标注。
> 日期：2026-09-28

---

## ① 一句话结论

**Recovery Heart 不是"修理玩家手里/背包里其它物品耐久"的消耗品**；它实现的是**「物品自己身上那根伪耐久条的回复」**——用原版 `minecraft:damage` 组件当一根 10 格的条，右键吃掉后由数据包把**它自己**放回原槽并把条打空（`damage = 10`），随后 `recover/*` 每 10 tick 把 `damage` 减 1 格，5 秒回满；限流则由原版 `minecraft:use_cooldown`（5 秒）承担。

四个要点（都可在源码里直接核到）：

1. **入口是原版进度，不是轮询**：右键用掉物品 → `minecraft:consume_item` 进度 → `core/mark_consumed` 置 1 tick 计时器 → 下一 tick `core/process_usage_wrapper` 靠"快照数量差"认出被吃掉的物品（`advancement/consume.json:4`、`core/mark_consumed.mcfunction:2-3`、`tick.mcfunction:8-10`、`core/process_usage_wrapper.mcfunction:11-25`）。
2. **"这能不能用"完全由原版组件负责**：`minecraft:consumable`（`consume_seconds: 0.05`）+ `minecraft:use_cooldown`（`seconds: 5.0`, `cooldown_group: "dc.recover_heart"`）；包侧**没有**任何冷却/次数判定（`loot_table/items/recover_heart.json:13-27`）。
3. **"回复"只认物品自己声明的 `dc.recover:1b`**：`recover/scan` 的每槽守卫只匹配带 `dc{recover:1b}` 的条目，其它物品**连宏调用都不发生**（`recover/scan.mcfunction:22`、`recover/tick_one.mcfunction:25`）。包里**没有**任何"扫全背包找受损物品去修"的代码路径。
4. **计时状态挂在物品上**（`dc.rb_cd` = 离下一格的剩余 tick），不是玩家分数 ⇒ 主手/副手/背包、换手换槽、多件同时在身上都各算各的（`recover/hit.mcfunction:7-19`、`recover/tick_one.mcfunction:14-18`）。

> 排除项（避免误读）：全仓检索 `dc.recover` / `recover_ticks` / `on_use_damage`，命中点**全部**落在 `doom.consumable` 的这一条链与它的探针/套件里，没有第二处消费者；本包也不存在"修缮其他物品耐久"的功能。

---

## ② 触发到生效的完整链路

### 2.1 真机时序（一次使用）

| 时刻          | 谁在动    | 发生了什么                                                                                                                                | 证据                                                                        |
| ----------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| T（玩家右键）     | 原版     | 开始"使用"（`consumable.consume_seconds = 0.05` ≈ 1 tick），`using_item` 进度触发                                                               | `loot_table/items/recover_heart.json:17`、`advancement/using.json:4-17`    |
| T           | 包      | `core/pre_save`：把当前 `SelectedItem` / 副手 / `SelectedItemSlot` 存进 `CACHE.usage`                                                        | `core/pre_save.mcfunction:7-12`                                           |
| T           | 原版 + 包 | 使用完成 → 原版吃掉物品 → `consume_item` 进度 → `core/mark_consumed`：`dc.consume_timer = 1`                                                      | `core/mark_consumed.mcfunction:2-3`                                       |
| T+1         | 包      | `tick.mcfunction:8` 计时器 1→0；`:9` 跑 `core/process_usage_wrapper`                                                                      | `tick.mcfunction:8-10`                                                    |
| T+1         | 包      | 用「快照 count − 当前 count ≥ 1」判定是**哪只手**被消耗；缓存里还必须带 `dc{detect:"consume"}`                                                               | `core/process_usage_wrapper.mcfunction:11-22`                             |
| T+1         | 包      | `core/process_type` → `core/finalize_slot`（定 `slot_cmd = hotbar.N`、`id`）→ `schedule/infinite`                                        | `core/process_type.mcfunction:2-7`、`core/finalize_slot.mcfunction:21-32`  |
| T+1         | 包      | `schedule/infinite` 把物品整份 + 落点写进 `CACHE.consumable`，`args.uses=1`、`args.damage=on_use_damage=10`，然后 `dc.restore_timer = 1`           | `schedule/infinite.mcfunction:16-27`                                      |
| T+2         | 包      | `tick.mcfunction:6` restore_timer 1→0 → `:7` `restore/do_check_timer`                                                                | `tick.mcfunction:6-7`                                                     |
| T+2         | 包      | `restore/do_restore`：建 `item_display` 中转体 → 写入 `damage = 10` → 盖 `resync` 戳 → `restore/guard` 判落点 → 写回 `hotbar.N`                    | `restore/do_restore.mcfunction:28-53`                                     |
| T+2 起每 tick | 包      | `recover/tick` → 逐玩家 `recover/tick_one` → 逐槽 `recover/scan`→`slot`→`hit`：`damage ≥ 1` 且无 `rb_cd` ⇒ 起表 `rb_cd = 10`，同 tick 已减 1（读回 9） | `tick.mcfunction:17`、`recover/hit.mcfunction:43-54`                       |
| 之后每 10 tick | 包      | `rb_cd` 减到 0 的那一 tick：`damage − 1`，`rb_cd` 复位成 `recover_ticks`                                                                       | `recover/hit.mcfunction:49-54`                                            |
| 第 100 tick  | 包      | `damage` 归 0 ⇒ 删除 `dc.rb_cd`（停表）；此时原版 5 秒冷却也到期，可再次使用                                                                                 | `recover/hit.mcfunction:63-65`、`test/give_recover_heart.mcfunction:13-16` |

耗时核对：`10 格 × 10 tick = 100 tick = 5 秒`，与 `use_cooldown.seconds = 5.0` 对齐（`test/give_recover_heart.mcfunction:13` 的注释也是这么写的：*"条涨满 == 冷却结束，节奏完全对齐"*）。

### 2.2 调用图（使用时 + 归还 + 回复）

```text
【A. 使用与识别】原版进度驱动，不是轮询
玩家右键（原版 consumable 0.05s）
├─ advancement doom.consumable:using     trigger=minecraft:using_item, item.dc 存在
│    └─ core/pre_save                    → CACHE.usage{main_snap, off_snap, sel}
└─ advancement doom.consumable:consume   trigger=minecraft:consume_item（无条件）
     └─ core/mark_consumed               → advancement revoke + dc.consume_timer = 1

【B. 每 tick 主链】data/minecraft/tags/function/tick.json → doom.consumable:tick
doom.consumable:tick  (tick.mcfunction)
├─ 6-7   restore_timer 递减；到 0 →  restore/do_check_timer
│                                    └─ restore/do_restore（未 depleted 时）
│                                       ├─ 中转体 item_display[tag=dc_restore_tmp]
│                                       ├─ restore/mark_sync       ← 盖 resync 戳，强制槽位同步包
│                                       ├─ restore/guard {slot_cmd,id} → #can
│                                       │    ├─ 1 → restore/write_at {slot_cmd}     （回原槽）
│                                       │    └─ 0 → restore/put_anywhere → put_slot（第一个空槽）／掉脚下
│                                       └─ kill 中转体
├─ 8-10  consume_timer 递减；到 0 → core/process_usage_wrapper   （见【A】的识别逻辑）
│                                       └─ core/process_type
│                                            ├─ core/finalize_slot   → slot_cmd / id
│                                            └─ schedule/infinite    → CACHE.consumable + restore_timer=1
├─ 12-13 discard_timer 递减 → restore/do_discard_restore        （丢弃链，同构）
├─ 15    core/detect_drop                                      （扫描刚丢出的物品）
├─ 17    recover/tick            ← ★ 耐久条回复的驱动入口
│        └─ as @a at @s → recover/tick_one        （必须"一个玩家一口气跑完"）
│             ├─ 31  core/report_ctx_dirty（rb.item 残留 ⇒ 报 E201，仅自检）
│             ├─ 37-39 副手：rb.item ← equipment.offhand → recover/hit {name:"weapon.offhand"}
│             ├─ 44   #rb_bag=1 → recover/scan        （36 槽逐槽守卫）
│             │         └─ 每槽 → recover/slot {i,name,slot}
│             │              └─ rb.item ← Inventory[{Slot:ib}] → recover/hit {name}
│             │                   └─ 改 damage / rb_cd → item_display[tag=dc_rb] → item replace … $(name)
│             └─ 47-50 #rb_bag=0 → 只认主手（SelectedItem → weapon.mainhand）
├─ 21    core/refresh_hand_cache（没在检测窗口里的玩家刷手部缓存）
├─ 26    rod/tick（鱼竿接口，本文件末尾之前）
└─ 37    core/snapshot_hand（手部快照，**必须是 tick 的最后一步**）
    38  core/watch_offhand（副手看门狗）
```

> `schedule/*` 这个目录名**与 `/schedule` 命令无关**：全包 `grep` 无任何 `schedule function/clear` 命令（`grep -rn "^schedule" .` 零命中），它只是"把这次使用登记进缓存并设定计时器"的派发层命名。

### 2.3 进度文件的分工（入口为什么是这些）

| 进度                             | 触发器                            | 条件                                     | 奖励函数                 |
| ------------------------------ | ------------------------------ | -------------------------------------- | -------------------- |
| `advancement/using.json`       | `minecraft:using_item`         | `item.predicates.custom_data.dc`（存在即可） | `core/pre_save`      |
| `advancement/consume.json`     | `minecraft:consume_item`       | **无条件**                                | `core/mark_consumed` |
| `advancement/item_used.json`   | `minecraft:item_used_on_block` | 排除 7 种方块 + `dc{detect:"place"}`        | `core/mark_placed`   |
| `advancement/inv_change.json`  | `minecraft:inventory_changed`  | 无                                      | `core/save_inv`      |
| `advancement/fishing_rod.json` | `minecraft:fishing_rod_hooked` | `rod` 谓词要求 `dc{rod:true}`              | `rod/catch`          |

Recovery Heart 走的是前两个：`using_item` 提供"被吃之前的那份物品"（快照），`consume_item` 提供"确实吃掉了"的事件。这也是 `consume_seconds > 0` 是硬要求的原因——0 秒时 `using_item` 状态从不出现，快照永远缺失，数量差恒为 0，原版吃掉物品而数据包毫无察觉（lint 规则 C5，`tools/doomtest/lint.mjs:76` 与 `:1200-1208` 的实测注释）。

---

## ③ 关键数据结构与字段

### 3.1 物品侧：Recovery Heart 的组件与 `dc` 契约

来源 `loot_table/items/recover_heart.json:5-31`（物品本体 `minecraft:heart_of_the_sea`）：

| 组件 / 字段                    | 值                                                                       | 作用                                                                                                    | 行号                         |
| -------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------- |
| `minecraft:item_name`      | `{"text":"Recover Heart"}`                                              | 显示名                                                                                                   | `:13`                      |
| `minecraft:max_stack_size` | `1`                                                                     | 不可堆叠（可损坏物品的硬要求）                                                                                       | `:14`                      |
| `minecraft:max_damage`     | `10`                                                                    | **伪耐久条 = 10 格**                                                                                       | `:15`                      |
| `minecraft:damage`         | `0`                                                                     | 初始满格                                                                                                  | `:16`                      |
| `minecraft:consumable`     | `{consume_seconds:0.05, animation:"none", has_consume_particles:false}` | 右键 1 tick 吃完（0 秒会检测不到，规则 C5）                                                                          | `:17`                      |
| `minecraft:use_cooldown`   | `{seconds:5.0, cooldown_group:"dc.recover_heart"}`                      | 原版冷却：5 秒内不能再点，热键栏灰罩                                                                                   | `:18`                      |
| `dc.detect`                | `"consume"`                                                             | 走"吃东西"检测链                                                                                             | `:21`                      |
| `dc.type`                  | `"infinite"`                                                            | 不限次数（**不是一次性消耗品**）                                                                                    | `:22`                      |
| `dc.on_use_damage`         | `10`                                                                    | 每次使用后把自己的条打空                                                                                          | `:23`                      |
| `dc.recover`               | `1`（落盘为 `1b`）                                                           | **参与伪耐久条回复的唯一开关**                                                                                     | `:24`                      |
| （易混）`dc.recover` 记分板目标     | 已停用                                                                     | 与物品字段**同名但不同物**：`scoreboard objectives add dc.recover`（`__load__.mcfunction:13`）只是旧存档兼容的残留目标，本链一行都不读它 | `__load__.mcfunction:8-15` |
| `dc.recover_ticks`         | `10`                                                                    | 每格回复所需 tick（缺省 10）                                                                                    | `:25`                      |

运行时由包自己写的字段（`README.md:27-28` 明确"别手填"）：

| 字段                | 类型  | 写入者                                | 语义                                       |
| ----------------- | --- | ---------------------------------- | ---------------------------------------- |
| `dc.rb_cd`        | int | `recover/hit.mcfunction:64`        | 离下一格的剩余 tick；**存在即"正在回复"**；回满时被删掉（`:65`） |
| `dc.resync`       | int | `restore/mark_sync.mcfunction:16`  | 每刻唯一的时间戳，只为强制服务端发槽位同步包（治"幽灵物品"）          |
| `dc.current_uses` | int | `restore/do_restore.mcfunction:31` | 归还时写入（infinite 类默认 `1`）；本链不使用            |

### 3.2 记分板（`__load__` 建，`__load__.mcfunction`）

| 目标                                                                          | 谁写 / 谁读                                                                 | 用途                                                                 | 行号                     |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------ | ---------------------- |
| `dc.consume_timer`                                                          | 写：`core/mark_consumed:3`、`tick.mcfunction:8,10`                         | 消耗后 1 tick 的延迟窗口                                                   | `__load__:6`           |
| `dc.restore_timer`                                                          | 写：`schedule/infinite:27`、`tick.mcfunction:6`、`restore/do_check_timer:2` | 归还前 1 tick 的延迟窗口                                                   | `__load__:5`           |
| `dc.rb_slot`                                                                | 写：`recover/slot:17`                                                     | **诊断游标**：0 主手 / 1 副手 / 100+N hotbar.N / 200+N inventory.N；不再决定写回目标 | `__load__:18-19`       |
| `dc.cfg`                                                                    | `#resync`（默认 1）、`#rb_bag`（默认 1）、`#rod_lock`（默认 10）                      | 三个开关                                                               | `__load__:42-50,61`    |
| `dc.temp`                                                                   | 全包临时分数                                                                  | `#D/#iv/#cd/#write/#can/#done/…` 都放这里                              | `__load__:20`          |
| `dc.recover` / `dc.recover_interval` / `dc.recover_step`                    | **已停用**（仅保留目标定义，避免旧存档报"未知记分板"）                                          | 旧版玩家级计时器                                                           | `__load__:8-15`        |
| `dc.trigger`/`dc.placed*`/`dc.off_*`/`dc.diag*`/`dc.u.glowstone`/`dc.rod_*` | 诊断与鱼竿链用                                                                 | 与本链无关                                                              | `__load__:21-41,51-61` |

### 3.3 storage

| 位置                                                         | 内容                                                    | 说明                                                                    |
| ---------------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------- |
| `doom.consumable:ctx rb.item`                              | 当前处理的那一件物品的完整 NBT                                     | **全局共享临时键**，因此必须"一个玩家一口气跑完"并每轮清空（`recover/tick_one.mcfunction:27-34`） |
| `doom.consumable:ctx args`                                 | `{i,name,slot}` 宏参数（扁平）                               | 由 `recover/scan` 每槽摆平一次（`recover/scan.mcfunction:21`）                 |
| `doom.consumable:ctx task_data`                            | `{item, hand, sel, slot_path, slot_cmd, id}`          | 识别到使用后的任务包（`core/process_usage_wrapper.mcfunction:19-25`）             |
| `doom.library:io players.data.<idx>.CACHE.usage`           | `{main_snap, off_snap, sel}`                          | 手部快照（`core/pre_save.mcfunction:7-12`）                                 |
| `doom.library:io players.data.<idx>.CACHE.consumable`      | `{item, slot_path, slot_cmd, id, args:{uses,damage}}` | 归还所需的全部信息（`schedule/infinite.mcfunction:6-27`）                        |
| `doom.library:io output[-1].data`                          | 读缓存的结果位                                               | `doom.library:api/read.mcfunction:6-7`                                |
| `doom.library:io players.data.<idx>.CACHE.<key>.timestamp` | 缓存写入时刻                                                | `doom.library:api/cache.mcfunction:8`                                 |

---

## ④ 核心函数逐段讲解

### 4.1 `recover/tick`：只做"逐玩家分发"

```mcfunction
# recover/tick.mcfunction:17
execute as @a at @s run function doom.consumable:recover/tick_one
```

文件头写明了纪律：共享临时（`rb.item` + 中转体 tag）是**全局一份**，若拆成多条 `as @a` 行，多玩家会互相覆盖（`recover/tick.mcfunction:11-16`）。`at @s` 是需要的——`recover/hit` 里的 `summon ~ ~ ~` 落点就是玩家脚下。

### 4.2 `recover/tick_one`：闸门 + 副手 + 背包

```mcfunction
# recover/tick_one.mcfunction:25 —— 门槛（绝大多数玩家零开销）
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{recover:1b}}}}] unless data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run return 0
```

```mcfunction
# recover/tick_one.mcfunction:31 —— 并发自检哨兵（必须在下面 data remove 之前）
execute if data storage doom.consumable:ctx rb.item run function doom.consumable:core/report_ctx_dirty
# :34
data remove storage doom.consumable:ctx rb.item
# :37-39 —— 副手：不在 Inventory 列表里，单独一步
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run data modify storage doom.consumable:ctx rb.item set from entity @s equipment.offhand
data modify storage doom.consumable:ctx args set value {name:"weapon.offhand",slot:1}
execute if data storage doom.consumable:ctx rb.item run function doom.consumable:recover/hit with storage doom.consumable:ctx args
# :44 —— 背包 + 主手（主手就是被选中的那个热键槽，由扫描统一处理，**不再单独处理一次**）
execute if score #rb_bag dc.cfg matches 1 run function doom.consumable:recover/scan
```

`#rb_bag dc.cfg = 0` 时退回"只认手部"（主手 + 副手），见 `:47-50`；两条分支最后都清一次 `rb.item`（`:53`）。

### 4.3 `recover/scan` + `recover/slot`：36 槽逐槽扫描

`scan` 是**脚本生成**的（生成器 `tools/gen_recover_slots.py`，槽位命名规则见 `:60-66`），每槽两行：

```mcfunction
# recover/scan.mcfunction:41-42（示例：Inventory.Slot 9 → inventory.0）
data modify storage doom.consumable:ctx args set value {i:9,name:"inventory.0",slot:200}
execute if data entity @s Inventory[{Slot:9b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
```

- 覆盖范围：`Inventory.Slot 0-8 → hotbar.0-8`（`:20-38`）、`Inventory.Slot 9-35 → inventory.0-26`（`:40-94`）。
- **只有带 `dc{recover:1b}` 的槽位才进入宏调用**；其它物品零开销。
- 扫完清 `rb.item`：`:96-97`。

`recover/slot` 三行各司其职（`recover/slot.mcfunction:1-19`）：

```mcfunction
# recover/slot.mcfunction:17-19
$scoreboard players set @s dc.rb_slot $(slot)                                  # ① 诊断游标
$data modify storage doom.consumable:ctx rb.item set from entity @s Inventory[{Slot:$(i)b}]   # ② 取件
function doom.consumable:recover/hit with storage doom.consumable:ctx args     # ③ 交给 hit
```

> `Inventory` 条目自带 `Slot` 字段，NBT 过滤器能一次取出命中的那一件——但**不能**在过滤器后再接 `[0]` 索引（项目已钉死，`recover/slot.mcfunction:12-16`）。

### 4.4 `recover/hit`：**真正改耐久的地方**

状态机（`recover/hit.mcfunction:7-10` 的头部注释 + `:43-54` 的实现）：

```mcfunction
# :25-26 读 damage（**缺省 0 = 满条**）
scoreboard players set #D dc.temp 0
execute if data storage doom.consumable:ctx rb.item.components."minecraft:damage" store result score #D dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:damage"

# :31-33 读间隔：物品自报 dc.recover_ticks，缺省 10；≤0 也回落到 10
scoreboard players set #iv dc.temp 10
execute if data storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".recover_ticks store result score #iv dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".recover_ticks
execute if score #iv dc.temp matches ..0 run scoreboard players set #iv dc.temp 10

# :36-37 读倒计时（-1 = 这件没在回复）
scoreboard players set #cd dc.temp -1
execute if data storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".rb_cd store result score #cd dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".rb_cd

# :43  满条：只在"还残留着 rb_cd"时写一次（自愈，防停不掉的表）
execute if score #D dc.temp matches ..0 if score #cd dc.temp matches 0.. run scoreboard players set #write dc.temp 1
# :46-47 未满 + 没在回复 → 起表
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches ..-1 run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches ..-1 run scoreboard players operation #cd dc.temp = #iv dc.temp
# :50-54 未满 + 在回复 → 先减后判（否则最后一格永远差一格）
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 1.. run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 1.. run scoreboard players remove #cd dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players remove #D dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players operation #cd dc.temp = #iv dc.temp
# :56 什么都不用改 ⇒ 直接返回（不建中转体）
execute if score #write dc.temp matches 0 run return 0
```

写回路径（`recover/hit.mcfunction:59-68`）：

```mcfunction
kill @e[type=item_display,tag=dc_rb]                                     # 先清残留（专包专用 tag）
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_rb"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_rb,limit=1] item set from storage doom.consumable:ctx rb.item
execute store result entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:damage" int 1 run scoreboard players get #D dc.temp
execute if score #D dc.temp matches 1.. store result entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd int 1 run scoreboard players get #cd dc.temp
execute if score #D dc.temp matches 0 if data entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd run data remove entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd
$item replace entity @s $(name) from entity @e[type=item_display,tag=dc_rb,limit=1] contents
kill @e[type=item_display,tag=dc_rb,limit=1]
data remove storage doom.consumable:ctx rb.item
```

**回答"一次修多少 / 保不保留其它数据"**：

- 一次只动**1 格**（`damage − 1`），而且只在 `rb_cd` 归零的那一 tick 动；**没有**一次回满的路径，也没有批量循环。
- 物品**整份**来自目标槽（`rb.item` 就是那一槽的 Inventory 条目），写回时**只覆盖两个位置**：`components."minecraft:damage"` 与 `components."minecraft:custom_data"."dc".rb_cd`。附魔、`item_name`、其它 NBT/组件、`count` 都原样保留。
- 每 tick 每件最多处理一次（`hit` 每个调用只处理一件）。

### 4.5 归还链（`restore/*`）：把被吃掉的物品放回**原来的那一格**

1. `restore/do_check_timer.mcfunction:2-18`：清 `restore_timer` → 读 `CACHE.consumable` → 有 `depleted` 才走 `do_depleted`（返还 `remainder`）→ 否则 `do_restore`；结尾清缓存。
2. `restore/do_restore.mcfunction:28-36`：建 `item_display[tag=dc_restore_tmp]`，`item` ← 缓存里的物品，写 `current_uses`（`:31`），**仅当物品带 `max_damage` 才写 `damage`**（`:36`，这是给 Recovery Heart 写 `damage = 10` 的那一行）。
3. `restore/mark_sync.mcfunction:16`：`store result entity … "dc".resync int 1 run time query gametime` —— 每刻唯一的戳，治「幽灵物品」（同 tick 消耗+归还、内容逐字节相同 ⇒ 服务端判定"槽位没变"而不发包 ⇒ 客户端停在"已消耗"画面）。
4. 落点三选一（`restore/do_restore.mcfunction:48-50`）：
   - `restore/guard`：`#can = 1` 当且仅当**目标槽是空的**或**里面还是同一件**（`restore/guard.mcfunction:18-20`，用 1.21.5+ 的 `execute if items entity @s <slot> <pred>`）；
   - `#can = 1` → `restore/write_at`：`$item replace entity @s $(slot_cmd) from entity … contents`（`restore/write_at.mcfunction:6`）；
   - `#can = 0` → `restore/put_anywhere`：按 `hotbar.0-8 → inventory.0-26` 找第一个空槽，经 `restore/put_slot` 写入（`restore/put_anywhere.mcfunction:21-91`、`restore/put_slot.mcfunction:19-20`）；36 格全满才 `summon minecraft:item` 掉在脚下（`:93-99`）。**任何一条路都不销毁、不覆盖**。
5. `restore/do_restore.mcfunction:53` 杀掉中转体。

`slot_cmd` 的来历（`core/finalize_slot.mcfunction:21-32`）：主手能精确到 `hotbar.N`（用消耗那一刻的 `SelectedItemSlot`，经 `core/sel_slot_cmd.mcfunction:13` 的宏把数字翻成槽位名），副手固定 `weapon.offhand`，读不到读数时退化成 `slot_path`（旧行为）。

### 4.6 识别段（`process_usage_wrapper` / `process_type` / `schedule/infinite`）

```mcfunction
# core/process_usage_wrapper.mcfunction:12-22（节选）
execute store result score #now_main dc.temp run data get entity @s SelectedItem.count
scoreboard players operation #main_diff dc.temp = #snap_main dc.temp
scoreboard players operation #main_diff dc.temp -= #now_main dc.temp
execute if score #main_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc"{detect:"consume"} run data modify storage doom.consumable:ctx task_data.item set from storage doom.library:io output[-1].data.CACHE.usage.data.main_snap
```

```mcfunction
# core/process_type.mcfunction:5-7
execute if data storage doom.consumable:ctx task_data.hand run function doom.consumable:core/finalize_slot
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"limited"} run function doom.consumable:schedule/limited with storage doom.consumable:ctx task_data
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"infinite"} run function doom.consumable:schedule/infinite with storage doom.consumable:ctx task_data
```

```mcfunction
# schedule/infinite.mcfunction:16-27（Recovery Heart 走这条）
data modify storage doom.library:ctx _.cache_data.args.uses set value 1
data modify storage doom.library:ctx _.cache_data.args.damage set value 0
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".on_use_damage run data modify storage doom.library:ctx _.cache_data.args.damage set from storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".on_use_damage
function doom.library:api/cache with storage doom.library:ctx _
scoreboard players set @s dc.restore_timer 1
```

- `args.damage` 默认 0（老行为）；Recovery Heart 靠 `dc.on_use_damage = 10` 变成"用完打空条"（`:19-22` 的注释直接点名 `items/recover_heart`）。
- `args.uses` 默认 1，只有物品带 `current_uses` 才覆盖（`:12-17` 的加固注释：无条件的 `set from` 会在源缺失时**中止整个函数**，导致"物品用掉就再也回不来"）。
- `schedule/limited`（有限次数类）会把 `max_damage` 当刻度算 `damage = maxbar − uses`（`schedule/limited.mcfunction:39-42`），耗尽时按 `depleted` 走 `disable/vanish/remainder`，并只清"当初那个槽、且还是同一件"（`schedule/limited.mcfunction:106-113,137`、`schedule/clear_slot.mcfunction:17`）。Recovery Heart 是 `infinite`，**完全不经过这条**。

### 4.7 1.21.6 里"读写物品 NBT"的正确写法（本包实际用法）

| 目的                    | 写法                                                                                                                                | 出处                                                                                        |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **读**手上物品的组件          | `data get entity @s SelectedItem.components."minecraft:damage"`（`components."<组件id>"`，带引号）                                        | `test/probe_recover_all.mcfunction:10`                                                    |
| **读**某一槽的整件           | `data modify storage <s> <k> set from entity @s Inventory[{Slot:12b}]`                                                            | `recover/slot.mcfunction:18`                                                              |
| **匹配**槽位里的物品          | `Inventory[{Slot:12b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}]`                                                    | `recover/scan.mcfunction:22`                                                              |
| **写**实体上物品的组件         | `data modify entity <e> item.components."minecraft:damage" set value <n>`                                                         | `api/rod_durability.mcfunction:11`                                                        |
| **写**（从分数）            | `execute store result entity <e> item.components."minecraft:custom_data"."dc".rb_cd int 1 run scoreboard players get #cd dc.temp` | `recover/hit.mcfunction:64`                                                               |
| **删**组件里的键            | `data remove entity <e> item.components."minecraft:custom_data"."dc".rb_cd`                                                       | `recover/hit.mcfunction:65`                                                               |
| **写**玩家槽位             | 只能用 `item replace entity @s <slot> from entity <item_display> contents`（玩家背包**不能**用 `data modify` 写，项目已钉）                         | `recover/hit.mcfunction:66`、`restore/write_at.mcfunction:6`、`rod/writeback.mcfunction:8`  |
| 槽位名                   | `hotbar.N` / `inventory.N` / `weapon.mainhand` / `weapon.offhand`；`N` 只能是字面量 ⇒ 用宏代换                                               | `core/sel_slot_cmd.mcfunction:13`；`tools/gen_recover_slots.py:6-7`（`container.N` 对玩家实体非法） |
| **判占用 / 同件**（1.21.5+） | `execute if items entity @s <slot> *` / `execute if items entity @s <slot> <item_id>`                                             | `restore/guard.mcfunction:19-20`                                                          |
| 数字宽度                  | loot_table JSON 的数字按**最小宽度**落盘（`10` → `10b`）：判据要写 `1b`/`12b`，比较数值用 `data get`（**不要**用 NBT 数字判据比宽度）                                | `recover/hit.mcfunction:29-30`、`tools/doomtest/lint.mjs:82`（C12）                          |
| **移除原版组件**            | 写 `"!minecraft:consumable": {}`（1.21.5+ 的"显式移除"形态，`data remove` 删不掉原型自带的组件）                                                       | `schedule/limited.mcfunction:72-79,108`                                                   |

---

## ⑤ 边界与已知坑

### 5.1 设计上明确处理的

| 边界                     | 行为                                                                                                                  | 证据                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 条是满的（`damage` 缺失或 0）   | **不写任何东西**（`#write=0` 直接 `return 0`）；只有"还残留 `rb_cd`"时才清一次表                                                          | `recover/hit.mcfunction:25-26,43,56`                                                                                  |
| 非参与物品                  | 没有 `dc{recover:1b}` 的槽位**连 `recover/slot` 都不调用**；即使被强行送进 `hit`，`damage` 缺失 ⇒ 视为满条 ⇒ 不写 `damage`、也不会给它新增 `damage` 组件 | `recover/scan.mcfunction:22`、`recover/hit.mcfunction:26`、`doom.test:suite/consumable_recover.mcfunction:201-207`（断言⑩） |
| 换手 / 换槽 / 进背包          | 进度不失步（状态在物品上），写回按每件的槽位名                                                                                             | `recover/tick_one.mcfunction:14-18`、`recover/scan.mcfunction:12-13`                                                   |
| 多件同时在身上                | 逐槽扫描 ⇒ 各算各的，不串台（旧版玩家级计时器的病根）                                                                                        | `recover/scan.mcfunction:6-13`、`recover/hit.mcfunction:12-19`、套件 ⑥~⑧ 断言                                               |
| 回满停表                   | `damage = 0` ⇒ 删 `rb_cd`；再驱动也不会变负                                                                                   | `recover/hit.mcfunction:63-65`、套件 ⑨ 断言                                                                                |
| 物品被别的手段修好              | 满条 + 残留 `rb_cd` ⇒ 只清表（自愈）                                                                                           | `recover/hit.mcfunction:42-43`                                                                                        |
| 归还时目标槽被别人占了            | **绝不覆盖**：找第一个空槽，36 格全满才掉脚下（`PickupDelay: 0`，可立刻捡回）并给一句黄字                                                            | `restore/guard.mcfunction:8-17`、`restore/put_anywhere.mcfunction:93-99`                                               |
| 同 tick 消耗 + 归还导致"幽灵物品" | `restore/mark_sync` 盖每刻唯一戳强制发包；开关 `#resync dc.cfg`（默认 1）                                                            | `restore/mark_sync.mcfunction:6-16`、`__load__.mcfunction:42-46`                                                       |
| 玩家在"消耗→归还"之间换槽         | 落点精确到 `hotbar.N`（消耗那一刻的 `SelectedItemSlot`），不再写"当前选中槽"                                                              | `core/finalize_slot.mcfunction:6-19`                                                                                  |
| 残留中转体                  | 每条流程都"先 kill 再 summon"，用完立刻 kill                                                                                    | `recover/hit.mcfunction:59`、`restore/do_restore.mcfunction:28`                                                        |
| 多玩家 + 共享临时键            | 逐玩家体必须"一口气跑完"；`rb.item` 残留时报 E201（`doom.log`）                                                                       | `recover/tick_one.mcfunction:4-12,27-31`、`core/report_ctx_dirty.mcfunction:13`                                        |

### 5.2 未实现 / 需注意

| 项                                    | 事实                                                                                                                | 证据 / 备注                                                                                                  |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **它不修别人的耐久**                         | 全链只处理带 `dc.recover:1b` 的物品自身；包里没有"扫受损物品"的代码                                                                       | 全仓 `grep dc.recover` 只命中本链                                                                               |
| 盔甲槽 / 末影箱 / 容器 / 合成格                 | **不参与**回复：扫描范围只有 `Inventory` 的 36 格 + `equipment.offhand`；包里没有出现任何其他槽位路径                                          | `recover/scan.mcfunction:20-94`、`recover/tick_one.mcfunction:37`                                         |
| 耐久上限                                 | **不读 `max_damage`**：`hit` 只把 `damage` 减到 0 就停，不校验上限、不夹取                                                           | `recover/hit.mcfunction:25-26,53`                                                                        |
| 不读 `damage` 的默认值                     | 缺失即 `0` = 满条（因此"没有耐久条 + 带 `recover:1b`"的物品是**空转**，不会被写坏）                                                          | `recover/hit.mcfunction:25-26`；套件⑩断言"不会被加上 damage 组件"                                                    |
| 堆叠物品                                 | 没有特殊处理：整叠一起读、一起写回；`damage` 是栈级组件 ⇒ 一叠只算"一件"的进度。Recovery Heart 自身 `max_stack_size: 1`                              | `recover/hit.mcfunction:61,66`、`loot_table/items/recover_heart.json:14`                                  |
| 不可损坏物品（`unbreakable`/无 `max_damage`） | 无专门判据（全包 `grep unbreakable` 零命中）；靠"`damage` 读不到 ⇒ 满条 ⇒ 不写"间接安全                                                    | `recover/hit.mcfunction:26`（推断，未真机验证）                                                                    |
| 创造模式                                 | **无任何 gamemode 判断**（全包 gamemode 判据只出现在 place 类测试夹具的告警里）。若原版在该模式下不消耗物品，则 `consume_item` 不触发 ⇒ 链路整条不启动（结果是"什么都不发生"） | `test/place_once.mcfunction:27-28` 等；consume 侧的创造模式行为**未验证**                                             |
| 原版 5 秒冷却                             | 包**不读不写** `use_cooldown`（全包 `use_cooldown` 只出现在鱼竿链与探针里）；灰罩 5 秒是物品组件 + 原版行为，包只管条                                   | `grep use_cooldown`（只命中 `rod/*`、`api/rod_*`、`test/*`）；`test/give_recover_heart.mcfunction:14-15` 是作者写的预期 |
| 离线玩家                                 | 不处理：`recover/tick` 只跑 `@a`（在线）。因为状态在物品上，"离线期间表不走"是可预期的；但**未验证**（尤其"消耗后立刻退出→重进"时的归还路径，计时器是玩家分数，跨会话是否按期补跑未验证）       | `recover/tick.mcfunction:17`                                                                             |
| `ghost_wipe`                         | 只是**测试夹具**的清场函数（杀残留 `dc_restore_tmp`/`dc_tmp` 中转体、清双手、复位诊断与三个计时器），不是生产链的一环                                        | `test/ghost_wipe.mcfunction:8-20`                                                                        |
| `rb.item` 会带上 `Slot` 字段              | `set from entity @s Inventory[{Slot:ib}]` 取的是**整个条目**（含 `Slot:Nb`），中转体的 `item` 因此也带这个键；包内不做清理，也没有注释说明它被验证过        | `recover/slot.mcfunction:18`、`recover/hit.mcfunction:61`（**观察项，未验证是否对物品有副作用**）                           |
| 测试夹具的注释漂移                            | `doom.test` 的泵函数头注释仍写"timer = damage × interval"（旧玩家级计时器模型），与 09-27 改版后的物品级 `rb_cd` 不符；虽然"不读真实时间、可同步驱动"的结论仍成立     | `packs/doom.test/.../lib/recover_pump.mcfunction:4-6`                                                    |
| 性能                                   | 只有身上带着 `dc{recover:1b}` 物品的玩家才付出"每 tick 36 条守卫行 + 1 条副手守卫"的代价；其余玩家被 `:25` 的门槛挡掉                                   | `recover/tick_one.mcfunction:20-22,25`                                                                   |
| 恢复速率下限                               | 每 tick 每件最多 1 格（无内层循环）⇒ `recover_ticks = 1` 时 10 格也要 10 tick 才回满                                                  | `recover/hit.mcfunction:50-54`                                                                           |

---

## ⑥ 如果我要在自己包里复刻：最小清单

1. **物品侧（loot table / 物品参数）**
   - `minecraft:max_damage: <格数>` + `minecraft:damage: 0` + `minecraft:max_stack_size: 1`（可损坏又不可堆叠是硬要求，否则加载期报 `Item cannot be both damageable and stackable`，规则 C6）。
   - `minecraft:consumable: {consume_seconds: 0.05, ...}`：**必须 > 0**（0 秒时 `using_item` 不出现，链整条不启动，规则 C5）。
   - 想让它"用完才回"：加 `dc.on_use_damage: <格数>`；想让它"用一次掉一格慢慢回"：改成 `on_use_damage: 1`。
   - 限流可加 `minecraft:use_cooldown: {seconds: <格数 × recover_ticks / 20>, cooldown_group: "<你的组名>"}`。
   - 契约：`dc.detect:"consume"`、`dc.type:"infinite"`、`dc.recover:1b`（**byte，判据必须写 `1b`**）、`dc.recover_ticks:<int,缺省10>`。
2. **触发侧**：两个进度（`using_item` → 存手部快照；`consume_item` → 置 1 tick 计时器）+ 一个 `#minecraft:tick`，缺一不可（`using_item` 那份快照就是"被吃之前的那份物品"）。
3. **归还侧**（可选但强烈建议，否则物品吃一次就没了）：缓存"物品整份 + 槽位名 + 物品 id"，下一 tick 用 `item replace entity @s <slot> from entity <item_display> contents` 写回；写入前判"空或同一件"，不满足就换空槽/掉脚下，**永不覆盖**。主手要精确到 `hotbar.N`（否则玩家换槽会吞东西）。
4. **回复侧**：每 tick `execute as @a at @s run function <your>:recover_tick_one`，闸门 `unless data entity @s Inventory[{…dc:{recover:1b}}] … run return 0`，然后逐槽 `Inventory[{Slot:Nb,components:{…}}]` 守卫 → 取件 → 状态机（`rb_cd` 存在 / 起表 / 先减后判 / 归零时 `damage − 1`）→ 中转体写回。
5. **一条纪律**：逐玩家体里**不要**把"取件"和"写回"拆成多条 `as @a`（共享 `rb.item` + `limit=1` 中转体会被后一个玩家覆盖）；状态一律放物品上（`dc.rb_cd`），不要放玩家分数。
6. **回归测试**：至少覆盖"起表 / 满 10 tick 才涨一格 / 换副手 / 进背包 / 三件各自独立 / 满条不挡别人 / 回满停表 / 无字段不参与"这 8 类（可直接照抄 `packs/doom.test/data/doom.test/function/suite/consumable_recover.mcfunction` 的断言清单）。

---

## ⑦ 证据索引（`文件:行号`）

**物品与契约**

- `loot_table/items/recover_heart.json:5-31`（组件与 `dc` 全表）、`:13-18`（consumable / use_cooldown）、`:19-27`（dc 字段）
- `README.md:12-28`（`dc` 契约表；`recover`/`recover_ticks`、运行时字段 `rb_cd`/`resync`）
- `pack.mcmeta:1-9`（pack_format 81 / supported 48–82 / 描述 C1 8.5）

**入口 / 识别**

- `advancement/using.json:4-17`、`advancement/consume.json:4-8`、`advancement/item_used.json:4-37`、`advancement/inv_change.json:4-9`
- `core/pre_save.mcfunction:2-15`、`core/mark_consumed.mcfunction:2-3`、`core/save_inv.mcfunction:16-35`
- `tick.mcfunction:6-10`（两个计时器）、`:17`（recover 驱动）、`:26,37-38`（rod/快照/看门狗）
- `core/process_usage_wrapper.mcfunction:11-25`、`core/process_type.mcfunction:2-7`
- `core/finalize_slot.mcfunction:21-32`、`core/sel_slot_cmd.mcfunction:3-13`

**回复（耐久恢复本体）**

- `recover/tick.mcfunction:1-17`、`recover/tick_one.mcfunction:4-53`
- `recover/scan.mcfunction:1-19`（设计说明）、`:20-38`（快捷栏）、`:40-94`（背包）、`:96-97`（清理）
- `recover/slot.mcfunction:1-19`
- `recover/hit.mcfunction:1-22`（状态模型与教训）、`:24-37`（读 damage/间隔/倒计时）、`:39-56`（状态机）、`:59-68`（写回）、`:70-71`（"生产代码不刷聊天栏"）
- `tools/gen_recover_slots.py:1-24`（生成器说明与游标编码）、`:60-66`（槽位名/编码规则）、`:74-78`（每槽两行）

**归还 / 落点守卫**

- `schedule/infinite.mcfunction:12-27`（infinite 类缓存契约）、`schedule/limited.mcfunction:14-50,106-113,116-142`
- `schedule/clear_slot.mcfunction:1-17`
- `restore/do_check_timer.mcfunction:2-18`、`restore/do_restore.mcfunction:6-53`
- `restore/guard.mcfunction:5-20`、`restore/write_at.mcfunction:1-6`、`restore/put_anywhere.mcfunction:1-20,93-99`、`restore/put_slot.mcfunction:1-20`
- `restore/mark_sync.mcfunction:1-16`、`restore/do_depleted.mcfunction:1-2`、`restore/notify_depleted.mcfunction:1-9`
- `restore/do_discard_restore.mcfunction:1-38`（丢弃链复用同一套落点规则）

**配置 / 自检 / 依赖**

- `__load__.mcfunction:4-50,61`（记分板、`#resync`、`#rb_bag`、`#rod_lock`；`:8-15` 说明旧玩家级计时器已停用）
- `data/minecraft/tags/function/load.json`、`data/minecraft/tags/function/tick.json`
- `core/report_ctx_dirty.mcfunction:1-13`（E201 哨兵；对接 `doom.log:error`）
- `packs/doom.library/data/doom.library/function/api/ensure.mcfunction:1-13`、`api/read.mcfunction:1-7`、`api/cache.mcfunction:1-8`
- `packs/doom.log/README.md:11-15,64-74`（`doom.log:error {code,message}` 与 E2xx 段；`:74` 写明已接入 `recover/tick_one`）

**测试与工具（未运行，仅读源码）**

- `packs/doom.test/data/doom.test/function/suite/consumable_recover.mcfunction:21-207`（断言主体：起表/rb_cd=9/10 tick 涨格/副手/背包/游标/多件独立/满条不挡/回满停表/无字段不参与）
- `packs/doom.test/data/doom.test/function/lib/recover_pump.mcfunction:1-11`（同步泵）、`run_one.mcfunction:30`（挂载点）
- `test/give_recover_heart.mcfunction:1-27`、`test/give_recover_heart_3.mcfunction:1-10`（作者写的时间线预期）
- `test/probe_recover_all.mcfunction:1-35`、`test/probe_recover_state.mcfunction:1-17`、`test/probe_multi_recover*.mcfunction`（判读口径）
- `test/ghost_wipe.mcfunction:1-20`（清场夹具）
- `tools/doomtest/lint.mjs:75-90`（规则表：C4/C5/C6/C12/E2）、`:1170-1210`（C4/C5 的实测依据）

**API（与本链无关，供对照）**

- `api/rod_durability.mcfunction:1-12`、`api/rod_durability_add.mcfunction:1-19`、`api/rod_disable.mcfunction:1-13`、`api/rod_enable.mcfunction:1-11`、`api/rod_reel.mcfunction:1-16`、`api/rod_reel_impl.mcfunction:1-7`、`api/rod_casting.mcfunction:1-6`
- `rod/pick.mcfunction:1-20`、`rod/writeback.mcfunction:1-16`、`rod/catch.mcfunction:1-17`、`rod/lock.mcfunction:1-24`、`rod/tick.mcfunction:1-25`、`rod/tick_one.mcfunction:1-26`、`rod/gate.mcfunction:1-22`、`rod/cast.mcfunction:1-7`、`rod/cast_ok.mcfunction:1-6`、`rod/deny.mcfunction:1-27`、`rod/reel.mcfunction:1-7`

**外部对照（同仓文档，仅作背景）**

- `doom.consumable检视报告.md:4`（包规模：80 函数 / 2239 行）、`:81-85`（健康项清单）
- `AGENTS.local.md:11`（1.21.6+ 原版数据包系列）、`:56-74`（鱼竿接口任务状态）
- `数据包易错点总结.md` §2.4（storage 污染 / "拿既要读又要写的判据当守卫"，被 `recover/*` 与 `restore/put_slot` 多处引用）

---

## ⑧ 本次未验证 / 未实现清单（诚实声明）

**未验证（本次为纯静态阅读，没有启动游戏、没有跑 `doom.test`）**

1. 真机时间线（"条涨满 == 冷却结束"、灰罩时长）来自作者注释与探针口径，本次未实测。
2. `minecraft:use_cooldown` 的冷却状态是否在物品被"吃掉后重建"时保留 —— 包内既不读也不写冷却状态，无法从源码判断，**未验证**。
3. 创造模式下的行为（原版是否消耗、`consume_item` 是否触发），以及离线玩家 / 死亡 / 换维度等场景，**未验证**。
4. `rb.item` 携带 `Slot` 字段被带进中转体后的实际影响，**未验证**（观察项）。
5. 多玩家同 tick 并发时 `dc_rb`（`recover/hit`）与 `dc_restore_tmp`（`restore/*`）两个 tag 的中转体是否绝对互不干扰 —— 代码纪律上成立（"先 kill 再建、用完即杀、tick 内顺序执行"），但**未实测**。

**未实现**

1. 盔甲槽 / 末影箱 / 容器 / 合成格不参与回复（无任何相关代码路径）。
2. 没有"修复玩家其它物品耐久"的功能 —— 与本链的语义不同，若有此需求需另写。
3. 没有耐久上限校验（不读 `max_damage`）、没有堆叠特殊处理、没有创造模式分流、没有对"任意受损物品"的通用过滤。
4. 用户可见反馈只有原版的两处：耐久条本身、`use_cooldown` 的灰罩；包侧**不刷聊天栏**（唯一例外是归还兜底的"手/背包都被占着"黄字，`restore/put_anywhere.mcfunction:96`）。
