# 探针：0 耐久下，block_interaction_range 归零修饰符的「加 / 加后删 / 不加」三格对照
# 用法：/function doom.consumable:test/probe_reach_zero
#
# 三个格子**都是 0 耐久**（damage = 5 = max_damage），唯一变量是 attribute_modifiers：
#   1  加了又删掉  → 预期**能放**（验证"删 key 能真正解除"—— 组件是对原型的补丁，删掉就回默认）
#   2  加了不删    → 预期**不能放**（复现上一轮，并把结论从 damage:0 扩展到 0 耐久）
#   3  不加        → 预期**能放**（对照：0 耐久本身不限制放置，上一轮已验过，这里再钉一次）
#
# 判读：
#   1 能放 + 2 不能放 + 3 能放 → 这条杠杆**干净且可逆**，可以正式用进 disable 分支
#   1 不能放                  → 删 key 没解除（可能被原型默认值接管）→ 得改用 `!` 前缀写法
#
# 为什么要专门验"加后删"：consumable 那次教训 —— 苹果的 consumable 来自**物品原型**，
# patch 里本来就没有这个键，`data remove` 一条不存在的路径什么也不做，默认值照旧生效。
# `attribute_modifiers` 对荧石**不是原型默认组件**，所以预期删掉就没了 —— 但这必须实测，不能想当然。
# 注：三个格子都带 dc.detect=place，拿着它们乱放会正常扣次数（这是预期行为）。

# ---------- 1：加了 attribute_modifiers 又删掉 ----------
kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_damage":5,"minecraft:damage":5,"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:0,depleted:"disable"}}}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers" set value [{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}]
data remove entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers"
item replace entity @s hotbar.0 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

# ---------- 2：加了不删 ----------
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_damage":5,"minecraft:damage":5,"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:0,depleted:"disable"}}}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers" set value [{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}]
item replace entity @s hotbar.1 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

# ---------- 3：不加（对照）----------
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_damage":5,"minecraft:damage":5,"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:0,depleted:"disable"}}}}
item replace entity @s hotbar.2 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

tellraw @s [{"text":"三格全是 0 耐久，唯一差别是 attribute_modifiers：","color":"gold"}]
tellraw @s [{"text":"  1 = 加了又删掉   2 = 加了不删   3 = 不加（对照）","color":"gold"}]
tellraw @s [{"text":"各拿在手上右键：预期 1 能放 / 2 不能放 / 3 能放","color":"yellow"}]
