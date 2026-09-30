# doom.consumable:core/watch_offhand —— 副手看门狗（静默，专抓"幽灵/复制"）
#
# 背景：2026-09-26 玩家两次报"副手凭空多出一件"（一次在快手指南修复之后），
#   但复现是间歇性的 —— 靠肉眼看不见它哪一刻冒出来。
# 做法：每 tick 比较副手的数量，一旦**增加**就记下游戏刻与累计次数。
#   出现幽灵后跑 probe_place_state，就能看到"哪一刻 + 几次"，
#   再对着那附近的 dc.placed_off / restore_timer 判断是不是恢复写错了手。
#
# 初值处理：load 时把 dc.off_prev 置 -1 当哨兵，并要求"上一刻 ≥ 0"才比较 ——
#   否则刚装包的第一 tick（0 > -1）会记一次假事件。
execute store result score #off_now dc.temp run data get entity @s equipment.offhand.count
execute if score @s dc.off_prev matches 0.. if score #off_now dc.temp > @s dc.off_prev run scoreboard players add @s dc.off_spike_n 1
execute if score @s dc.off_prev matches 0.. if score #off_now dc.temp > @s dc.off_prev store result score @s dc.off_spike run time query gametime
scoreboard players operation @s dc.off_prev = #off_now dc.temp
