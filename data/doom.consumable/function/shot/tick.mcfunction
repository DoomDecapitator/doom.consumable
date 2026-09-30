# doom.consumable:shot/tick —— 弓/弩/三叉戟射击链入口（每刻由 tick 调用）
# 逐玩家单行调用（同 rod/tick 约定）：tick_one 内的共享临时分数（#shot_now/#shot_prev）安全。
execute as @a at @s run function doom.consumable:shot/tick_one
