# doom.consumable:test/_reach_diag —— 打印"手持物品 + 当前方块交互距离"读数
# 由 probe_reach_full 调用；每条读数前调用方会先打一行标题。
# 为什么把两件事一起打：光看物品 NBT 不知道属性有没有生效，光看属性不知道物品上挂了什么。
tellraw @s [{"text":"  id = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","interpret":false,"color":"white"},{"text":"  damage/max = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:damage\"","entity":"@s","interpret":false,"color":"white"},{"text":"/","color":"dark_gray"},{"nbt":"SelectedItem.components.\"minecraft:max_damage\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"  attribute_modifiers = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:attribute_modifiers\"","entity":"@s","interpret":false,"color":"white"}]
scoreboard players set #brr dc.temp -1
scoreboard players set #spd dc.temp -1
execute store result score #brr dc.temp run attribute @s minecraft:block_interaction_range get 1000
execute store result score #spd dc.temp run attribute @s minecraft:movement_speed get 1000
tellraw @s [{"text":"  block_interaction_range×1000 = ","color":"gold"},{"score":{"name":"#brr","objective":"dc.temp"},"color":"white"},{"text":"   movement_speed×1000 = ","color":"gold"},{"score":{"name":"#spd","objective":"dc.temp"},"color":"white"},{"text":"（控制量，默认 100）","color":"dark_gray"}]
