# doom.consumable:block/tick_restore —— 每 5 tick 扫一遍设备，把到期的「冷却态」换回「就绪态」
#
# 为什么需要轮询：冷却到期是"时间到了"，不是"有人交互"；没有这一步，冷却态方块会一直留在原地。
# 成本：每 5 tick 一次实体循环（设备数量级是个位数，可忽略）。
scoreboard players add #blk_gate dc.temp 1
execute if score #blk_gate dc.temp matches 5.. run scoreboard players set #blk_gate dc.temp 0
execute if score #blk_gate dc.temp matches 0 run execute as @e[type=minecraft:marker,tag=dc.block_cd] at @s run function doom.consumable:block/restore_ready
# 顺便清理长期闲置的自动设备（显式设备不受影响）
execute if score #blk_gate dc.temp matches 0 run function doom.consumable:block/prune
