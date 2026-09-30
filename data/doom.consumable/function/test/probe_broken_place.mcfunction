# 探针：0 耐久（damage == max_damage，"已破损"）的方块物品还能不能放置？
# 用法：/function doom.consumable:test/probe_broken_place
#
# 背景：doom.consumable 的 disable 模式，耗尽后物品会带着
#   damage = 5 = max_damage（0 耐久）+ 摘掉 detect 的状态回到手上。
#   摘 detect 只让**数据包**不再计数；能不能放，取决于原版对"破损物品"的态度 ——
#   这不是读代码能确定的，必须实测。
#
# 两个变体并排放进快捷栏，做**对照实验**（避免"能放"其实是别的原因造成的）：
#   第 1 格 A：damage = 5（= max_damage，已破损）← 就是 disable 耗尽后的真实状态
#   第 2 格 B：damage = 4（还剩 1 点耐久）      ← 对照组
#
# 判读：
#   A 放不下去、B 能放  → 破损状态正好挡住了放置 ⇒ place 类的 disable 事实上是完整的
#   A 也能放            → 放置是方块物品的固有行为，组件挡不住 ⇒ disable 只能是"数据包不再计数"

# ---------- A：0 耐久 ----------
kill @e[type=item_display,tag=dc_probe]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_damage":5,"minecraft:damage":5,"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{type:"limited",max_uses:5,current_uses:0,depleted:"disable"}}}}
item replace entity @s hotbar.0 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

# ---------- B：还剩 1 点耐久 ----------
summon minecraft:item_display ~ ~ ~ {Tags:["dc_probe"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_probe,limit=1] item set value {id:"minecraft:glowstone",count:1,components:{"minecraft:max_damage":5,"minecraft:damage":4,"minecraft:max_stack_size":1,"minecraft:custom_data":{dc:{type:"limited",max_uses:5,current_uses:1,depleted:"disable"}}}}
item replace entity @s hotbar.1 from entity @e[type=item_display,tag=dc_probe,limit=1] contents
kill @e[type=item_display,tag=dc_probe]

tellraw @s [{"text":"快捷栏 1 = 0 耐久（A，已破损）｜ 2 = 还剩 1 点（B，对照）","color":"gold"}]
tellraw @s [{"text":"各拿在手上对地面右键：A 放不下去 = 破损挡住了；A 也能放 = 组件挡不住放置","color":"yellow"}]
