# doom.consumable:shot/depleted_disable —— disable 耗尽：物品留手 + use_cooldown 长冷却（拉不了弓的灰条）
# shot_locked 字段标记状态（tick_one 闸门后由锁定维护续杯——同 rod/lock 模式）。
kill @e[type=item_display,tag=dc_shot_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_shot_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx shot.main run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx shot.main run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s equipment.offhand
data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:custom_data".dc.shot_locked set value 1b
data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:use_cooldown" set value {seconds:3600f}
execute if data storage doom.consumable:ctx shot.main run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx shot.main run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_shot_tmp,limit=1]
