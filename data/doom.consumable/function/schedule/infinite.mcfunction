# doom.consumable:schedule/infinite — save restore_data to CACHE.consumable
function doom.library:api/open
data modify storage doom.library:ctx _.cache_key set value "consumable"
data modify storage doom.library:ctx _.cache_data set value {}
data modify storage doom.library:ctx _.cache_data.item set from storage doom.consumable:ctx task_data.item
data modify storage doom.library:ctx _.cache_data.slot_path set from storage doom.consumable:ctx task_data.slot_path
# 2026-09-27：恢复落点（可为 hotbar.N）与物品 id 一起进缓存 —— 恢复链靠它们做"占用就不覆盖"的判定
execute if data storage doom.consumable:ctx task_data.slot_cmd run data modify storage doom.library:ctx _.cache_data.slot_cmd set from storage doom.consumable:ctx task_data.slot_cmd
execute if data storage doom.consumable:ctx task_data.id run data modify storage doom.library:ctx _.cache_data.id set from storage doom.consumable:ctx task_data.id
data modify storage doom.library:ctx _.cache_data.args set value {}
# ⚠ 2026-09-20 加固：infinite 类物品**本来就没有 current_uses**（三个现成 fixture 全都没有），
#   而原来这行是无条件 `set from` —— 取不到源可能中止整个函数，
#   那样缓存写不进、restore_timer 也设不上，物品用掉就再也回不来。
#   现在先给默认值 1，读得到才覆盖。do_restore 那边读 args.uses 也就永远有值了。
data modify storage doom.library:ctx _.cache_data.args.uses set value 1
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".current_uses run data modify storage doom.library:ctx _.cache_data.args.uses set from storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".current_uses
data modify storage doom.library:ctx _.cache_data.args.damage set value 0
# 2026-09-20：「伪耐久条」物品可以在用完时把条清空（而不是保持满格），
#   由物品自己声明 dc.on_use_damage（缺省 0 = 老行为，完全向后兼容）。
#   典型用途见 items/recover_heart：用完 ⇒ damage=10（空条）+ 5 秒冷却，
#   再由 recover/* 每 10 tick 涨回一格。
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".on_use_damage run data modify storage doom.library:ctx _.cache_data.args.damage set from storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc".on_use_damage
function doom.library:api/cache with storage doom.library:ctx _
data remove storage doom.library:ctx _.cache_key
data remove storage doom.library:ctx _.cache_data
scoreboard players set @s dc.restore_timer 1