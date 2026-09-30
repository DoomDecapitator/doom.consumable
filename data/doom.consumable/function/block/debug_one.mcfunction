# doom.consumable:block/debug_one —— 单台设备：按状态打粒子（绿=就绪 / 红=冷却中）并计数
# 调用：execute as <设备> at @s run function doom.consumable:block/debug_one
scoreboard players set #blk_rd dc.temp 0
execute store result score #blk_rd dc.temp run data get entity @s data.dc.cd_ready
execute store result score #blk_now dc.temp run time query gametime
execute if score #blk_rd dc.temp matches 1.. if score #blk_now dc.temp < #blk_rd dc.temp run particle minecraft:dust{color:[1.0,0.25,0.25],scale:1.2} ~ ~0.7 ~ 0.35 0.2 0.35 0 8
execute if score #blk_rd dc.temp matches 1.. if score #blk_now dc.temp < #blk_rd dc.temp run scoreboard players add #blk_cool dc.temp 1
execute unless score #blk_rd dc.temp matches 1.. run particle minecraft:happy_villager ~ ~0.7 ~ 0.35 0.2 0.35 0 8
execute unless score #blk_rd dc.temp matches 1.. run scoreboard players add #blk_ready dc.temp 1
execute if score #blk_rd dc.temp matches 1.. if score #blk_now dc.temp >= #blk_rd dc.temp run particle minecraft:happy_villager ~ ~0.7 ~ 0.35 0.2 0.35 0 8
execute if score #blk_rd dc.temp matches 1.. if score #blk_now dc.temp >= #blk_rd dc.temp run scoreboard players add #blk_ready dc.temp 1
