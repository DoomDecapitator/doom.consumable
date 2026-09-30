# doom.consumable:rod/tick —— 鱼竿右键接口：每刻驱动（由 tick/tick 调用）
#
# 三条互相补位的路线（2026-09-30 B1 重构）：
#   ① 统计事件：记分板 dc.rod_use（准则 minecraft.used:minecraft.fishing_rod）
#      **仅抛竿** +1（引擎源码实锤：awardStat 只在 FishingRodItem.use 抛竿分支）
#      ⇒ 与 @s dc.rod_prev 求差 = "本刻抛了一次竿"（1 tick 精度），只路由 rod/cast
#   ② 状态机：@s dc.rod_state = 0 未抛竿 / 1 正在钓鱼
#      抛竿置 1（cast_ok）；**收杆 = watch_impl 的浮标死亡监听**（自己的浮标没了 + 还持杆）
#   ③ 鱼漂实体：@e[type=minecraft:fishing_bobber] 是客观事实
#      · 本文件末尾给所有鱼漂打 tag dc_rod_seen
#      · "没有 dc_rod_seen 的鱼漂"= 本刻刚抛出来的 ⇒ bind_impl 给它打归属标签
#        dc_rod_own_<uid>（uid = 抛竿玩家 UUID[0]；1.21.6 浮标存档无 Owner 字段，归属只能这样建）
#      · 浮标死亡（收杆/断线/外力）⇒ watch_impl 按玩家是否还持杆分流：真收杆（回调）/自愈（静默）
#
# ⚠ 与 recover/tick 同一纪律：逐玩家体必须"一个玩家一口气跑完"（共享临时 storage + 宏参数），
#   所以这里只有一条 `as @a … run function rod/tick_one`，不要再拆成两行。
#
# 开销：早退闸门在 rod/tick_one 里 —— 身上没有 dc{rod:1b} 的玩家不读统计、不进状态机。

# （旧版的全局自愈已删：它跑在逐玩家体**之前**，"世界无鱼漂 ⇒ 全部 state=0"会把最后一个
#   收杆玩家的 on_rod_reel 回调吃掉（state 先被清 0，watch 永远看不到）。per-player 的
#   watch_impl 已完全取代它：收杆（还持杆）⇒ reel 回调；外力（不持杆）⇒ 静默归零。）

# ② 逐玩家：读数 → 事件 → 状态机（含锁定维护 + 收杆监听）
execute as @a at @s run function doom.consumable:rod/tick_one

# ③ 本刻鱼漂打标（必须在最后：bind_impl 靠 tag=!dc_rod_seen 认"本刻新抛"）
tag @e[type=minecraft:fishing_bobber] add dc_rod_seen
