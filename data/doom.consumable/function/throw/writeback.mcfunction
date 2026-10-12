# doom.consumable:throw/writeback [MACRO] —— 扣次写回（item_display 中转体三步）
# 参数源：doom.consumable:ctx throw（需要 uses / dmg / main 全部就位 —— process_one 连续行保证）
# 为什么走中转体：与 shot/writeback 同因（玩家背包不能用 data modify 写；且这里的值是运行时算出来的，
#   宏参数只能进命令字符串，进不了 item NBT ⇒ 不能像连发弹匣那样用 item modify 绕开）。
#
# ⚠ 主/副手用**值判定** doom.consumable:ctx throw{main:1b}，不是存在性判定（见 process_one 头部说明）。
kill @e[type=item_display,tag=dc_throw_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_throw_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx throw{main:1b} run data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx throw{main:1b} run data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item set from entity @s equipment.offhand
$data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:custom_data".dc.current_uses set value $(uses)
$data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:damage" set value $(dmg)
execute if data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_throw_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_throw_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_throw_tmp,limit=1]
