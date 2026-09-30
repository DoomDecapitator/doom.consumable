# doom.consumable:core/mark_consumed — 消耗已发生：补拍使用快照 + 挂 1 tick 处理计时器
#
# 为什么必须在这里补拍快照（2026-10-01 实测）：
#   正常"有持续时间的"物品靠 using_item 每 tick 刷新的快照来认物品；但
#   `consume_seconds: 0` 的物品走 Consumable.use() 的**即时分支** ⇒ 不调 startUsingItem
#   ⇒ using_item 永不发火 ⇒ 快照缺失 ⇒ 旧逻辑下"右键直接消失、不计数也不恢复"。
#   实测：consume_item 的**奖励函数早于扣减**执行 —— 此刻手上还是**刚被消耗的那件**（count=N 未减）。
#   所以在这里补拍一张快照，下面 1 tick 后的 process_usage_wrapper 差分（N → N-1）就照样成立，
#   0 秒物品与普通物品走完全同一条链。
#   ⚠ 顺带根治另一个真 bug：快照必定来自"这一次消耗"，不可能再拿上一次没消耗掉的旧快照张冠李戴。
advancement revoke @s only doom.consumable:consume
function doom.consumable:core/pre_save
scoreboard players set @s dc.consume_timer 1
