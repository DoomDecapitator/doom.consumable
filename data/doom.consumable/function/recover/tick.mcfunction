# doom.consumable:recover/tick —— 每 tick 驱动"伪耐久条"的回复（由 tick/tick 调用）
# 调用：function doom.consumable:recover/tick
#
# 只对带 dc.recover:1b 的物品生效；其它物品连判据都不匹配，几乎零开销。
#
# 2026-09-26：**主手 / 副手 / 背包**三处都参与（旧版的"优先级"已随 2026-09-27 改版取消 ——
#   现在每件各算各的，见下）。
# 2026-09-27：计时状态搬进物品自身（dc.rb_cd），并改成**逐槽扫描** ⇒
#   身上几件同时回复都不会串台，换手 / 换槽 / 进出背包也不失步
#   （玩家报障原话：「两件同时在身上时条会串台/跳变」）。
#
# ⚠⚠ 本文件只做一件事：**逐玩家分发**。真正的每一步在 recover/tick_one 里，
#   而且必须"一个玩家一口气跑完" —— 原因见 tick_one 头部的并发说明：
#   rb.item 与中转体 tag dc_rb 都是**全局共享**的，拆成多条 `as @a` 行会让玩家之间互相覆盖
#   （多玩家乱序，单玩家看不出来）。2026-09-26 由玩家当场指出这一点后改成现在这样。
#   **不要再把逐玩家步骤铺回本文件。**
execute as @a at @s run function doom.consumable:recover/tick_one
