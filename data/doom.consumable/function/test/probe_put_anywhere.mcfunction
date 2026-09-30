# doom.consumable:test/probe_put_anywhere —— 直接**真跑**一次"找第一个空槽"的兜底函数
#
# 为什么单独做这个探针（2026-09-27）：
#   守卫套件 A/D 两格在真机上打出「手/背包都被占着，物品先放在脚下」，
#   可当时玩家背包只占 9/36 格 —— 梯子**本该**找到空槽。两种判据（items(*) / NBT 占用）
#   在"占用格"上表现一致（probe_slot_guard ②③），但"空格子"这一侧一直没被单独问过。
#   本探针把梯子**原样跑一遍**（真的建中转体、真的调 put_anywhere），报告 #done 与最终落点。
#
# 用法：/function doom.consumable:test/probe_put_anywhere     （自己布置、自己收尾）
tellraw @s [{"text":"===== [SLOT] put_anywhere 实测 =====","color":"gold"}]

# ① 当前占用：Inventory 列表长度
execute store result score #len dc.temp run data get entity @s Inventory
tellraw @s [{"text":"① Inventory 列表长度 = ","color":"gray"},{"score":{"name":"#len","objective":"dc.temp"},"color":"white"},{"text":"（36 = 一格不空；9 之类 = 有大片空位）","color":"dark_gray"}]

# ② 前 12 格并排看两种判据（hotbar.0-8 + inventory.0-2）
tellraw @s [{"text":"② 前 12 格（items(*) / NBT）：每格两行，命中=占着","color":"gray"}]
execute if items entity @s hotbar.0 * run tellraw @s [{"text":"   hotbar.0     items(*) 命中","color":"gray"}]
execute unless items entity @s hotbar.0 * run tellraw @s [{"text":"   hotbar.0     items(*) 未命中（空）","color":"green"}]
execute if data entity @s Inventory[{Slot:0b}] run tellraw @s [{"text":"   hotbar.0     NBT 有条目","color":"gray"}]
execute unless data entity @s Inventory[{Slot:0b}] run tellraw @s [{"text":"   hotbar.0     NBT 空","color":"green"}]
execute if items entity @s hotbar.1 * run tellraw @s [{"text":"   hotbar.1     items(*) 命中","color":"gray"}]
execute unless items entity @s hotbar.1 * run tellraw @s [{"text":"   hotbar.1     items(*) 未命中（空）","color":"green"}]
execute if data entity @s Inventory[{Slot:1b}] run tellraw @s [{"text":"   hotbar.1     NBT 有条目","color":"gray"}]
execute unless data entity @s Inventory[{Slot:1b}] run tellraw @s [{"text":"   hotbar.1     NBT 空","color":"green"}]
execute if items entity @s hotbar.2 * run tellraw @s [{"text":"   hotbar.2     items(*) 命中","color":"gray"}]
execute unless items entity @s hotbar.2 * run tellraw @s [{"text":"   hotbar.2     items(*) 未命中（空）","color":"green"}]
execute if data entity @s Inventory[{Slot:2b}] run tellraw @s [{"text":"   hotbar.2     NBT 有条目","color":"gray"}]
execute unless data entity @s Inventory[{Slot:2b}] run tellraw @s [{"text":"   hotbar.2     NBT 空","color":"green"}]
execute if items entity @s hotbar.3 * run tellraw @s [{"text":"   hotbar.3     items(*) 命中","color":"gray"}]
execute unless items entity @s hotbar.3 * run tellraw @s [{"text":"   hotbar.3     items(*) 未命中（空）","color":"green"}]
execute if data entity @s Inventory[{Slot:3b}] run tellraw @s [{"text":"   hotbar.3     NBT 有条目","color":"gray"}]
execute unless data entity @s Inventory[{Slot:3b}] run tellraw @s [{"text":"   hotbar.3     NBT 空","color":"green"}]
execute if items entity @s hotbar.4 * run tellraw @s [{"text":"   hotbar.4     items(*) 命中","color":"gray"}]
execute unless items entity @s hotbar.4 * run tellraw @s [{"text":"   hotbar.4     items(*) 未命中（空）","color":"green"}]
execute if data entity @s Inventory[{Slot:4b}] run tellraw @s [{"text":"   hotbar.4     NBT 有条目","color":"gray"}]
execute unless data entity @s Inventory[{Slot:4b}] run tellraw @s [{"text":"   hotbar.4     NBT 空","color":"green"}]
execute if items entity @s hotbar.5 * run tellraw @s [{"text":"   hotbar.5     items(*) 命中","color":"gray"}]
execute unless items entity @s hotbar.5 * run tellraw @s [{"text":"   hotbar.5     items(*) 未命中（空）","color":"green"}]
execute if data entity @s Inventory[{Slot:5b}] run tellraw @s [{"text":"   hotbar.5     NBT 有条目","color":"gray"}]
execute unless data entity @s Inventory[{Slot:5b}] run tellraw @s [{"text":"   hotbar.5     NBT 空","color":"green"}]

