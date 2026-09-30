# 诊断：手上这件物品到底有没有把 block_interaction_range 改掉
# 用法：拿着要测的那一格，运行本命令
#
# 为什么要量而不是猜：probe_reach 那一轮（物品**没有** max_damage/damage）修饰符生效、放不下去；
# probe_reach_zero 这一轮（0 耐久）同样写法却能放。两者只差 damage/max_damage。
# 于是只有两种解释：
#   (a) 0 耐久让 attribute_modifiers 失效
#   (b) 这一轮的修饰符根本没挂上（写 SNBT 出错）
# 本命令把"物品上有哪些修饰符"与"玩家实际算出来的属性值"同时打出来，直接分辨。
#
# 读法：
#   attribute_modifiers 那一行空      → (b)：修饰符没挂上
#   有修饰符、但 brr 仍是 4500        → 修饰符在物品上却不生效（(a) 或属性被别的来源覆盖）
#   有修饰符、brr 为 0 或负数         → 修饰符其实生效了，那就得重新解释"为什么还能放"
#
# spd 是控制量：movement_speed 默认 0.1 → ×1000 = 100。它非 0 才说明 attribute get 本身可用，
# 否则 brr 的 0 就只是"命令没跑成"而不是"属性被归零"。
tellraw @s [{"text":"===== [R] reach 诊断 =====","color":"gold"}]
tellraw @s [{"text":"手持 id = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"attribute_modifiers = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:attribute_modifiers\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"damage / max_damage = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:damage\"","entity":"@s","interpret":false,"color":"white"},{"text":" / ","color":"dark_gray"},{"nbt":"SelectedItem.components.\"minecraft:max_damage\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"custom_data = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\"","entity":"@s","interpret":false,"color":"white"}]

scoreboard players set #brr dc.temp -1
scoreboard players set #spd dc.temp -1
execute store result score #brr dc.temp run attribute @s minecraft:block_interaction_range get 1000
execute store result score #spd dc.temp run attribute @s minecraft:movement_speed get 1000
tellraw @s [{"text":"block_interaction_range ×1000 = ","color":"gold"},{"score":{"name":"#brr","objective":"dc.temp"},"color":"white"},{"text":"   （原版默认 4500）","color":"dark_gray"}]
tellraw @s [{"text":"movement_speed ×1000        = ","color":"gold"},{"score":{"name":"#spd","objective":"dc.temp"},"color":"white"},{"text":"   （控制量，默认 100；非 0 才说明 attribute get 可用）","color":"dark_gray"}]
