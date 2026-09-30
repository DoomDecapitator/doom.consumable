# doom.consumable:block/place_mark —— 命中那一格：没有设备就建一台（有就保持原样，不动别人的设备）
scoreboard players set #pl_hit dc.temp 1
execute unless entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1] run function doom.consumable:block/place_make with storage doom.consumable:ctx plc
