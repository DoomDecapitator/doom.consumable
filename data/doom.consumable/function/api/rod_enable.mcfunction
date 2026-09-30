# doom.consumable:api/rod_enable —— 解除禁用（清 dc.rod_locked 与 use_cooldown）
#
# 调用：execute as <玩家> run function doom.consumable:api/rod_enable
# 作用对象：执行者手上那把 dc 鱼竿（主手优先，其次副手）。
# 注意：若禁用来自**物品标签** #doom.consumable:rod_locked，本函数清不掉（标签在数据包侧）——
#   那种情况请把物品从标签里移除。
function doom.consumable:rod/pick
execute unless data storage doom.consumable:ctx rod.item run return 0
data remove storage doom.consumable:ctx rod.item.components."minecraft:custom_data"."dc".rod_locked
data remove storage doom.consumable:ctx rod.item.components."minecraft:use_cooldown"
function doom.consumable:rod/writeback with storage doom.consumable:ctx rod
