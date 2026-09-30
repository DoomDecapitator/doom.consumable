# doom.consumable:test/probe_bag_slot —— 背包槽位寻址探针（逐环节定位）
#
# 背景：suite/consumable_recover 的 ⑤d/⑤e 双双失败，而它们分别断言
#   "放进背包后继续涨条" 与 "按 Inventory[{Slot:12b}] 取件"。⑤e 也失败 ⇒ **那件不在 Slot 12**。
# 三种可能，一趟跑清：
#   A) `item replace … inventory.3` 落到的 **Slot 不是 12**（槽位映射假设错）
#   B) 该槽位名对玩家非法 ⇒ 命令失败 ⇒ 物品其实还在副手（随后被清副手时毁掉）
#   C) 落对了，但取件/写回把它写去了别的槽（物品被"搬家"）
#
# 用法：/function doom.consumable:test/probe_bag_slot
#   它会自己布置（副手放一件测试物 → 复制进 inventory.3 → 跑一次逐槽扫描），逐环节打印。
tellraw @s [{"text":"===== [BAG] 背包槽位寻址探针 =====","color":"gold"}]

# 先把现场清干净：双手、目标槽都清空，避免旧物品干扰判读
item replace entity @s weapon.mainhand with air
item replace entity @s weapon.offhand with air
item replace entity @s inventory.3 with air
item replace entity @s hotbar.3 with air
execute store result score #len0 dc.temp run data get entity @s Inventory
tellraw @s [{"text":"① 布置前 Inventory 列表长度 = ","color":"gray"},{"score":{"name":"#len0","objective":"dc.temp"},"color":"white"}]

# 布置：先写进副手（这条槽位名是**已验证**的），再复制到 inventory.3（待验证的那条）
item replace entity @s weapon.offhand with minecraft:heart_of_the_sea[minecraft:max_damage=10,minecraft:max_stack_size=1,minecraft:damage=7,minecraft:custom_data={dc:{recover:1b,recover_ticks:10b,type:"infinite"}}]
item replace entity @s inventory.3 from entity @s weapon.offhand
item replace entity @s weapon.offhand with air
execute store result score #len1 dc.temp run data get entity @s Inventory
tellraw @s [{"text":"② 复制到 inventory.3 之后 Inventory 长度 = ","color":"gray"},{"score":{"name":"#len1","objective":"dc.temp"},"color":"white"},{"text":"   （比①大 1 ⇒ 东西确实进了背包）","color":"dark_gray"}]

# 关键环节：整个 Inventory 原样打印 —— 直接看那件落在**哪个 Slot**
tellraw @s [{"text":"③ 整个 Inventory（看 Slot 字段到底几）：","color":"gray"}]
tellraw @s [{"nbt":"Inventory","entity":"@s","color":"white"}]

# 判据命中情况：能否按 Slot:12 取到、能否按 dc 过滤器取到
data remove storage doom.consumable:ctx probe.slot12
data remove storage doom.consumable:ctx probe.filter
execute if data entity @s Inventory[{Slot:12b}] run data modify storage doom.consumable:ctx probe.slot12 set from entity @s Inventory[{Slot:12b}]
execute if data entity @s Inventory[{components:{"minecraft:custom_data":{"dc":{"recover":1b}}}}] run data modify storage doom.consumable:ctx probe.filter set from entity @s Inventory[{components:{"minecraft:custom_data":{"dc":{"recover":1b}}}}]
tellraw @s [{"text":"④ Inventory[{Slot:12b}] = ","color":"gray"},{"nbt":"probe.slot12","storage":"doom.consumable:ctx","color":"white"}]
tellraw @s [{"text":"⑤ 按 dc 过滤器取件 = ","color":"gray"},{"nbt":"probe.filter","storage":"doom.consumable:ctx","color":"white"}]
data remove storage doom.consumable:ctx probe.slot12
data remove storage doom.consumable:ctx probe.filter

# 逐槽扫描的结论：游标该停在"最后一个命中的槽"（100+N=hotbar.N / 200+N=inventory.N）
#   2026-09-27：recover/locate 已删除（它每 tick 只认一件 = 串台/冻结的根因），
#   现在扫的是全部 36 槽；探针里只有 Slot 12 这一件 ⇒ 扫完游标必须正好停在 203。
function doom.consumable:recover/scan
tellraw @s [{"text":"⑥ recover/scan 结论 dc.rb_slot = ","color":"gray"},{"score":{"name":"@s","objective":"dc.rb_slot"},"color":"white"},{"text":"   （按设计：Slot 12 ⇒ 200+(12−9)=203）","color":"dark_gray"}]
data remove storage doom.consumable:ctx rb.item

tellraw @s [{"text":"判读：③ 里那件的 Slot 若不是 12 ⇒ 槽位映射假设错了（A）；② 长度没涨或③里根本没有那件 ⇒ 命令失败/物品丢了（B）；③ 是 12 而⑥不是 203 ⇒ 换算错了（C）。","color":"aqua"}]

# 收尾：把探针自己布置的东西收干净。
#   ⚠ 2026-09-26 教训：它留在 inventory.3 的那件会让此后所有停表类断言失败
#   （套件 ⑤f/⑦ 就是这么被坑的 —— 现在套件有开关兜底，但探针本身也该干净离场）。
item replace entity @s inventory.3 with air
data remove storage doom.consumable:ctx rb.item
