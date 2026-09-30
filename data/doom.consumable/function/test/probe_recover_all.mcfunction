# 探针：一次性问全 —— 主手 / 副手 / 背包里的伪耐久条物品各是什么状态
# 用法：/function doom.consumable:test/probe_recover_all
# 不需要刻意拿什么：它会把"心到底在哪"和"每件的倒计时"直接打印出来。
#
# 2026-09-27 改版：状态搬进物品（dc.rb_cd）并改成逐槽扫描 ⇒ 本探针改成
#   "逐件打印 damage + rb_cd"，驱动一次 tick 后再打印一遍，看**每一件**有没有各自推进。
tellraw @s [{"text":"===== [RB] 全量判读 =====（状态在物品上：dc.rb_cd = 离下一格的剩余 tick）","color":"gold"}]

# 主手
tellraw @s [{"text":"主手 id = ","color":"gray"},{"nbt":"SelectedItem.id","entity":"@s","interpret":false,"color":"white"},{"text":"   damage/max = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:damage\"","entity":"@s","interpret":false,"color":"white"},{"text":" / ","color":"dark_gray"},{"nbt":"SelectedItem.components.\"minecraft:max_damage\"","entity":"@s","interpret":false,"color":"white"},{"text":"   dc = ","color":"gray"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]
# 副手
tellraw @s [{"text":"副手 id = ","color":"gray"},{"nbt":"equipment.offhand.id","entity":"@s","interpret":false,"color":"white"},{"text":"   damage = ","color":"gray"},{"nbt":"equipment.offhand.components.\"minecraft:damage\"","entity":"@s","interpret":false,"color":"white"},{"text":"   dc = ","color":"gray"},{"nbt":"equipment.offhand.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]

# 1) 门槛：身上有没有带 dc{recover:1b} 的东西（背包 或 副手）
execute if data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run tellraw @s [{"text":"1) 背包/快捷栏里命中 dc{recover:1b} ✓ —— 逐槽扫描会访问它","color":"green"}]
execute unless data entity @s Inventory[{components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run tellraw @s [{"text":"1) 背包/快捷栏里没有 dc{recover:1b}","color":"gray"}]
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{recover:1b} run tellraw @s [{"text":"1b) 副手命中 dc{recover:1b} ✓","color":"green"}]

# 2) 驱动一次，看每件有没有各自推进（同一 tick 内，"哪一件"不再需要挑）
tellraw @s [{"text":"2) 调用 doom.consumable:recover/tick …（下面每一项都应当各自 −1）","color":"gray"}]
function doom.consumable:recover/tick
tellraw @s [{"text":"   主手 dc = ","color":"gold"},{"nbt":"SelectedItem.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"   副手 dc = ","color":"gold"},{"nbt":"equipment.offhand.components.\"minecraft:custom_data\".\"dc\"","entity":"@s","interpret":false,"color":"white"}]
tellraw @s [{"text":"   游标 dc.rb_slot = ","color":"gold"},{"score":{"name":"@s","objective":"dc.rb_slot"},"color":"white"},{"text":"（100+N hotbar.N / 200+N inventory.N / 1 副手 / 0 主手）","color":"dark_gray"}]

# 3) 背包抽样三格（探针/套件常用的 Slot 8 / 9 / 12）：各自 id / damage / rb_cd
data remove storage doom.consumable:ctx probe
execute if data entity @s Inventory[{Slot:8b}] run data modify storage doom.consumable:ctx probe.a set from entity @s Inventory[{Slot:8b}]
execute if data entity @s Inventory[{Slot:9b}] run data modify storage doom.consumable:ctx probe.b set from entity @s Inventory[{Slot:9b}]
execute if data entity @s Inventory[{Slot:12b}] run data modify storage doom.consumable:ctx probe.c set from entity @s Inventory[{Slot:12b}]
tellraw @s [{"text":"   hotbar.8  (Slot 8)  id = ","color":"gray"},{"nbt":"probe.a.id","storage":"doom.consumable:ctx","color":"white"},{"text":"  damage = ","color":"gray"},{"nbt":"probe.a.components.\"minecraft:damage\"","storage":"doom.consumable:ctx","color":"white"},{"text":"  rb_cd = ","color":"gray"},{"nbt":"probe.a.components.\"minecraft:custom_data\".\"dc\".\"rb_cd\"","storage":"doom.consumable:ctx","color":"white"}]
tellraw @s [{"text":"   inventory.0(Slot 9)  id = ","color":"gray"},{"nbt":"probe.b.id","storage":"doom.consumable:ctx","color":"white"},{"text":"  damage = ","color":"gray"},{"nbt":"probe.b.components.\"minecraft:damage\"","storage":"doom.consumable:ctx","color":"white"},{"text":"  rb_cd = ","color":"gray"},{"nbt":"probe.b.components.\"minecraft:custom_data\".\"dc\".\"rb_cd\"","storage":"doom.consumable:ctx","color":"white"}]
tellraw @s [{"text":"   inventory.3(Slot 12) id = ","color":"gray"},{"nbt":"probe.c.id","storage":"doom.consumable:ctx","color":"white"},{"text":"  damage = ","color":"gray"},{"nbt":"probe.c.components.\"minecraft:damage\"","storage":"doom.consumable:ctx","color":"white"},{"text":"  rb_cd = ","color":"gray"},{"nbt":"probe.c.components.\"minecraft:custom_data\".\"dc\".\"rb_cd\"","storage":"doom.consumable:ctx","color":"white"}]
data remove storage doom.consumable:ctx probe
tellraw @s [{"text":"判读：每一件都应当自己走自己的 rb_cd（不再有「只有第一件会回」）；rb_cd 缺失而 damage≥1 = 下一 tick 会起表","color":"yellow"}]
