# doom.consumable:rod/bind_impl [MACRO] —— 给本刻新抛的浮标打归属标签
#
# 调用：rod/cast_ok with storage doom.consumable:ctx rod（rod.uid = 玩家 UUID[0] int 分量）
# 语义：tag=!dc_rod_seen = 本刻新抛（rod/tick ③ 在每刻末尾给所有浮标补 dc_rod_seen）；
#   sort=nearest + distance=..32（执行点是玩家自己）⇒ 认的就是自己刚抛的那颗——
#   浮标从玩家眼部生成，别人的浮标不可能比自己那颗更近；多玩家同刻各抛各的也不串（tick_one 逐玩家串行）。
# 产出：浮标带 dc_rod_own_<uid> 直到实体消亡（收杆/断线/外力都随实体一起消失，无需清理）。
# 为什么需要它：1.21.6 浮标存档**没有 Owner 字段**（2026-09-30 真机实锤），
#   归属只能靠抛竿时主动打标；收杆检测（watch_impl）与外部强收（api/rod_reel）都靠这个标签。
$tag @e[type=minecraft:fishing_bobber, tag=!dc_rod_seen, distance=..32, sort=nearest, limit=1] add dc_rod_own_$(uid)
