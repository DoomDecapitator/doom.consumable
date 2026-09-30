# doom.consumable:shot/writeback [MACRO] —— 扣次写回（item_display 中转体三步）
# 参数源：doom.consumable:ctx shot（需要 uses / dmg / main 全部就位 —— process_one 连续行保证）
# 为什么走中转体：1.21.6 data modify entity <玩家> 全被拒 + item replace 无 from storage ⇒ 唯一通路。
kill @e[type=item_display,tag=dc_shot_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_shot_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx shot.main run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx shot.main run data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item set from entity @s equipment.offhand
$data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:custom_data".dc.current_uses set value $(uses)
$data modify entity @e[type=item_display,tag=dc_shot_tmp,limit=1] item.components."minecraft:damage" set value $(dmg)
execute if data storage doom.consumable:ctx shot.main run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx shot.main run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_shot_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_shot_tmp,limit=1]
