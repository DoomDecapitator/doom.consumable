# doom.consumable:throw/depleted_normal —— normal 耗尽：摘 dc 与伪耐久组件，恢复为普通投掷物
# 与 shot 同构。同 depleted_disable：先守卫"手上还有那件 dc 物品"，避免凭空造物。
execute unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{detect:"throw"} run return 0
kill @e[type=item_display,tag=dc_throw_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_throw_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx throw{main:1b} run data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx throw{main:1b} run data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item set from entity @s equipment.offhand
data remove entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:custom_data".dc
data remove entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:max_damage"
data remove entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:unbreakable"
data remove entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:damage"
execute if data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_throw_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_throw_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_throw_tmp,limit=1]
