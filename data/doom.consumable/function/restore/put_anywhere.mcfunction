# doom.consumable:restore/put_anywhere —— 目标槽位被占了：塞进第一个空槽；没有空槽就掉在脚下
#
# **本文件由脚本生成**：tools/gen_restore_fallback.py（改槽位范围就重跑它，别手改）
#
# 什么时候会走到这里（2026-09-27 新增）：
#   恢复的目标槽位里已经站着**别的东西**了 —— 典型场景是玩家在"消耗 → 恢复"之间换了槽/捡了别的东西。
#   旧版这时仍然 `item replace` 硬塞回去，于是把那一格里的东西直接抹掉（玩家报障：切换物品使用会吞物品）。
#   现在的规矩：**绝不覆盖**。先按 hotbar.0-8 → inventory.0-26 找第一个空槽；一个都没有就把物品
#   掉在脚下（PickupDelay 0，立刻能捡回来），并给一句黄字提示。任何一条路都不会销毁物品。
#
# ⚠ "这一格空着吗"用 **NBT 占用判据**（`Inventory[{Slot:ib}]` 没有条目 = 空），
#   不用 `unless items entity @s <slot> *`：后者在真机梯子里没能命中过任何空槽
#   （guard 里同一形态的 inventory.N 却正常 —— 2026-09-27 的体检探针 test/probe_slot_guard 里复盘）。
#   NBT 占用是本项目反复用过的判据（探针、旧 scan_inv_slots 都是它），稳。
#
# 前置：@e[type=item_display,tag=dc_restore_tmp,limit=1] = 中转体（拿着要放回的那件）；@s = 玩家
# 产出：#done dc.temp = 1 表示已落位（供调用方判断是否走了掉落兜底）
execute unless entity @e[type=item_display,tag=dc_restore_tmp,limit=1] run return 0
scoreboard players set #done dc.temp 0
data modify storage doom.consumable:ctx put.name set value "hotbar.0"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:0b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.1"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:1b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.2"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:2b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.3"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:3b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.4"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:4b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.5"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:5b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.6"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:6b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.7"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:7b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "hotbar.8"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:8b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.0"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:9b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.1"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:10b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.2"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:11b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.3"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:12b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.4"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:13b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.5"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:14b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.6"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:15b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.7"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:16b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.8"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:17b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.9"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:18b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.10"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:19b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.11"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:20b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.12"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:21b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.13"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:22b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.14"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:23b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.15"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:24b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.16"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:25b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.17"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:26b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.18"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:27b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.19"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:28b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.20"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:29b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.21"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:30b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.22"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:31b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.23"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:32b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.24"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:33b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.25"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:34b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put
data modify storage doom.consumable:ctx put.name set value "inventory.26"
execute if score #done dc.temp matches 0 unless data entity @s Inventory[{Slot:35b}] run function doom.consumable:restore/put_slot with storage doom.consumable:ctx put

# 36 格全满：掉在脚下（PickupDelay 0 = 能立刻捡回；地上没销毁风险）
# 2026-09-27：走到这里时顺手报一次「当时到底占了几格」—— 下次不用再靠猜。
execute if score #done dc.temp matches 0 run execute store result score #len dc.temp run data get entity @s Inventory
execute if score #done dc.temp matches 0 run tellraw @s [{"text":"[dc] 手/背包都被占着，物品先放在脚下（当时 Inventory 条目数 = ","color":"yellow"},{"score":{"name":"#len","objective":"dc.temp"},"color":"white"},{"text":"）","color":"yellow"}]
# BUG-3 修复（2026-09-30 beta 实锤）：裸 summon（无 Item compound）在 1.21.6 召出 "Air" 且一刻即毁，
#   下一行 data modify 找不到活实体 ⇒ 满背包兜底变成静默销毁物品。占位 Item 让实体活到换装那一步。
execute if score #done dc.temp matches 0 run summon minecraft:item ~ ~ ~ {Tags:["dc_restored"],PickupDelay:0s,Motion:[0d,0.3d,0d],Item:{id:"minecraft:stone",count:1}}
execute if score #done dc.temp matches 0 run data modify entity @e[type=item,tag=dc_restored,limit=1] Item set from entity @e[type=item_display,tag=dc_restore_tmp,limit=1] item
execute if score #done dc.temp matches 0 run tag @e[type=item,tag=dc_restored,limit=1] remove dc_restored
