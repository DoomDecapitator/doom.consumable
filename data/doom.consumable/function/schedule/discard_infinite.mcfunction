# doom.consumable:schedule/discard_infinite
# @s = item entity (Age:0s/1s, discardable), at item position

# Save item data from entity before switching context
data modify storage doom.consumable:ctx drop_item set from entity @s Item

# 1. Check if origin exists (the dropper)
scoreboard players set #found dc.temp 0
execute on origin run scoreboard players set #found dc.temp 1
execute unless score #found dc.temp matches 1 run kill @s
execute unless score #found dc.temp matches 1 run data remove storage doom.consumable:ctx drop_item
execute unless score #found dc.temp matches 1 run return 0

# 2. Check cooldown
scoreboard players set #cooldown_active dc.temp 0
execute on origin if score @s dc.discard_timer matches 1.. run scoreboard players set #cooldown_active dc.temp 1

# 3. Cooldown: bounce item back to player instead of consuming
# FIXED (C): 不再用全局 dc_bounce tag + tp（多玩家同时丢弃会 tp 错物品）
#   PickupDelay=0 后玩家在附近自动捡回（原版 40t 保护被移除）
execute if score #cooldown_active dc.temp matches 1 on origin run tellraw @s [{"text":"[dc] This item is on cooldown!","color":"red"}]
execute if score #cooldown_active dc.temp matches 1 run data modify entity @s PickupDelay set value 0s
# F6：打标记，避免下一 tick 的 Age:1s 那趟再处理一次（会重复提示 on cooldown）
execute if score #cooldown_active dc.temp matches 1 run tag @s add dc_bounced
execute if score #cooldown_active dc.temp matches 1 run data remove storage doom.consumable:ctx drop_item
execute if score #cooldown_active dc.temp matches 1 run return 0

# 4. Save data and schedule restore
execute on origin run function doom.consumable:schedule/discard_infinite_save

# 5. Vanish the dropped item
particle minecraft:cloud ~ ~0.5 ~ 0.1 0.1 0.1 0.1 10
data remove storage doom.consumable:ctx drop_item
kill @s
