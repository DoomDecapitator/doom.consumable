# doom.consumable:schedule/discard_infinite_save
# @s = player (the dropper)
# Reads from storage doom.consumable:ctx drop_item (pre-saved from item entity)
# Saves to per-player CACHE, sets cooldown timer, calls on_drop callbacks
# Determines original slot (mainhand/offhand) for prioritized restore

# Read cooldown duration
scoreboard players set #cooldown dc.temp 60
execute if data storage doom.consumable:ctx drop_item.components."minecraft:custom_data"."dc".discard_cooldown run execute store result score #cooldown dc.temp run data get storage doom.consumable:ctx drop_item.components."minecraft:custom_data"."dc".discard_cooldown

# Save to per-player CACHE
function doom.library:api/open
data modify storage doom.library:ctx _.cache_key set value "discard"
data modify storage doom.library:ctx _.cache_data set value {}
data modify storage doom.library:ctx _.cache_data.item set from storage doom.consumable:ctx drop_item
data modify storage doom.library:ctx _.cache_data.item.count set value 1

# Determine original slot: check SelectedItem vs offhand
# FIXED (D): 丢弃最后一个物品后 SelectedItem 已清空 → 无法用 if data 判断
#   Q 默认丢主手 → 默认 mainhand；仅当主手完全无物品且副手有 discardable 才判 offhand
data modify storage doom.library:ctx _.cache_data.slot_path set value "weapon.mainhand"
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{discardable:1b} run data modify storage doom.library:ctx _.cache_data.slot_path set value "weapon.mainhand"
execute unless data entity @s SelectedItem if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{discardable:1b} run data modify storage doom.library:ctx _.cache_data.slot_path set value "weapon.offhand"

# 2026-09-27：恢复落点（slot_cmd，可精确到 hotbar.N）与物品 id —— 与吃/放两条链同构。
#   见 core/finalize_slot 与 restore/guard：这两项是"绝不覆盖别人槽位"的判定依据。
execute if data storage doom.library:ctx _.cache_data.item.id run data modify storage doom.library:ctx _.cache_data.id set from storage doom.library:ctx _.cache_data.item.id
data modify storage doom.library:ctx _.cache_data.slot_cmd set from storage doom.library:ctx _.cache_data.slot_path
data remove storage doom.consumable:ctx sel
execute if data entity @s SelectedItemSlot if data storage doom.library:ctx _.cache_data{slot_path:"weapon.mainhand"} store result storage doom.consumable:ctx sel.n int 1 run data get entity @s SelectedItemSlot
execute if data storage doom.consumable:ctx sel.n run function doom.consumable:core/sel_slot_cmd with storage doom.consumable:ctx sel
execute if data storage doom.library:ctx _.cache_data{slot_path:"weapon.mainhand"} if data storage doom.consumable:ctx sel.cmd run data modify storage doom.library:ctx _.cache_data.slot_cmd set from storage doom.consumable:ctx sel.cmd
data remove storage doom.consumable:ctx sel

function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data

# Set cooldown timer
scoreboard players set @s dc.discard_timer 0
scoreboard players operation @s dc.discard_timer = #cooldown dc.temp

# Call on_drop callbacks
function #doom.consumable:on_drop
execute if data storage doom.consumable:data drop_callbacks[0] run function doom.consumable:api/run_drop_callbacks

advancement revoke @s only doom.consumable:inv_change
