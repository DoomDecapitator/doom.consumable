# doom.consumable:test/give_recover_heart —— 冷却 + 回复条 的海洋之心
# 用法：/function doom.consumable:test/give_recover_heart
#
# 组件一览：
#   minecraft:max_damage        = 10        ← 「伪耐久条」10 格
#   minecraft:damage            = 0         ← 满格
#   minecraft:consumable        = 0.05 秒   ← 1 tick 用完（0 秒会检测不到，规则 C5）
#   minecraft:use_cooldown      = 5 秒      ← 原版冷却：5 秒内不能再点，快捷栏有灰罩
#   dc.on_use_damage            = 10        ← 用完把条清空（而不是保持满格）
#   dc.recover:1                           ← 让 recover/* 接管这条的回复
#   dc.type                     = infinite  ← 不限次数
#
# 预期时间线（每 0.5 秒涨一格；dc.recover_ticks: 10 ⇒ 10 格 × 0.5s = 5 秒回满，与 5 秒冷却同步）：
#   点右键 → 物品被消耗 → 立刻回到手上，**条瞬间变空** + 快捷栏出现 5 秒灰罩
#   0.5s → 9 格 …… 4.5s → 1 格 …… 5.0s → 满格，灰罩同时消失，可以再用
#   换句话说：条涨满 == 冷却结束，节奏完全对齐
#
# 回复怎么走（2026-09-27 改版后）：
#   · 计时状态**跟着物品自己走**：物品上带 dc.rb_cd（离下一格的剩余 tick），
#     所以主手 / 副手 / 背包**任何位置**都会继续回，换手、换槽、丢地上捡回来都不失步。
#   · 每 tick 逐槽扫描（recover/scan，36 槽 + 副手），**几件同时回复也各算各的**，不串台。
#   · 开关 #rb_bag dc.cfg：1（默认）= 连背包一起扫；0 = 只认手部（主手 + 副手）。
#
# ⚠ 旧的"优先级 主手 > 副手 > 背包"与"只在手上时推进"都已作废（那是玩家级计时器的老设计，
#   正是"两件同时在身上会串台/跳变"的病根）。
tellraw @s [{"text":"[dc] recover heart ×1（无限次 · 用完空条 · 5 秒回满 · 5 秒冷却）","color":"green"}]
loot give @s loot doom.consumable:items/recover_heart
