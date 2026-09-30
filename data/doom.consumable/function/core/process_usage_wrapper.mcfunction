# doom.consumable:core/process_usage_wrapper
function doom.library:api/open
data remove storage doom.consumable:ctx task_data
# ---------- 快照新鲜度（2026-10-01 修复）----------
# 快照必须来自刚刚（≤2 tick）。缺时间戳=接受（向后兼容旧缓存/测试夹具）。
# 超过窗口 ⇒ 这是"上一次没消耗掉"的旧快照，直接放弃本次处理（宁可漏记，也不张冠李戴）。
#   正常链路：using_item 每 tick 刷新快照 ⇒ 消耗后处理时 age ∈ {0,1,2}。
scoreboard players set #stamp dc.temp 0
execute store result score #stamp dc.temp run data get storage doom.library:io output[-1].data.CACHE.usage.data.time
scoreboard players set #age dc.temp 0
execute store result score #age dc.temp run time query gametime
scoreboard players operation #age dc.temp -= #stamp dc.temp
execute if score #stamp dc.temp matches 1.. if score #age dc.temp matches 3.. run return 0
scoreboard players set #snap_main dc.temp 0
scoreboard players set #now_main dc.temp 0
scoreboard players set #main_diff dc.temp 0
scoreboard players set #snap_off dc.temp 0
scoreboard players set #now_off dc.temp 0
scoreboard players set #off_diff dc.temp 0
execute store result score #snap_main dc.temp run data get storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.count
execute store result score #now_main dc.temp run data get entity @s SelectedItem.count
scoreboard players operation #main_diff dc.temp = #snap_main dc.temp
scoreboard players operation #main_diff dc.temp -= #now_main dc.temp
execute store result score #snap_off dc.temp run data get storage doom.library:io output[-1].data.CACHE.usage.data.off_snap.count
execute store result score #now_off dc.temp run data get entity @s equipment.offhand.count
scoreboard players operation #off_diff dc.temp = #snap_off dc.temp
scoreboard players operation #off_diff dc.temp -= #now_off dc.temp
execute if score #main_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc"{detect:"consume"} run data modify storage doom.consumable:ctx task_data.item set from storage doom.library:io output[-1].data.CACHE.usage.data.main_snap
execute if score #main_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc"{detect:"consume"} run data modify storage doom.consumable:ctx task_data.hand set value {hand:"mainhand"}
execute unless data storage doom.consumable:ctx task_data.hand if score #off_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.usage.data.off_snap.components."minecraft:custom_data"."dc"{detect:"consume"} run data modify storage doom.consumable:ctx task_data.item set from storage doom.library:io output[-1].data.CACHE.usage.data.off_snap
execute unless data storage doom.consumable:ctx task_data.hand if score #off_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.usage.data.off_snap.components."minecraft:custom_data"."dc"{detect:"consume"} run data modify storage doom.consumable:ctx task_data.hand set value {hand:"offhand"}
# 2026-09-27：把"用它的那一刻选中的热键槽"一并带进 task_data（恢复落点要精确到 hotbar.N）
execute if data storage doom.consumable:ctx task_data{hand:"mainhand"} if data storage doom.library:io output[-1].data.CACHE.usage.data.sel run data modify storage doom.consumable:ctx task_data.sel set from storage doom.library:io output[-1].data.CACHE.usage.data.sel
execute if data storage doom.consumable:ctx task_data.hand run function doom.consumable:core/process_type with storage doom.consumable:ctx
data modify storage doom.library:ctx _.cache_key set value "usage"
data modify storage doom.library:ctx _.cache_data set value {}
function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data