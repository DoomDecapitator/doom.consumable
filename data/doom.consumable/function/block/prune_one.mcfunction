# doom.consumable:block/prune_one —— 单台自动设备的闲置判定（占用 #blk_rd / #blk_age）
scoreboard players set #blk_rd dc.temp 0
execute store result score #blk_rd dc.temp run data get entity @s data.dc.cd_ready
execute if score #blk_rd dc.temp matches ..0 run kill @s
scoreboard players set #blk_age dc.temp 0
execute store result score #blk_age dc.temp run time query gametime
scoreboard players operation #blk_age dc.temp -= #blk_rd dc.temp
execute if score #blk_age dc.temp matches 600.. run kill @s
