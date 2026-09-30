# doom.consumable:api/block_cd_debug —— 调试：给 16 格内每台设备打状态粒子，并打印就绪/冷却数量
#
# 用法：站在设备附近执行（as 玩家）。绿粒子=就绪，红粒子=冷却中。
execute unless entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..16] run tellraw @s {"text":"[dc] 16 格内没有冷却设备","color":"gray"}
execute unless entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..16] run return 0
scoreboard players set #blk_ready dc.temp 0
scoreboard players set #blk_cool dc.temp 0
execute as @e[type=minecraft:marker,tag=dc.block_cd,distance=..16] at @s run function doom.consumable:block/debug_one
execute store result storage doom.consumable:ctx blk.ready int 1 run scoreboard players get #blk_ready dc.temp
execute store result storage doom.consumable:ctx blk.cool int 1 run scoreboard players get #blk_cool dc.temp
function doom.consumable:block/debug_print with storage doom.consumable:ctx blk
execute as @e[type=minecraft:marker,tag=dc.block_cd,distance=..16] at @s run function doom.consumable:api/block_cd_status
