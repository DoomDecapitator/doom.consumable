# doom.consumable:shot/depleted_normal —— normal 耗尽：摘 dc 与伪耐久组件，恢复为普通弓（原版耐久回归）
kill @e[type=item_display,tag=dc_shot_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_shot_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx shot.main run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx shot.main run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s equipment.offhand
data remove entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:custom_data".dc
data remove entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:max_damage"
data remove entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:unbreakable"
data remove entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:damage"
execute if data storage doom.consumable:ctx shot.main run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx shot.main run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_shot_tmp,limit=1]
