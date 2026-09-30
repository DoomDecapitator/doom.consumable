# doom.consumable:core/mark_placed - 放置类物品使用标记
# FIXED (K1): 放置即消耗（每次 item_used_on_block 触发时扣 1 次使用）
#   语义: place 物品每次放置消耗 1 次，耗尽后按 depleted 模式处理
#         vanish → 物品消失; remainder → 给物品; disable → 数据包不再计数/不再返还
#
#   ⚠ 2026-09-20：disable 对 place 类**做不到"不能再放置"**（实测）。
#     放置走的是方块交互、受玩家属性 `block_interaction_range` 控制，物品侧没有"禁止放置"开关；
#     所以 place 类 disable 只能是"数据包不再管它"（摘 detect）。唯一物品侧杠杆是 attribute_modifiers，
#     代价是拿着它期间连箱子/按钮/挖方块都够不到。旧注释写的"不能再放置"是错的。
#
#   ⚠ 2026-09-26 定案（真机复现 + 日志实证）：**物品必须取"放置之前"那一份**。
#     原版是在**消耗掉手上那件之后**才触发 item_used_on_block，所以奖励函数跑起来时：
#       · count=1 ⇒ 手是空的 ⇒ 链连物品都认不出 ⇒ 放下去直接丢、永不返还
#       · count≥2 ⇒ 手上是**扣过一次**的那叠（3→2）⇒ "返还"还的是扣完那份 ⇒ 每放一次永久少一件
#     来源：core/snapshot_hand 写在 tick 函数**最后**（在所有恢复动作之后）的那份快照 ——
#       它在放置之前、又已经反映了上一次恢复的结果（放 tick 最前面会拍到"扣过那份"，连续放置必掉数）。
#     时刻戳窗口 [T−1, T]：交互包在服务器 tick 最前面处理、写快照的 #minecraft:tick 更晚，
#       所以放置那一刻缓存里必然是上一 tick 那份；再旧的不认，否则会把陈旧物品复活 = 凭空造物。
#
#   ⚠ 2026-09-26 第二个坑：**到底是哪只手放的？**成就触发不带这个信息，而玩家可能**两只手都有**
#     place 物品（实测：主手无限荧石 3 + 副手有限荧石 5）。旧的"主手优先"会让恢复写到没被用的那只手 ⇒
#     被消耗的那份没补回来、另一只却多一份 ⇒ 玩家看到的正是"**物品被送到下一个槽位**"（其实是一次复制）。
#     现在按**数量差**判断：快照比当前手少的那只 = 真被消耗的那只。
advancement revoke @s only doom.consumable:item_used
# 静默诊断（不刷聊天栏）：dc.trigger = 本函数被触发的次数，dc.placed = 真正建成任务的次数。
#   两者的差 = "成就触发了但没能认出 place 物品"的次数（那几次的原版消耗会永久丢，值得盯）。
#   入口闸门在进度里：item_used.json 的 match_tool 谓词用 predicates 子集匹配
#   {"minecraft:custom_data":{"dc":{"detect":"place"}}}（注意 predicates 与 items 同级）。
scoreboard players add @s dc.trigger 1
data modify storage doom.consumable:ctx task_data set value {}

# ---------- 第一步：读快照 + 定时刻窗口 ----------
function doom.library:api/open
execute store result score #snap_now dc.temp run time query gametime
execute store result score #snap_at dc.temp run data get storage doom.library:io output[-1].data.CACHE.hand.data.time
scoreboard players operation #snap_min dc.temp = #snap_now dc.temp
scoreboard players remove #snap_min dc.temp 1
scoreboard players set #snap_ok dc.temp 0
execute if score #snap_at dc.temp <= #snap_now dc.temp if score #snap_at dc.temp >= #snap_min dc.temp run scoreboard players set #snap_ok dc.temp 1

# ---------- 第二步：靠"快照 − 当前手"的数量差判断用了哪只手 ----------
# 差值 ≥ 1 = 那只手确实少了一件（就是它被消耗了）。差值不可用时下面有兜底。
execute store result score #snap_main_diff dc.temp run data get storage doom.library:io output[-1].data.CACHE.hand.data.mainhand.count
execute store result score #now_main dc.temp run data get entity @s SelectedItem.count
scoreboard players operation #snap_main_diff dc.temp -= #now_main dc.temp
execute store result score #snap_off_diff dc.temp run data get storage doom.library:io output[-1].data.CACHE.hand.data.offhand.count
execute store result score #now_off dc.temp run data get entity @s equipment.offhand.count
scoreboard players operation #snap_off_diff dc.temp -= #now_off dc.temp

