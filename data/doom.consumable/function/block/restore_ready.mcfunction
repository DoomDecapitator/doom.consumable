# doom.consumable:block/restore_ready —— 单台设备：冷却到点就把方块换回「就绪」形态
#
# 自带全部条件（没声明 cd_block_ready / 还没到期 / 已经是就绪态都直接 return），所以可无条件调用：
#   · block/tick_restore —— 每 5 tick 扫一遍设备（as 设备 at @s 调用本函数）
# 位置：以设备自身为执行位置（block/set_device_state 用不了，这里直接 setblock ~ ~ ~）。
execute unless data entity @s data.dc.cd_block_ready run return 0
scoreboard players set #blk_rd dc.temp 0
execute store result score #blk_rd dc.temp run data get entity @s data.dc.cd_ready
execute if score #blk_rd dc.temp matches ..0 run return 0
execute store result score #blk_now dc.temp run time query gametime
execute if score #blk_now dc.temp < #blk_rd dc.temp run return 0
data modify storage doom.consumable:ctx blk.state set from entity @s data.dc.cd_block_ready
function doom.consumable:block/set_self_state with storage doom.consumable:ctx blk
data modify entity @s data.dc.cd_ready set value 0
data remove storage doom.consumable:ctx blk.state
