# doom.consumable:block/ray_step —— 视线射线：每步 0.25 格，最多 20 步（5 格，覆盖原版约 4.5 格交互距离）
#
# 目标：找回「原版这次交互打到的那个方块」—— 做法就是沿视线找**第一个非空气方块**：
#   原版服务端的 BlockHitResult 也是这么来的，而触发器**不给奖励函数**方块坐标
#   （条件里的 location 只用于过滤）⇒ 只能自己重算。
# ⚠ 必须 anchored eyes（run function 的上下文是玩家脚底，直接用会从脚底射出，几格之外就落到方块下方）。
# ⚠ 命中后要 align xyz：射线点可能落在目标方块**前面一格**（空气块），
#   不 align 的话 `if block ~ ~ ~ #标签` 测的是空气 ⇒ 永远匹配不上。
scoreboard players add #blk_step dc.temp 1
execute unless block ~ ~ ~ #doom.consumable:air_like run execute align xyz run function doom.consumable:block/found_block
execute if score #blk_hit dc.temp matches 1 run return 0
execute if score #blk_step dc.temp matches ..20 positioned ^ ^ ^0.25 run function doom.consumable:block/ray_step
