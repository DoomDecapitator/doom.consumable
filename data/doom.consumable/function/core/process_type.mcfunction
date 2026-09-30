# doom.consumable:core/process_type
execute if data storage doom.consumable:ctx task_data.hand{hand:"mainhand"} run data modify storage doom.consumable:ctx task_data.slot_path set value "weapon.mainhand"
execute if data storage doom.consumable:ctx task_data.hand{hand:"offhand"} run data modify storage doom.consumable:ctx task_data.slot_path set value "weapon.offhand"
# 落点/id 必须在派发**之前**定死：schedule/* 只负责把它们抄进 CACHE
execute if data storage doom.consumable:ctx task_data.hand run function doom.consumable:core/finalize_slot
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"limited"} run function doom.consumable:schedule/limited with storage doom.consumable:ctx task_data
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"infinite"} run function doom.consumable:schedule/infinite with storage doom.consumable:ctx task_data
data remove storage doom.consumable:ctx task_data