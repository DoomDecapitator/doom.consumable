# doom.consumable:restore/mark_sync —— 给"即将塞回玩家手里"的物品盖一个每刻唯一的戳
#
# 调用方式（**作用者是中转体 item_display**）：
#     execute as @e[type=item_display,tag=dc_restore_tmp,limit=1] run function doom.consumable:restore/mark_sync
#
# 为什么必须有这一步（2026-09-26 真机 A/B 坐实）：
#   · 原版消耗与我们恢复发生在**同一 tick**，恢复出来的又与客户端手上那件**逐字节相同**
#   · 服务端的容器同步是**对比式**的（把自己的"远端副本"与当前槽位比，一样就不发包）
#     —— 它并不知道客户端已经按自己的预测把手上那件抹掉了
#   ⇒ 客户端停在"已消耗"画面：**手里看不见东西，但功能完全正常**（能放、计数也涨）
#   实测：`test/ghost_start`（关）＝看不见；`test/ghost_start_on`（开）＝全程看得见。唯一变量就是这个戳。
#
# 开关：#resync dc.cfg（__load__ 里默认 1 = 开）。0 只用于复现幽灵、做对照。
# 代价：物品自定义数据每放一次变一次（对玩家不可见；已实测不会引起换手抖动）。
#   只对**已经带 dc 的物品**盖戳（没有 dc 命名空间的不碰）。
execute if score #resync dc.cfg matches 1 if data entity @s item.components."minecraft:custom_data"."dc" store result entity @s item.components."minecraft:custom_data"."dc".resync int 1 run time query gametime
