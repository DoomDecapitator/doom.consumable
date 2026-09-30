# doom.consumable:test/probe_slot_guard —— 落点判据体检（`execute if items` vs NBT 占用）
#
# 背景（2026-09-27）：restore/put_anywhere 的"找第一个空槽"梯子在真机上**没命中任何空槽**
#   （两次都走了掉落兜底），而 restore/guard 里同一形态的 `if items entity @s <slot> <id>`
#   却按预期工作。本探针把两种判据在同一批槽位上并排打印，并用**只读**方式把两条梯子的条件
#   各跑一遍，直接问出"到底哪一格会被选中"。
#
# 用法：/function doom.consumable:test/probe_slot_guard     （纯读，不动任何东西）
tellraw @s [{"text":"===== [SLOT] 落点判据体检 =====","color":"gold"}]

# ---------- ① 主手：一定占着 —— items(*) 必须命中 ----------
execute if items entity @s weapon.mainhand * run tellraw @s [{"text":"① weapon.mainhand  items(*) = 命中 ✓（手上有东西）","color":"green"}]
execute unless items entity @s weapon.mainhand * run tellraw @s [{"text":"① weapon.mainhand  items(*) = 未命中 ✗（手上有东西却说不命中 ⇒ 这个判据不可靠）","color":"red"}]

# ---------- ② 四格并排：items(*) 结果 vs NBT 占用 ----------
execute if items entity @s hotbar.0 * run tellraw @s [{"text":"② hotbar.0    items(*) = 命中","color":"gray"}]
execute unless items entity @s hotbar.0 * run tellraw @s [{"text":"② hotbar.0    items(*) = 未命中","color":"gray"}]
execute if data entity @s Inventory[{Slot:0b}] run tellraw @s [{"text":"   hotbar.0    NBT   = 有条目（占用）","color":"dark_gray"}]
execute unless data entity @s Inventory[{Slot:0b}] run tellraw @s [{"text":"   hotbar.0    NBT   = 空","color":"dark_gray"}]

execute if items entity @s hotbar.5 * run tellraw @s [{"text":"② hotbar.5    items(*) = 命中","color":"gray"}]
execute unless items entity @s hotbar.5 * run tellraw @s [{"text":"② hotbar.5    items(*) = 未命中","color":"gray"}]
execute if data entity @s Inventory[{Slot:5b}] run tellraw @s [{"text":"   hotbar.5    NBT   = 有条目（占用）","color":"dark_gray"}]
execute unless data entity @s Inventory[{Slot:5b}] run tellraw @s [{"text":"   hotbar.5    NBT   = 空","color":"dark_gray"}]

execute if items entity @s inventory.0 * run tellraw @s [{"text":"② inventory.0 items(*) = 命中","color":"gray"}]
execute unless items entity @s inventory.0 * run tellraw @s [{"text":"② inventory.0 items(*) = 未命中","color":"gray"}]
execute if data entity @s Inventory[{Slot:9b}] run tellraw @s [{"text":"   inventory.0 NBT   = 有条目（占用）","color":"dark_gray"}]
execute unless data entity @s Inventory[{Slot:9b}] run tellraw @s [{"text":"   inventory.0 NBT   = 空","color":"dark_gray"}]

execute if items entity @s inventory.8 * run tellraw @s [{"text":"② inventory.8 items(*) = 命中","color":"gray"}]
execute unless items entity @s inventory.8 * run tellraw @s [{"text":"② inventory.8 items(*) = 未命中","color":"gray"}]
execute if data entity @s Inventory[{Slot:17b}] run tellraw @s [{"text":"   inventory.8 NBT   = 有条目（占用）","color":"dark_gray"}]
execute unless data entity @s Inventory[{Slot:17b}] run tellraw @s [{"text":"   inventory.8 NBT   = 空","color":"dark_gray"}]

# ---------- ③ 只读复刻两条梯子（前 12 格：hotbar.0-8 → 0..8，inventory.0-2 → 100..102）----------
#   与 put_anywhere 的写法逐字一致，只是把"写入"换成"记下第一个命中位"。
scoreboard players set #f dc.temp -1
execute if score #f dc.temp matches -1 unless items entity @s hotbar.0 * run scoreboard players set #f dc.temp 0
execute if score #f dc.temp matches -1 unless items entity @s hotbar.1 * run scoreboard players set #f dc.temp 1
execute if score #f dc.temp matches -1 unless items entity @s hotbar.2 * run scoreboard players set #f dc.temp 2
execute if score #f dc.temp matches -1 unless items entity @s hotbar.3 * run scoreboard players set #f dc.temp 3
execute if score #f dc.temp matches -1 unless items entity @s hotbar.4 * run scoreboard players set #f dc.temp 4
execute if score #f dc.temp matches -1 unless items entity @s hotbar.5 * run scoreboard players set #f dc.temp 5
execute if score #f dc.temp matches -1 unless items entity @s hotbar.6 * run scoreboard players set #f dc.temp 6
execute if score #f dc.temp matches -1 unless items entity @s hotbar.7 * run scoreboard players set #f dc.temp 7
execute if score #f dc.temp matches -1 unless items entity @s hotbar.8 * run scoreboard players set #f dc.temp 8
execute if score #f dc.temp matches -1 unless items entity @s inventory.0 * run scoreboard players set #f dc.temp 100
execute if score #f dc.temp matches -1 unless items entity @s inventory.1 * run scoreboard players set #f dc.temp 101
execute if score #f dc.temp matches -1 unless items entity @s inventory.2 * run scoreboard players set #f dc.temp 102

scoreboard players set #g dc.temp -1
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:0b}] run scoreboard players set #g dc.temp 0
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:1b}] run scoreboard players set #g dc.temp 1
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:2b}] run scoreboard players set #g dc.temp 2
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:3b}] run scoreboard players set #g dc.temp 3
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:4b}] run scoreboard players set #g dc.temp 4
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:5b}] run scoreboard players set #g dc.temp 5
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:6b}] run scoreboard players set #g dc.temp 6
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:7b}] run scoreboard players set #g dc.temp 7
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:8b}] run scoreboard players set #g dc.temp 8
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:9b}] run scoreboard players set #g dc.temp 100
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:10b}] run scoreboard players set #g dc.temp 101
execute if score #g dc.temp matches -1 unless data entity @s Inventory[{Slot:11b}] run scoreboard players set #g dc.temp 102

tellraw @s [{"text":"③ items(*) 梯子选中：","color":"gray"},{"score":{"name":"#f","objective":"dc.temp"},"color":"white"},{"text":"    NBT 梯子选中：","color":"gray"},{"score":{"name":"#g","objective":"dc.temp"},"color":"white"},{"text":"   （编码：0-8 = hotbar.N；100/101/102 = inventory.0/1/2；-1 = 前 12 格一个都没命中）","color":"dark_gray"}]
tellraw @s [{"text":"判读：两个数不同 ⇒ items(*) 判据与 NBT 占用判据不等价（正是 put_anywhere 走掉落兜底的原因，已改用 NBT 判据）；两个数都是 -1 ⇒ 前 12 格真的都占着。","color":"yellow"}]
