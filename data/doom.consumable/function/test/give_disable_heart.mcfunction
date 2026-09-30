# doom.consumable:test/give_disable_heart —— 3 次、0 秒使用、disable 模式的海洋之心
# 用法：/function doom.consumable:test/give_disable_heart
#
# 为什么用海洋之心而不是苹果：
#   · 原版海洋之心**没有** minecraft:consumable 组件，是我们自己用 loot table 写进补丁的 ——
#     正好用来验证 disable 分支处理"补丁提供的 consumable"这一路
#     （苹果的 consumable 来自物品原型，走的是 `!` 显式移除那一套；两者必须都能善终）
#   · consume_seconds 极短（0.05 = 1 tick）让它**不吃饥饿值也能近乎立刻用完** ——
#     测试循环从"啃苹果"变成"点右键"，而且不受饱食度干扰
#
# ⚠ 为什么不是 0 秒：实测 `consume_seconds: 0` 时物品右键后**直接消失**，不计数也不恢复 ——
#   探测量依赖 using_item 成就写快照，而它要求"使用中"状态存在**至少一 tick**；
#   0 秒时该状态从不出现 ⇒ 快照永远缺失 ⇒ 数量差恒为 0 ⇒ 检测不到。
#   静态规则 C5 会拦住这个组合（detect:"consume" + consume_seconds<=0）。
#
# 预期：
#   第 1~3 次右键：用掉、立刻回到手上，耐久条 3→2→1
#   第 4 次（耗尽）：物品**留在手上**（disable 模式不清手持）、耐久条变空、
#                   再右键**没有任何反应**（consumable 被彻底移除）
tellraw @s [{"text":"[dc] disable heart ×1（3 次 · 0.05 秒使用 · 耗尽后不可用）","color":"green"}]
loot give @s loot doom.consumable:items/disable_heart
