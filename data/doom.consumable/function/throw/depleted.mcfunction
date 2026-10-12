# doom.consumable:throw/depleted —— 耗尽分派：vanish（默认）/ disable / normal
# 与 shot/depleted 同构；注意投掷物**扔出后原版就把它从手里拿走了**（count 减 1，最后一颗直接消失），
# 所以 vanish 分支这里的 `item replace … with air` 在真机上多数情况是**幂等的空操作**
# —— 但保留它：当 count>1 时手上还剩着那一叠，必须清掉（与 shot 的语义保持一致）。
execute if data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{depleted:"disable"} run function doom.consumable:throw/depleted_disable
execute if data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{depleted:"normal"} run function doom.consumable:throw/depleted_normal
execute unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{depleted:"disable"} unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{depleted:"normal"} if data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.mainhand with air
execute unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{depleted:"disable"} unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{depleted:"normal"} unless data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.offhand with air
