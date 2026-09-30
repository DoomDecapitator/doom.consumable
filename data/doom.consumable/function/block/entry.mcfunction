# doom.consumable:block/entry —— 方块交互入口（两条进度都指向这里）
#
# 用途：给「挂在方块上的冷却设备」（marker 实体，tag dc.block_cd）做冷却闸门。
#   · 命中设备且已到期 ⇒ 刷新到期刻 + 触发回调 #doom.consumable:on_block_use
#   · 命中设备但还在冷却 ⇒ 触发回调 #doom.consumable:on_block_denied（带剩余 tick）
#
# 为什么需要「射线找方块」：原版触发器**不给奖励函数**「被交互的方块坐标」
# （item_used_on_block 条件里的 location 只用于过滤，函数读不到）⇒
# 这里从眼睛沿视线逐 0.25 格推进把那个方块找回来。只在真的发生方块交互时跑（入口是进度奖励），常驻成本为零。
#
# 便宜门：8 格内没有本包设备 ⇒ 直接返回（普通世界里每次右键只多一次选择器查询）
# ⚠ 重新上膛必须放在**最前面**（2026-10-01 修复）：原先把 revoke 写在便宜门之后，
#   于是"8 格内没有设备"的那次交互会消耗掉成就、却不重新上膛 ⇒ 之后所有方块交互永久失效。
advancement revoke @s only doom.consumable:block_use
advancement revoke @s only doom.consumable:block_use_empty

# 便宜门：8 格内既没有设备、也没有「方块类型配置」⇒ 直接返回。
#   ⚠ 配置驱动时"设备是第一次使用时才现场建的"⇒ 不能只看设备存在与否（那会让配置永远不生效）。
execute unless entity @e[type=minecraft:marker,tag=dc.block_cd,distance=..8] unless data storage doom.consumable:block_cd entries[0] run return 0
scoreboard players set #blk_hit dc.temp 0
scoreboard players set #blk_step dc.temp 0
# ⚠ 必须 anchored eyes：射线要从眼睛出发（run function 的上下文是玩家脚底位置，直接用会从脚底射出、
#   几格之外就落在设备下方 —— 2026-10-01 实测踩到：guard 通过但 hit 恒 0）。
execute anchored eyes run function doom.consumable:block/ray_step
