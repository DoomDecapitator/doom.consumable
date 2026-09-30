# doom.consumable:shot/depleted —— 耗尽分派：vanish（默认）/ disable / normal
# 显式 disable / normal 命中则走专门处理；否则一律 vanish（与 consumable 家族默认一致）。
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"disable"} run function doom.consumable:shot/depleted_disable
execute if data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"normal"} run function doom.consumable:shot/depleted_normal
execute unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"disable"} unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"normal"} if data storage doom.consumable:ctx shot.main run item replace entity @s weapon.mainhand with air
execute unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"disable"} unless data storage doom.consumable:ctx shot.item.components."minecraft:custom_data".dc{depleted:"normal"} unless data storage doom.consumable:ctx shot.main run item replace entity @s weapon.offhand with air
