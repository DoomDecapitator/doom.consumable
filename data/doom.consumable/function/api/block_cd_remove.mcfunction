# doom.consumable:api/block_cd_remove —— 移除 8 格内最近的冷却设备
#   （若设备声明了 cd_block_ready，会先把方块换回就绪形态再删，避免留下一个"冷却中"的外观）
execute at @s as @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest] at @s run function doom.consumable:block/force_ready
execute at @s run kill @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest]
tellraw @s {"text":"[dc] 已移除最近的冷却设备（方块已换回就绪形态）","color":"gray"}