# #snap_hand: 0=未定 1=mainhand 2=offhand
scoreboard players set #snap_hand dc.temp 0
execute if score #snap_ok dc.temp matches 1 if score #snap_main_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.hand.data.mainhand.components."minecraft:custom_data"."dc"{detect:"place"} run scoreboard players set #snap_hand dc.temp 1
execute if score #snap_ok dc.temp matches 1 if score #snap_hand dc.temp matches 0 if score #snap_off_diff dc.temp matches 1.. if data storage doom.library:io output[-1].data.CACHE.hand.data.offhand.components."minecraft:custom_data"."dc"{detect:"place"} run scoreboard players set #snap_hand dc.temp 2
# 差值判断不了（两边都没少 / 有一边本来就不是 place 物品）⇒ 退回"快照里谁是 place 物品"，主手优先
execute if score #snap_ok dc.temp matches 1 if score #snap_hand dc.temp matches 0 if data storage doom.library:io output[-1].data.CACHE.hand.data.mainhand.components."minecraft:custom_data"."dc"{detect:"place"} run scoreboard players set #snap_hand dc.temp 1
execute if score #snap_ok dc.temp matches 1 if score #snap_hand dc.temp matches 0 if data storage doom.library:io output[-1].data.CACHE.hand.data.offhand.components."minecraft:custom_data"."dc"{detect:"place"} run scoreboard players set #snap_hand dc.temp 2

# ---------- 第三步：采纳（slot_path 与 item 成对，只由 #snap_hand 决定）----------
execute if score #snap_hand dc.temp matches 1 run data modify storage doom.consumable:ctx task_data.slot_path set value "weapon.mainhand"
execute if score #snap_hand dc.temp matches 1 run data modify storage doom.consumable:ctx task_data.item set from storage doom.library:io output[-1].data.CACHE.hand.data.mainhand
execute if score #snap_hand dc.temp matches 2 run data modify storage doom.consumable:ctx task_data.slot_path set value "weapon.offhand"
execute if score #snap_hand dc.temp matches 2 run data modify storage doom.consumable:ctx task_data.item set from storage doom.library:io output[-1].data.CACHE.hand.data.offhand
# 2026-09-27：把快照里记的"选中热键槽"一并采纳 —— 恢复落点要精确到 hotbar.N。
#   否则玩家在"放置 → 恢复"之间换槽，恢复会写进新槽、把新槽里的东西直接抹掉（= 吞物品）。
execute if data storage doom.consumable:ctx task_data.item if data storage doom.library:io output[-1].data.CACHE.hand.data.sel run data modify storage doom.consumable:ctx task_data.sel set from storage doom.library:io output[-1].data.CACHE.hand.data.sel

# ---------- 第四步：快照完全不可用时退回当前手（例如刚装包还没跑过 tick）----------
execute unless data storage doom.consumable:ctx task_data.item if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"place"} run data modify storage doom.consumable:ctx task_data.slot_path set value "weapon.mainhand"
execute unless data storage doom.consumable:ctx task_data.item if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"place"} run data modify storage doom.consumable:ctx task_data.item set from entity @s SelectedItem
execute unless data storage doom.consumable:ctx task_data.item if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"place"} run data modify storage doom.consumable:ctx task_data.slot_path set value "weapon.offhand"
execute unless data storage doom.consumable:ctx task_data.item if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{detect:"place"} run data modify storage doom.consumable:ctx task_data.item set from entity @s equipment.offhand
# 兜底这条路读的是**当前手**，所以槽号也取当前这一刻的
execute unless data storage doom.consumable:ctx task_data.item if data entity @s SelectedItemSlot if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{detect:"place"} run data modify storage doom.consumable:ctx task_data.sel set from entity @s SelectedItemSlot

# ---------- 派发 ----------
# 落点/id 定死（恢复链 restore/guard 靠它们判断"目标槽位能不能写"）
execute if data storage doom.consumable:ctx task_data.item run function doom.consumable:core/finalize_slot
# 分别计数：恢复落点翻到副手时一眼可见（静默，不刷聊天栏）
execute if data storage doom.consumable:ctx task_data{slot_path:"weapon.mainhand"} run scoreboard players add @s dc.placed_main 1
execute if data storage doom.consumable:ctx task_data{slot_path:"weapon.offhand"} run scoreboard players add @s dc.placed_off 1
execute if data storage doom.consumable:ctx task_data.item run scoreboard players add @s dc.placed 1
execute if data storage doom.consumable:ctx task_data.item run execute store result score @s dc.lastcount run data get storage doom.consumable:ctx task_data.item.count
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"limited"} run function doom.consumable:schedule/limited with storage doom.consumable:ctx task_data
execute if data storage doom.consumable:ctx task_data.item.components."minecraft:custom_data"."dc"{type:"infinite"} run function doom.consumable:schedule/infinite with storage doom.consumable:ctx task_data
# 放置节奏取证：不管这次有没有认出物品，都记一次"放置发生的时刻"（间隔分布见 core/place_diag）
function doom.consumable:core/place_diag
data remove storage doom.consumable:ctx task_data
# 方块冷却（放置即冷却）：物品声明了 dc.place_cd ⇒ 给刚放下的那一格挂一台「出生即冷却」的设备
#   （秒数写在放置类物品自己的 dc 上，与包内物品契约一致；未声明的物品行为完全不变）
execute if data storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc".place_cd run function doom.consumable:block/place_begin
execute unless data storage doom.library:io output[-1].data.CACHE.usage.data.main_snap.components."minecraft:custom_data"."dc".place_cd if data storage doom.library:io output[-1].data.CACHE.usage.data.off_snap.components."minecraft:custom_data"."dc".place_cd run function doom.consumable:block/place_begin
