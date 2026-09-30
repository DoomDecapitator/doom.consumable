# doom.consumable:api/block_cd_reset —— 让 8 格内最近的设备立刻冷却完毕（cd_ready 归 0）
execute at @s run data modify entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest] data.dc.cd_ready set value 0
tellraw @s {"text":"[dc] 最近的冷却设备已立即就绪","color":"gray"}
