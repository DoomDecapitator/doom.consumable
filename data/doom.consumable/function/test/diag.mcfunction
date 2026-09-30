# doom.consumable:test/diag — 卡住时跑这一条命令，把判定需要的信息全打到聊天栏
# 用法：/function doom.consumable:test/diag
tellraw @s [{"text":"===== [dc] diag =====","color":"gold"}]

execute unless data entity @s SelectedItem.components."minecraft:custom_data"."dc" run tellraw @s [{"text":"main: 手上不是 dc 物品（id = ","color":"yellow"},{"nbt":"SelectedItem.id","entity":"@s","interpret":false,"color":"white"},{"text":"）","color":"yellow"}]
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run tellraw @s [{"text":"main.id     = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","interpret":false,"color":"white"}]
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run tellraw @s [{"text":"main.uses   = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\".current_uses","entity":"@s","interpret":false,"color":"white"},{"text":"  / max_uses = ","color":"dark_gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\".max_uses","entity":"@s","interpret":false,"color":"dark_gray"}]
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run tellraw @s [{"text":"main.damage = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:damage\"","entity":"@s","interpret":false,"color":"white"},{"text":"  / max_damage = ","color":"dark_gray"},{"nbt":"SelectedItem.components.\"minecraft:max_damage\"","entity":"@s","interpret":false,"color":"dark_gray"}]
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run tellraw @s [{"text":"main.dc     = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc" run tellraw @s [{"text":"main.count  = ","color":"gray"},{"nbt":"SelectedItem.count","entity":"@s","interpret":false,"color":"white"}]

# 缓存里还剩什么（api/open 会把该玩家数据写到 output[-1]）
function doom.library:api/open
tellraw @s [{"text":"CACHE.usage      = ","color":"gray"},{"nbt":"output[-1].data.CACHE.usage","storage":"doom.library:io","interpret":false,"color":"white"}]
tellraw @s [{"text":"CACHE.consumable = ","color":"gray"},{"nbt":"output[-1].data.CACHE.consumable","storage":"doom.library:io","interpret":false,"color":"white"}]

# 计时器放最后：万一某行不被支持，上面关键信息已经拿到了
execute store result score #diag_ct dc.temp run scoreboard players get @s dc.consume_timer
execute store result score #diag_rt dc.temp run scoreboard players get @s dc.restore_timer
tellraw @s [{"text":"timers: consume=","color":"gray"},{"score":{"name":"#diag_ct","objective":"dc.temp"},"color":"white"},{"text":" restore=","color":"gray"},{"score":{"name":"#diag_rt","objective":"dc.temp"},"color":"white"}]
