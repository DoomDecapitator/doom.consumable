# doom.consumable:block/force_ready —— 无条件把设备方块换成「就绪」形态（不看冷却是否到期）
#
# 与 restore_ready 的区别：那个是"到点了自然换回"，这个是"人为收尾"（移除设备时用），
#   所以不能带到期判定（否则删掉设备后方块会永远留在冷却态 —— 2026-10-01 实测踩到）。
execute unless data entity @s data.dc.cd_block_ready run return 0
data modify storage doom.consumable:ctx blk.state set from entity @s data.dc.cd_block_ready
function doom.consumable:block/set_self_state with storage doom.consumable:ctx blk
data modify entity @s data.dc.cd_ready set value 0
data remove storage doom.consumable:ctx blk.state
