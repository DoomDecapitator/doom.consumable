# doom.consumable:api/block_cd_status —— 打印 8 格内最近设备的 key / 秒数 / 剩余 tick / 已激活次数
execute unless entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8] run tellraw @s {"text":"[dc] 8 格内没有冷却设备","color":"gray"}
execute unless entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8] run return 0

execute store result score #blk_st dc.temp run time query gametime
scoreboard players set #blk_rd dc.temp 0
execute store result score #blk_rd dc.temp run data get entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest] data.dc.cd_ready
scoreboard players operation #blk_rd dc.temp -= #blk_st dc.temp
data remove storage doom.consumable:ctx blk
execute store result storage doom.consumable:ctx blk.left int 1 run scoreboard players get #blk_rd dc.temp
execute store result storage doom.consumable:ctx blk.sec int 1 run data get entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest] data.dc.cd_seconds
execute store result storage doom.consumable:ctx blk.count int 1 run data get entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest] data.dc.cd_count
data modify storage doom.consumable:ctx blk.key set from entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8,limit=1,sort=nearest] data.dc.cd_key
function doom.consumable:api/block_cd_status_print with storage doom.consumable:ctx blk
data remove storage doom.consumable:ctx blk
