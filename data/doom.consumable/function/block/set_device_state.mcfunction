# doom.consumable:block/set_device_state [MACRO] —— 把「最近那台设备所在方块」换成 blk.state 指定的形态
#
# 调用：function doom.consumable:block/set_device_state with storage doom.consumable:ctx blk
#       （blk.state = 完整方块状态串，例 minecraft:lever[face=floor,powered=true]）
# 位置要求：调用者的位置在设备 1 格内（allow / debug 的射线命中点满足）。
$execute at @e[type=minecraft:marker,tag=dc.block_cd,distance=..1,limit=1,sort=nearest] run setblock ~ ~ ~ $(state)
