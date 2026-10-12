# doom.consumable:tick
#
# doomtest-ignore: E2 —— 本文件的每条 `execute as @a` 都**自包含**：
#   被调函数在同一行里跑完一位玩家的全流程，写与读都在那次调用内，不存在跨行共享临时状态。
#   E2 是"提醒规则"，这里显式豁免（真正违规的形态见 recover/tick_one 头部说明）。
execute as @a[scores={dc.restore_timer=1..}] run scoreboard players remove @s dc.restore_timer 1
execute as @a[scores={dc.restore_timer=0}] at @s run function doom.consumable:restore/do_check_timer
execute as @a[scores={dc.consume_timer=1..}] run scoreboard players remove @s dc.consume_timer 1
execute as @a[scores={dc.consume_timer=0}] at @s run function doom.consumable:core/process_usage_wrapper
execute as @a[scores={dc.consume_timer=0}] run scoreboard players set @s dc.consume_timer -1
# Discard timer (drop cooldown)
execute as @a[scores={dc.discard_timer=1..}] run scoreboard players remove @s dc.discard_timer 1
execute as @a[scores={dc.discard_timer=0}] at @s run function doom.consumable:restore/do_discard_restore
# Drop detection (scan for freshly dropped discardable items)
function doom.consumable:core/detect_drop
# 伪耐久条的回复驱动（只对带 dc.recover:1b 的物品生效，其它玩家/物品零匹配）
function doom.consumable:recover/tick
# Cache refresh for players not in an active detection window
# 2026-09-11：原选择器带 tag=!dc.used —— 而 dc.used 从未被设置，该条件恒真。
# 已删掉这个失效谓词，行为不变但语义不再骗人。
execute as @a[scores={dc.consume_timer=..-1,dc.restore_timer=..-1,dc.discard_timer=..-1}] run function doom.consumable:core/refresh_hand_cache

# 鱼竿右键接口：统计事件（DC 接口）→ 状态机 → 否决时同 tick 收回鱼漂
#   早退闸门在 rod/tick_one 里（身上没有 dc{rod:1b} 的玩家零开销）；
#   必须放在手部快照**之前**（快照是 tick 的最后一步，别动它的位置）。
function doom.consumable:rod/tick

# 弓/弩/三叉戟射击链（stat 差分事件源，2026-09-30 弓扩展）。
# 必须放 snapshot_hand **之前**（同 rod）：扣次先改主手，快照读到的才是扣完次的状态。
function doom.consumable:shot/tick

# 投掷物消耗链（2026-10-05 P0-1）：雪球 / 鸡蛋 / 末影珍珠 / 经验瓶。
# 同 shot：必须放 snapshot_hand 之前（扣次若改主手，快照要拍到改完之后的状态）。
function doom.consumable:throw/tick

# 方块冷却设备：每 5 tick 把到期的「冷却态」方块换回「就绪态」（自带条件，无设备时零成本）
function doom.consumable:block/tick_restore

# ============ 手部快照（放置链入口用）—— 必须是 tick 的**最后一步** ============
# 位置很讲究（2026-09-26 两次踩才定）：
#   · 原版是在**消耗掉手上那件之后**才触发 item_used_on_block ⇒ 入口不能读"当前手"，
#     必须读这份快照（它是"放置之前"的那份）。
#   · 快照必须放在**所有恢复动作之后**：放在最前面时，上一次放置的恢复还没跑，
#     拍到的就是"被扣过的那份"（3→2 的 2）⇒ 下一次放置采纳它又少一件。
#     手动慢慢放（间隔 >1 tick）看不出来，**按住右键连续放**就会每次少一件。
#   · 玩家交互包在服务器 tick 最前面处理，所以下一 tick 的放置读到的正是本行写下的快照
#     （mark_placed 的时刻戳窗口是 [当前刻−1, 当前刻]，正是为这个时序留的）。
execute as @a run function doom.consumable:core/snapshot_hand
# 副手看门狗：副手数量一旦增加就记账（静默）—— 专抓幽灵/复制，见该文件注释
execute as @a run function doom.consumable:core/watch_offhand
