# doom.consumable:test/probe_multi_recover —— 两件同时在身上时，**两件都要各自回**
#
# 为什么要有这个探针（2026-09-27，玩家报障原话）：
#   「两件同时在身上时条会串台/跳变」—— 旧版计时器挂在**玩家分数**上，而写回目标每 tick 按
#   "主手 > 副手 > 背包"只挑一件 ⇒ 一件的进度被写到另一件上（串台/跳变），另一件永远推不动（冻结）。
#   修法：计时状态搬进物品自身 dc.rb_cd + 逐槽扫描（见 recover/hit、recover/scan）。
#
# 本探针把两件分别放进 hotbar.8（Inventory.Slot 8）与 inventory.0（Slot 9），
#   damage 故意不同（7 / 5）—— 于是"哪件在动、动成什么样"一眼可判。
#
# 用法：
#   /function doom.consumable:test/probe_multi_recover       ← 布置（两件各就各位）+ 驱动 1 tick
#   等 10~20 秒（或直接再跑一次 tick）
#   /function doom.consumable:test/probe_multi_recover_read  ← 只读：看两件的 damage 与 rb_cd
tellraw @s [{"text":"[RB] 布置两件（hotbar.8 damage=7 / inventory.0 damage=5），两件都该各自回…","color":"gold"}]
item replace entity @s hotbar.8 with minecraft:heart_of_the_sea[minecraft:max_damage=10,minecraft:max_stack_size=1,minecraft:damage=7,minecraft:custom_data={dc:{recover:1b,recover_ticks:10b,type:"infinite"}}]
item replace entity @s inventory.0 with minecraft:heart_of_the_sea[minecraft:max_damage=10,minecraft:max_stack_size=1,minecraft:damage=5,minecraft:custom_data={dc:{recover:1b,recover_ticks:10b,type:"infinite"}}]
function doom.consumable:recover/tick
tellraw @s [{"text":"布置完成并驱动 1 tick：两件都应当出现 dc.rb_cd = 9（各自起表）。","color":"gray"}]
tellraw @s [{"text":"游标 dc.rb_slot = ","color":"gray"},{"score":{"name":"@s","objective":"dc.rb_slot"},"color":"white"},{"text":"（扫完停在**最后一个**命中的槽：Slot 9 ⇒ 200）","color":"dark_gray"}]
function doom.consumable:test/probe_multi_recover_read
