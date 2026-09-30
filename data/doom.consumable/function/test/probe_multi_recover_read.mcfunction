# doom.consumable:test/probe_multi_recover_read —— 只读：两件里各自的 damage / rb_cd
# 用法：跑过 probe_multi_recover、等一会儿之后再跑本命令。
#
# 判读（2026-09-27 改版后）：
#   · 两件的 damage 都在**各自**往下走（7→…、5→…，相差保持 2）= 正确
#   · 只有一件在动 / 另一件冻住                      = 还是"只认一件"的老毛病
#   · 两件 damage 变成同一个数（串台/跳变）           = 计时器又挂到玩家身上去了
tellraw @s [{"text":"===== [RB] 多件判读 =====（每件自己一份 dc.rb_cd）","color":"gold"}]
data remove storage doom.consumable:ctx probe.a
data remove storage doom.consumable:ctx probe.b
execute if data entity @s Inventory[{Slot:8b}] run data modify storage doom.consumable:ctx probe.a set from entity @s Inventory[{Slot:8b}]
execute if data entity @s Inventory[{Slot:9b}] run data modify storage doom.consumable:ctx probe.b set from entity @s Inventory[{Slot:9b}]
tellraw @s [{"text":"hotbar.8   （Slot 8）id = ","color":"gray"},{"nbt":"probe.a.id","storage":"doom.consumable:ctx","color":"white"},{"text":"  damage = ","color":"gray"},{"nbt":"probe.a.components.\"minecraft:damage\"","storage":"doom.consumable:ctx","color":"white"},{"text":"  rb_cd = ","color":"gray"},{"nbt":"probe.a.components.\"minecraft:custom_data\".\"dc\".\"rb_cd\"","storage":"doom.consumable:ctx","color":"white"}]
tellraw @s [{"text":"inventory.0（Slot 9）id = ","color":"gray"},{"nbt":"probe.b.id","storage":"doom.consumable:ctx","color":"white"},{"text":"  damage = ","color":"gray"},{"nbt":"probe.b.components.\"minecraft:damage\"","storage":"doom.consumable:ctx","color":"white"},{"text":"  rb_cd = ","color":"gray"},{"nbt":"probe.b.components.\"minecraft:custom_data\".\"dc\".\"rb_cd\"","storage":"doom.consumable:ctx","color":"white"}]
tellraw @s [{"text":"游标 dc.rb_slot = ","color":"gray"},{"score":{"name":"@s","objective":"dc.rb_slot"},"color":"white"},{"text":"（108=hotbar.8，200=inventory.0，扫完停在最后一个命中的槽）","color":"dark_gray"}]
tellraw @s [{"text":"判读：两件各自的 damage 与 rb_cd 都在动 = 正确；只有一件动 = 又变回「只认一件」；两件值相同 = 串台。","color":"aqua"}]
tellraw @s [{"text":"清场：/function doom.consumable:test/probe_multi_recover_wipe（或 doom.test:reset_one）","color":"dark_gray"}]
data remove storage doom.consumable:ctx probe.a
data remove storage doom.consumable:ctx probe.b
