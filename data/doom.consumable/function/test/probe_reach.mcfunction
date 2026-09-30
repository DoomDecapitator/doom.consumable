# 探针：用 attribute_modifiers 把「方块交互距离」归零，能不能挡住放置
# 用法：/function doom.consumable:test/probe_reach
#
# 背景（2026-09-20 实测）：
#   0 耐久（damage == max_damage，"已破损"）的方块物品**照样能放** ——
#   物品侧没有任何"禁止放置"的组件：放置走的是**方块交互**，
#   受玩家属性 `block_interaction_range` 控制（物品只是交互的载体）。
#   所以唯一可能的物品侧杠杆是 attribute_modifiers：**持有期间**改这个属性。
#
# 快捷栏第 1 格：挂了「持有即把 block_interaction_range 减 10」的荧石（外观正常、damage 0）
# 快捷栏第 2 格：普通荧石 —— 对照，证明"放不下去"不是因为别的原因
#
# 判读：
#   1 放不下去、2 能放 → 这条杠杆有效。代价：**拿着它期间连箱子/按钮/挖方块都够不到**（reach 是全局的）
#   1 也能放           → 属性名/写法不对，或放置不查这个属性 → 此路不通
#
# 顺带请试两件事（决定代价能不能接受）：
#   · 拿着第 1 格去开箱子 / 按按钮 → 如果也没反应，说明它把"所有方块交互"都禁了
#   · 拿着第 1 格去挖方块         → 同上

kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_stack_size":1,"minecraft:attribute_modifiers":[{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}],"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:5}}}}
item replace entity @s hotbar.0 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:5}}}}
item replace entity @s hotbar.1 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

tellraw @s [{"text":"快捷栏 1 = 持有即归零方块交互距离 ｜ 2 = 普通荧石（对照）","color":"gold"}]
tellraw @s [{"text":"各拿在手上对地面右键；再用第 1 格试开箱子 / 挖方块，看代价多大","color":"yellow"}]
