# doom.consumable:__load__
#
# doomtest-ignore: E2 —— 加载期设置，不涉及"逐实体流水线跨行共享状态"。
scoreboard objectives add dc.check_use dummy
scoreboard objectives add dc.restore_timer dummy
scoreboard objectives add dc.consume_timer dummy
scoreboard objectives add dc.discard_timer dummy
# ⚠ 2026-09-27：伪耐久条的计时状态**不再存玩家分数**了 ——
#   dc.recover / dc.recover_interval / dc.recover_step 三块已停用（定义保留，免得旧存档/旧命令
#   报"未知记分板"）。状态现在**跟着物品自己走**：items 的 dc.rb_cd = 离下一格的剩余 tick。
#   起因：玩家报障「两件同时在身上时条会串台/跳变」—— 玩家级计时器 + 每 tick 挑一件写回，
#   必然把 A 的进度写到 B 身上。详见 recover/hit 与 recover/tick_one 的头部说明。
scoreboard objectives add dc.recover dummy
scoreboard objectives add dc.recover_interval dummy
scoreboard objectives add dc.recover_step dummy
# 回复扫描的**诊断**游标（recover/scan 每命中一槽写一次；真正的落点由宏参数里的槽位名决定）：
#   0 主手 / 1 副手 / 100+N hotbar.N / 200+N inventory.N
scoreboard objectives add dc.rb_slot dummy
scoreboard players set @a dc.rb_slot -1
# 方块类型冷却配置（≈ 方块版 use_cooldown）：仅当不存在时初始化，避免 /reload 覆盖作者配置
execute unless data storage doom.consumable:block_cd entries run data modify storage doom.consumable:block_cd entries set value []
scoreboard objectives add dc.block_use dummy
scoreboard objectives add dc.block_denied dummy
scoreboard objectives add dc.temp dummy
scoreboard objectives add dc.placed dummy
scoreboard objectives add dc.trigger dummy
scoreboard objectives add dc.lastcount dummy
scoreboard objectives add dc.placed_main dummy
scoreboard objectives add dc.placed_off dummy
scoreboard objectives add dc.off_prev dummy
scoreboard objectives add dc.off_spike dummy
scoreboard objectives add dc.off_spike_n dummy
# 放置节奏取证（间隔分布 = 分辨"点击被吞"还是"纯显示问题"）
scoreboard objectives add dc.diag dummy
scoreboard players set #n dc.diag 0
scoreboard players set #last dc.diag 0
scoreboard players set #now dc.diag 0
scoreboard players set #gap dc.diag 0
scoreboard players set #maxgap dc.diag 0
scoreboard players set #sumgap dc.diag 0
scoreboard players set #sumslow dc.diag 0
scoreboard players set #slow dc.diag 0
scoreboard players set #bursts dc.diag 0
# 原版"使用次数"计数：与数据包认出的放置次数对照（客户端若以为手是空的，这里也不会涨）
scoreboard objectives add dc.u.glowstone minecraft.used:minecraft.glowstone
# 客户端重同步开关：**默认 1 = 开**（2026-09-26 A/B 坐实「幽灵」病根与修法，见 restore/mark_sync）。
#   1 = 每次把物品塞回玩家之前盖一个每刻唯一的戳 ⇒ 服务端必定发槽位同步包 ⇒ 客户端不会停在"已消耗"画面。
#   0 = 复现幽灵用（test/ghost_start 会显式置 0，test/ghost_start_on 显式置 1）。
scoreboard objectives add dc.cfg dummy
scoreboard players set #resync dc.cfg 1
# 背包回复开关：1 = 背包里的伪耐久条也回（默认）；0 = 退回"只认手部"（主手 + 副手）。
#   套件里"只认手部"那几条会临时置 0 —— 玩家身上别的测试残留就不会掺进来。
#   见 recover/tick_one（门槛与两条分支都在这一个文件里）。
scoreboard players set #rb_bag dc.cfg 1
# ---- 鱼竿右键接口（2026-09-27）----
# dc.rod_use：准则 minecraft.used:minecraft.fishing_rod —— **仅抛竿** +1（B1 源码实锤：awardStat
#   只在 FishingRodItem.use 的抛竿分支，收竿分支零统计）⇒ 统计上涨 = 抛竿，只路由 rod/cast。
#   收杆事件源是 rod/watch_impl 的浮标死亡监听（归属标签 dc_rod_own_<uid>）。
scoreboard objectives add dc.rod_use minecraft.used:minecraft.fishing_rod
scoreboard objectives add dc.rod_prev dummy
# dc.rod_state：0 = 未抛竿 / 1 = 正在钓鱼（状态机，由 rod/tick 维护）
scoreboard objectives add dc.rod_state dummy
# dc.rod_uid：玩家 UUID[0] int 分量（rod/cast_ok 抛竿时缓存）——浮标归属标签的钥匙：
#   1.21.6 浮标存档无 Owner 字段，归属只能抛竿时主动打标；watch（收杆检测）与
#   api/rod_reel（外部强收）都靠 @s dc.rod_uid 免读实体 NBT。
scoreboard objectives add dc.rod_uid dummy
# dc.rod_catch：成功钩取（钓上物品 / 拉回实体）次数，由进度 doom.consumable:fishing_rod 记账
scoreboard objectives add dc.rod_catch dummy
# 锁定鱼竿续期用的冷却秒数（rod/lock）：>=1 生效；改这个分数即可调整"用不了"的灰条时长
scoreboard players set #rod_lock dc.cfg 10
# ---- 弓/弩/三叉戟射击事件（2026-09-30 弓扩展）----
# stat 差分事件源：引擎只在投射物真的射出时 +1（空射/拉不满不涨），与 rod 链同构。
# dc.shot_prev_* 不在 __load__ 建哨兵：shot/tick_one 惰性初始化（首见玩家同步 prev = 当前 stat，
# 消历史积累防假事件）—— 这是 rod 链 B10 教训的根治版（__load__ as @a 管不到 reload 后加入的玩家）。
scoreboard objectives add dc.shot_use_bow minecraft.used:minecraft.bow
scoreboard objectives add dc.shot_use_crossbow minecraft.used:minecraft.crossbow
scoreboard objectives add dc.shot_use_trident minecraft.used:minecraft.trident
# prev objective 必须建（objective 不存在 = 命令直接失败）；**分数**留给 tick_one 惰性初始化
scoreboard objectives add dc.shot_prev_bow dummy
scoreboard objectives add dc.shot_prev_crossbow dummy
scoreboard objectives add dc.shot_prev_trident dummy
# ---- 投掷物消耗链（2026-10-05 P0-1）----
# ★ 关键实证（推翻了"原版没有 used:snowball"的前置判断）：
#   `scoreboard objectives add probe.snow minecraft.used:minecraft.snowball` **成功创建**
#   ⇒ 该准则**存在**；假玩家持雪球连按 5 次 ⇒ 计分板 5、背包 16→11（**真的计数**）；
#   对照组 stick 连按 3 次 ⇒ 0（证明是"投掷语义专属"，不是泛化右键计数）。
#   ⇒ 投掷物可以直接复刻 shot 链的 stat 差分结构，**不需要**实体检测 / 进度变体 /
#     Ragecraft 式的 `@e[type=snowball]` 兜底（那是给"地图自己 summon 的弹幕"用的，问题不同）。
# 覆盖：雪球 / 鸡蛋 / 末影珍珠 / 经验瓶（四种原版投掷物，stat 均已实测存在）
scoreboard objectives add dc.throw_use_snowball minecraft.used:minecraft.snowball
scoreboard objectives add dc.throw_use_egg minecraft.used:minecraft.egg
scoreboard objectives add dc.throw_use_ender_pearl minecraft.used:minecraft.ender_pearl
scoreboard objectives add dc.throw_use_xp_bottle minecraft.used:minecraft.experience_bottle
scoreboard objectives add dc.throw_prev_snowball dummy
scoreboard objectives add dc.throw_prev_egg dummy
scoreboard objectives add dc.throw_prev_ender_pearl dummy
scoreboard objectives add dc.throw_prev_xp_bottle dummy
scoreboard players set @a dc.off_prev -1
scoreboard players set @a dc.restore_timer -1
scoreboard players set @a dc.consume_timer -1
execute unless data storage doom.consumable:data drop_callbacks run data modify storage doom.consumable:data drop_callbacks set value []
forceload add 0 0
advancement revoke @a only doom.consumable:inv_change
advancement revoke @a only doom.consumable:using
advancement revoke @a only doom.consumable:consume
advancement revoke @a only doom.consumable:item_used
execute as @a run function doom.library:api/open
execute as @a run data modify storage doom.library:ctx _.cache_key set value "inventory"
execute as @a run data modify storage doom.library:ctx _.cache_data set value {}
execute as @a run data modify storage doom.library:ctx _.cache_data.Inventory set from entity @s Inventory
execute as @a if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.mainhand set from entity @s SelectedItem
execute as @a if data entity @s equipment.offhand.components."minecraft:custom_data"."dc" run data modify storage doom.library:ctx _.cache_data.offhand set from entity @s equipment.offhand
execute as @a run function doom.library:api/cache with storage doom.library:ctx _
execute as @a run data remove storage doom.library:ctx _.cache_key
execute as @a run data remove storage doom.library:ctx _.cache_data
tellraw @a [{"text":"[dc] C1 8.5 — if function hand checks","color":"green"}]