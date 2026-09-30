# doom.consumable:recover/hit [MACRO] —— 推进**一件**伪耐久条的回复（逐件独立，不串台）
#
# 调用：function doom.consumable:recover/hit with storage doom.consumable:ctx args
# 前置：storage doom.consumable:ctx rb.item = 那一件的 NBT（调用方已取好）
#       宏参数 $(name) = 写回用的可执行槽位名（hotbar.N / weapon.mainhand / weapon.offhand）
#
# 状态**跟着物品自己走**：`dc.rb_cd` = 离下一格的剩余 tick（存在即"正在回复"）。
#   · 没在回复 + damage ≥ 1  → 起表：rb_cd = recover_ticks（缺省 10 tick/格）
#   · 在回复（rb_cd ≥ 1）    → 每 tick 减 1；减到 0 就涨一格（damage − 1）并复位成 recover_ticks
#   · damage 到 0（回满）    → 删掉 rb_cd（停表；下次被用坏时重新起表）
#
# ⚠⚠ 为什么状态必须放进物品（2026-09-27 玩家报障「两件同时在身上时条会串台/跳变」）：
#   旧版计时器是**玩家分数**（dc.recover / dc.recover_step），写回的值是
#   `recover / interval`（= 玩家计时器算出来的**绝对格数**）；而"写哪一件"是每 tick 重新按
#   "主手 > 副手 > 背包"挑一件 ⇒ 玩家身上有两件时：
#     · A 的进度被写到 B 身上（B 的条突然跳到 A 的格数 = 串台/跳变）
#     · B 自己那件的进度永远推不动（冻结）
#   状态挂在物品上之后，"这一 tick 该动哪一件"这个问题自然消失：每件各算各的，
#   在手上、在背包、换手、换槽都不影响（recover/scan 保证每件都被访问到）。
#
# ⚠ 本文件与 recover/slot、recover/scan 共用共享临时（rb.item / dc_rb 中转体），
#   必须"一个玩家一口气跑完"—— 见 recover/tick_one 与 tick 头部说明（易错点 §2.4.1）。

# ---------- 读：damage（缺省 0 = 满条）----------
scoreboard players set #D dc.temp 0
execute if data storage doom.consumable:ctx rb.item.components."minecraft:damage" store result score #D dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:damage"

# ---------- 读：间隔（物品自报 recover_ticks，缺省 10）----------
# ⚠ loot_table 里写的数字按最小宽度落盘（JSON `10` → NBT `10b`），
#   所以判据/读取一律走 `data get`（它按数值取），不要用 NBT 数字判据比宽度。
scoreboard players set #iv dc.temp 10
execute if data storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".recover_ticks store result score #iv dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".recover_ticks
execute if score #iv dc.temp matches ..0 run scoreboard players set #iv dc.temp 10

# ---------- 读：倒计时（-1 = 这件没在回复）----------
scoreboard players set #cd dc.temp -1
execute if data storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".rb_cd store result score #cd dc.temp run data get storage doom.consumable:ctx rb.item.components."minecraft:custom_data"."dc".rb_cd

# ---------- 算：#write = 1 才需要写回（省掉无谓的中转体）----------
scoreboard players set #write dc.temp 0

# 满条：只在"还残留着 rb_cd"时清一下（自愈：物品被别的手段修好了，别留个停不掉的表）
execute if score #D dc.temp matches ..0 if score #cd dc.temp matches 0.. run scoreboard players set #write dc.temp 1

# 未满 + 没在回复 → 起表（rb_cd = interval；紧接着就会走下面的递减 ⇒ 1 tick 后读到 interval−1）
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches ..-1 run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches ..-1 run scoreboard players operation #cd dc.temp = #iv dc.temp

# 未满 + 在回复 → 递减；减到 0 就涨一格并复位（**先减后判**，否则最后一格永远差一格）
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 1.. run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 1.. run scoreboard players remove #cd dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players set #write dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players remove #D dc.temp 1
execute if score #D dc.temp matches 1.. if score #cd dc.temp matches 0 run scoreboard players operation #cd dc.temp = #iv dc.temp

execute if score #write dc.temp matches 0 run return 0

# ---------- 写回：中转体（先清后建；专包专用 tag dc_rb）+ 落到 $(name) ----------
kill @e[type=item_display,tag=dc_rb]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_rb"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_rb,limit=1] item set from storage doom.consumable:ctx rb.item
execute store result entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:damage" int 1 run scoreboard players get #D dc.temp
# 未满 → 写回倒计时；已回满 → 把倒计时删掉（= 停表）
execute if score #D dc.temp matches 1.. store result entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd int 1 run scoreboard players get #cd dc.temp
execute if score #D dc.temp matches 0 if data entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd run data remove entity @e[type=item_display,tag=dc_rb,limit=1] item.components."minecraft:custom_data"."dc".rb_cd
$item replace entity @s $(name) from entity @e[type=item_display,tag=dc_rb,limit=1] contents
kill @e[type=item_display,tag=dc_rb,limit=1]
data remove storage doom.consumable:ctx rb.item

# 排查线索：想知道"哪一件、涨到第几格了"，跑 doom.consumable:test/probe_recover_all
# （生产代码不刷聊天栏：诊断行一律留在探针里）
