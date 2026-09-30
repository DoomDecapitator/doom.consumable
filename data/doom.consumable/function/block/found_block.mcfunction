# doom.consumable:block/found_block —— 找到了被交互的方块（执行位置已 align 到该方块）：决定用哪台设备
#
# ① 该方块上已有显式设备（api/block_cd_place / 手工 summon）⇒ 直接用；
# ② 否则按**方块类型**查配置（storage doom.consumable:block_cd.entries，按方块标签匹配）——
#    命中就**惰性建一台自动设备**记在这个位置（这就是「方块版 use_cooldown」：
#    作者只声明「标签 + 秒数」，不需要逐块装设备）；
# ③ 都没有 ⇒ 本次交互不管（零副作用）。
scoreboard players set #blk_hit dc.temp 1
scoreboard players set #dev_ready dc.temp 0
execute if entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..1] run scoreboard players set #dev_ready dc.temp 1
execute if score #dev_ready dc.temp matches 0 run scoreboard players set #cfg_hit dc.temp 0
execute if score #dev_ready dc.temp matches 0 run function doom.consumable:block/cfg_lookup
execute if score #dev_ready dc.temp matches 0 if score #cfg_hit dc.temp matches 1 run function doom.consumable:block/dev_create with storage doom.consumable:ctx dev
execute if score #dev_ready dc.temp matches 0 if score #cfg_hit dc.temp matches 1 run scoreboard players set #dev_ready dc.temp 1
execute if score #dev_ready dc.temp matches 1 run function doom.consumable:block/hit
