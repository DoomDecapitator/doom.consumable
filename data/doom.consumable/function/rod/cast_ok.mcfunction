# doom.consumable:rod/cast_ok —— 抛竿放行：状态置 1 + 浮标归属绑定 + 外部回调
scoreboard players set @s dc.rod_state 1
# （BUG-4 的"统计差分消费"行已随错杀路由一并删除：统计只路由 cast，
#   单次右键双回调在 B1 新结构下结构性不可能——差分不再被读第二次。）
#
# ---- 浮标归属绑定（B1）：收杆检测的地基 ----
# 1.21.6 浮标存档**没有 Owner 字段**（2026-09-30 真机实锤）⇒ 归属只能"抛竿时主动打标"：
#   ① UUID[0] → @s dc.rod_uid（分数缓存：之后每刻 watch / api 强收都读它，不用再读实体 NBT）
#   ② 本刻新抛（tag=!dc_rod_seen）且离我最近的浮标 ⇒ 打 dc_rod_own_<uid>（rod/bind_impl）
#   浮标从玩家眼部生成——别人的浮标不可能比自己那颗更近；同刻多人各抛各的也不串（逐玩家串行）。
execute store result score @s dc.rod_uid run data get entity @s UUID[0]
data remove storage doom.consumable:ctx rod
execute store result storage doom.consumable:ctx rod.uid int 1 run scoreboard players get @s dc.rod_uid
execute if data storage doom.consumable:ctx rod.uid run function doom.consumable:rod/bind_impl with storage doom.consumable:ctx rod
data remove storage doom.consumable:ctx rod
function #doom.consumable:on_rod_cast
#
# ---- 按钮模式（orbital 式单击触发器）----
# 物品声明 dc.rod_button:1b ⇒ 抛竿后立即收回浮标 + 状态归 0（api/rod_reel 是"无回调强收"）：
#   每次右键都是干净的 cast 事件，不进"钓鱼中"状态，也不会有后续 reel 回调。
#   外部回调（on_rod_cast）先执行——效果先响，浮标后杀。
execute if data entity @s SelectedItem.components."minecraft:custom_data"."dc"{rod_button:1b} run function doom.consumable:api/rod_reel
execute if data entity @s equipment.offhand.components."minecraft:custom_data"."dc"{rod_button:1b} run function doom.consumable:api/rod_reel