# ③ 只读复刻梯子：两种判据各挑出第一格（编码 0-8 = hotbar.N，100.. = inventory.N-9）
scoreboard players set #f dc.temp -1
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:0b}] run scoreboard players set #f dc.temp 0
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:1b}] run scoreboard players set #f dc.temp 1
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:2b}] run scoreboard players set #f dc.temp 2
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:3b}] run scoreboard players set #f dc.temp 3
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:4b}] run scoreboard players set #f dc.temp 4
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:5b}] run scoreboard players set #f dc.temp 5
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:6b}] run scoreboard players set #f dc.temp 6
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:7b}] run scoreboard players set #f dc.temp 7
execute if score #f dc.temp matches -1 unless data entity @s Inventory[{Slot:8b}] run scoreboard players set #f dc.temp 8
scoreboard players set #g dc.temp -1
execute if score #g dc.temp matches -1 unless items entity @s hotbar.0 * run scoreboard players set #g dc.temp 0
execute if score #g dc.temp matches -1 unless items entity @s hotbar.1 * run scoreboard players set #g dc.temp 1
execute if score #g dc.temp matches -1 unless items entity @s hotbar.2 * run scoreboard players set #g dc.temp 2
execute if score #g dc.temp matches -1 unless items entity @s hotbar.3 * run scoreboard players set #g dc.temp 3
execute if score #g dc.temp matches -1 unless items entity @s hotbar.4 * run scoreboard players set #g dc.temp 4
execute if score #g dc.temp matches -1 unless items entity @s hotbar.5 * run scoreboard players set #g dc.temp 5
execute if score #g dc.temp matches -1 unless items entity @s hotbar.6 * run scoreboard players set #g dc.temp 6
execute if score #g dc.temp matches -1 unless items entity @s hotbar.7 * run scoreboard players set #g dc.temp 7
execute if score #g dc.temp matches -1 unless items entity @s hotbar.8 * run scoreboard players set #g dc.temp 8
tellraw @s [{"text":"③ 梯子第一格（只读）：NBT 版 = ","color":"gray"},{"score":{"name":"#f","objective":"dc.temp"},"color":"white"},{"text":"   items(*) 版 = ","color":"gray"},{"score":{"name":"#g","objective":"dc.temp"},"color":"white"}]

# ④ 真跑一遍 put_anywhere：中转体拿一件 barrier，看它能不能进空槽
clear @s minecraft:barrier 0
execute store result score #b0 dc.temp run clear @s minecraft:barrier 0
scoreboard players set #done dc.temp -1
kill @e[type=item_display,tag=dc_restore_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_restore_tmp"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_restore_tmp,limit=1] item.id set value "minecraft:barrier"
function doom.consumable:restore/put_anywhere
execute store result score #b1 dc.temp run clear @s minecraft:barrier 0
tellraw @s [{"text":"④ 真跑 put_anywhere：#done = ","color":"gray"},{"score":{"name":"#done","objective":"dc.temp"},"color":"white"},{"text":"   barrier 数量 ","color":"gray"},{"score":{"name":"#b0","objective":"dc.temp"},"color":"white"},{"text":" → ","color":"dark_gray"},{"score":{"name":"#b1","objective":"dc.temp"},"color":"white"}]
tellraw @s [{"text":"判读：#done=1 且 barrier 数量 +1 ⇒ 梯子正常（进空槽）；#done=0 ⇒ 梯子一格都没命中（才是真 bug）","color":"yellow"}]

# ⑤ 收尾：清掉探针自己放进去的 barrier 与中转体
kill @e[type=item_display,tag=dc_restore_tmp]
clear @s minecraft:barrier 1000
kill @e[type=item,nbt={Item:{id:"minecraft:barrier"}},distance=..16]
data remove storage doom.consumable:ctx rb.item
