# doom.consumable:recover/scan —— 逐槽扫描玩家 36 个背包槽（**本文件由脚本生成**）
# 生成器：tools/gen_recover_slots.py（改槽位范围就重跑它，别手改）
#
# 调用：execute as @s at @s run function doom.consumable:recover/scan
# 前置：@s = 玩家；storage doom.consumable:ctx rb.item 干净（由 recover/tick_one 保证）
#
# 2026-09-27 为什么要"逐槽扫"而不是"用过滤器取一件"：
#   旧版用 NBT 过滤器只取**第一件**能命中的物品，于是同一玩家身上的第二件永远轮不到 ——
#   表现就是"两件同时在身上时条会串台/跳变"（玩家报障原话）。
#   根因是**计时器挂在玩家分数上**，而写回目标却按"当前定位到的那一件"挑 ⇒ 一件的进度被写到另一件上。
#   现在状态（dc.rb_cd = 离下一格的剩余 tick）**跟着物品自己走**，每一件都必须被访问到，
#   所以必须逐槽扫；代价是每 tick 36 条守卫行，且**只有身上带着 recover 物品的玩家**才走到这里
#   （recover/tick_one 第一行的门槛把绝大多数玩家挡在外面）。
#
# 宏参数摆平在这里（宏只能读扁平键）：
#   $(i)    槽号（用于 Inventory[{Slot:ib}] 过滤器）
#   $(name) 可执行槽位名（hotbar.N / inventory.N）
#   $(slot) 诊断游标编码

# ---------- 快捷栏：Inventory.Slot 0-8 → hotbar.0-8 ----------
data modify storage doom.consumable:ctx args set value {i:0,name:"hotbar.0",slot:100}
execute if data entity @s Inventory[{Slot:0b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:1,name:"hotbar.1",slot:101}
execute if data entity @s Inventory[{Slot:1b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:2,name:"hotbar.2",slot:102}
execute if data entity @s Inventory[{Slot:2b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:3,name:"hotbar.3",slot:103}
execute if data entity @s Inventory[{Slot:3b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:4,name:"hotbar.4",slot:104}
execute if data entity @s Inventory[{Slot:4b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:5,name:"hotbar.5",slot:105}
execute if data entity @s Inventory[{Slot:5b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:6,name:"hotbar.6",slot:106}
execute if data entity @s Inventory[{Slot:6b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:7,name:"hotbar.7",slot:107}
execute if data entity @s Inventory[{Slot:7b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:8,name:"hotbar.8",slot:108}
execute if data entity @s Inventory[{Slot:8b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args

# ---------- 背包主区：Inventory.Slot 9-35 → inventory.0-26 ----------
data modify storage doom.consumable:ctx args set value {i:9,name:"inventory.0",slot:200}
execute if data entity @s Inventory[{Slot:9b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:10,name:"inventory.1",slot:201}
execute if data entity @s Inventory[{Slot:10b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:11,name:"inventory.2",slot:202}
execute if data entity @s Inventory[{Slot:11b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:12,name:"inventory.3",slot:203}
execute if data entity @s Inventory[{Slot:12b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:13,name:"inventory.4",slot:204}
execute if data entity @s Inventory[{Slot:13b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:14,name:"inventory.5",slot:205}
execute if data entity @s Inventory[{Slot:14b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:15,name:"inventory.6",slot:206}
execute if data entity @s Inventory[{Slot:15b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:16,name:"inventory.7",slot:207}
execute if data entity @s Inventory[{Slot:16b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:17,name:"inventory.8",slot:208}
execute if data entity @s Inventory[{Slot:17b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:18,name:"inventory.9",slot:209}
execute if data entity @s Inventory[{Slot:18b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:19,name:"inventory.10",slot:210}
execute if data entity @s Inventory[{Slot:19b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:20,name:"inventory.11",slot:211}
execute if data entity @s Inventory[{Slot:20b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:21,name:"inventory.12",slot:212}
execute if data entity @s Inventory[{Slot:21b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:22,name:"inventory.13",slot:213}
execute if data entity @s Inventory[{Slot:22b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:23,name:"inventory.14",slot:214}
execute if data entity @s Inventory[{Slot:23b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:24,name:"inventory.15",slot:215}
execute if data entity @s Inventory[{Slot:24b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:25,name:"inventory.16",slot:216}
execute if data entity @s Inventory[{Slot:25b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:26,name:"inventory.17",slot:217}
execute if data entity @s Inventory[{Slot:26b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:27,name:"inventory.18",slot:218}
execute if data entity @s Inventory[{Slot:27b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:28,name:"inventory.19",slot:219}
execute if data entity @s Inventory[{Slot:28b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:29,name:"inventory.20",slot:220}
execute if data entity @s Inventory[{Slot:29b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:30,name:"inventory.21",slot:221}
execute if data entity @s Inventory[{Slot:30b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:31,name:"inventory.22",slot:222}
execute if data entity @s Inventory[{Slot:31b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:32,name:"inventory.23",slot:223}
execute if data entity @s Inventory[{Slot:32b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:33,name:"inventory.24",slot:224}
execute if data entity @s Inventory[{Slot:33b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:34,name:"inventory.25",slot:225}
execute if data entity @s Inventory[{Slot:34b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args
data modify storage doom.consumable:ctx args set value {i:35,name:"inventory.26",slot:226}
execute if data entity @s Inventory[{Slot:35b,components:{"minecraft:custom_data":{dc:{recover:1b}}}}] run function doom.consumable:recover/slot with storage doom.consumable:ctx args

# 扫完清干净共享临时键（下一 tick / 下一个玩家还要用同一个路径）
data remove storage doom.consumable:ctx rb.item
