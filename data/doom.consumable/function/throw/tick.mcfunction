# doom.consumable:throw/tick —— 投掷物消耗链入口（雪球 / 鸡蛋 / 末影珍珠 / 经验瓶）
#
# ★ 2026-10-05 关键实证（推翻了本任务书的前置判断）：
#   任务书说「原版**没有** `minecraft.used:minecraft.snowball` 这个统计 ⇒ 必须另造事件源」——
#   **实测该判断不成立**。本机 1.21.11 真机三连证：
#     ① `scoreboard objectives add probe.snow minecraft.used:minecraft.snowball`
#        ⇒ `Created new objective [probe.snow]`（**准则合法**，非未知准则）
#     ② 假玩家持雪球连按 5 次 `player Alice use once`
#        ⇒ 计分板 **5**、背包 16 → 11（**真的计数**，且与实际消耗同步）
#     ③ 对照组：同法持 `minecraft:stick` 连按 3 次 ⇒ **不计分**（0）
#        ⇒ 证明这不是"右键就加"的泛化计数，而是**投掷语义专属**的统计。
#   附带实证：`minecraft.used:minecraft.egg` 3 次 ⇒ 3；`minecraft.used:minecraft.ender_pearl`
#   3 次 ⇒ 1（珍珠把人传送走，后续几次没落在原地，但**确实计数**）。
#
#   ⇒ 结论：**投掷物可以直接复刻 shot 链的 stat 差分结构**，不需要实体检测、不需要进度变体、
#     也不需要参考 Ragecraft IV 的 `@e[type=snowball]` 兜底做法。
#     （Ragecraft 之所以用实体 tag 分派，是因为它要的是**自定义弹幕行为**——
#     地图 own 的雪球是 `summon` 出来的、不经过玩家投掷，自然没有 stat。
#     而本包要的是「玩家自己扔出去的那一下扣次」，stat 正是对的工具。两者问题不同。）
#
# 逐玩家单行调用（与 shot/tick 同约定）：tick_one 内的共享临时分数安全。
execute as @a at @s run function doom.consumable:throw/tick_one
