# 探针（全自动）：0 耐久下 block_interaction_range 修饰符的三格对照 —— 边摆边读
# 用法：/function doom.consumable:test/probe_reach_full
#
# 为什么要有这一版：上一版要玩家自己切换快捷栏，结果**物品已经被放掉了**、
# 手上是空的，三行读数对物品只字未提（见 probe_reach_diag 的日志）。
# 这一版由命令自己把物品塞进**当前手持格**再读数 —— 不依赖玩家切格子、不依赖玩家报告。
#
# 三个变体（**全部 0 耐久**，唯一变量是 attribute_modifiers）：
#   A 加了又删   → 期望：物品上无修饰符、属性 4500
#   B 加了不删   → 期望：物品上有修饰符、属性被压低（0 或负）
#   C 不加       → 期望：物品上无修饰符、属性 4500
#
# 判读（关键就在 B）：
#   B 的 attribute_modifiers 为空        → 修饰符根本没挂上（写 SNBT 出错）
#   B 有修饰符但属性仍 4500              → 修饰符在物品上却不生效 ⇒ 0 耐久那条路要单独查
#   B 有修饰符且属性被压低               → 修饰符生效 ⇒ "三个都能放"必须另找解释（当时手上拿的可能不是它）
#
# 命令结束后会把 A/B/C 重新铺到快捷栏 0/1/2，供你手动试放置。
# ⚠ 会覆盖你当前手持格和快捷栏前三格。

# 基准物品（0 耐久 + 已禁用状态）
data modify storage doom.consumable:ctx probe_item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_damage":5,"minecraft:damage":5,"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{detect:"place",type:"limited",max_uses:5,current_uses:0,depleted:"disable"}}}}

tellraw @s [{"text":"===== [R2] 边摆边读 =====","color":"gold"}]

# ---------- A：加了又删 ----------
kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers" set value [{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}]
data remove entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers"
item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]
tellraw @s [{"text":"--- A：0 耐久 + 加了又删 ---","color":"aqua"}]
function doom.consumable:test/_reach_diag

# ---------- B：加了不删 ----------
kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers" set value [{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}]
item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]
tellraw @s [{"text":"--- B：0 耐久 + 加了不删（关键格）---","color":"aqua"}]
function doom.consumable:test/_reach_diag

# ---------- C：不加（对照）----------
kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
item replace entity @s weapon.mainhand from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]
tellraw @s [{"text":"--- C：0 耐久 + 不加（对照）---","color":"aqua"}]
function doom.consumable:test/_reach_diag

# ---------- 铺回快捷栏，供手动试放置 ----------
kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
item replace entity @s hotbar.0 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item.components."minecraft:attribute_modifiers" set value [{type:"minecraft:block_interaction_range",id:"dc:no_reach",amount:-10.0,operation:"add_value",slot:"mainhand"}]
item replace entity @s hotbar.1 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set from storage doom.consumable:ctx probe_item
item replace entity @s hotbar.2 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

tellraw @s [{"text":"快捷栏铺好了：0 = A(加了又删)  1 = B(加了不删)  2 = C(不加)","color":"gold"}]
tellraw @s [{"text":"把第 1 格拿在手上，先跑一次 /function doom.consumable:test/probe_reach_diag（拿在手上才量得准），再右键试放置","color":"yellow"}]
