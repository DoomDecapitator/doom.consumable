# doom.consumable:throw/depleted_disable —— disable 耗尽：物品留手 + use_cooldown 长冷却
# 与 shot 同款：写 dc.throw_locked 标记 + 挂 1 小时冷却（原版层面扔不动 + 灰条反馈）。
# ⚠ 投掷物的特殊点：原版扔出后手里那份 count 已经减 1；最后一颗扔出时手里**是空的**，
#   此时 `data modify … set from entity @s SelectedItem` 会读到空/旧值。
#   ⇒ 所以必须先判「手上还有那件 dc 物品」才做中转，否则会凭空造出一颗投掷物（复制 bug）。
execute unless data storage doom.consumable:ctx throw.item.components."minecraft:custom_data".dc{detect:"throw"} run return 0
kill @e[type=item_display,tag=dc_throw_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_throw_tmp"],item:{id:"minecraft:stone",count:1}}
execute if data storage doom.consumable:ctx throw{main:1b} run data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx throw{main:1b} run data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item set from entity @s equipment.offhand
data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:custom_data".dc.throw_locked set value 1b
data modify entity @e[type=item_display,tag=dc_throw_tmp,limit=1] item.components."minecraft:use_cooldown" set value {seconds:3600f}
execute if data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_throw_tmp,limit=1] contents
execute unless data storage doom.consumable:ctx throw{main:1b} run item replace entity @s weapon.offhand from entity @e[type=item_display,tag=dc_throw_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_throw_tmp,limit=1]
