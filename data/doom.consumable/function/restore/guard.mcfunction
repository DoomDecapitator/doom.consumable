# doom.consumable:restore/guard [MACRO] —— 目标槽位能不能安全写入？
#
# 调用：function doom.consumable:restore/guard with storage doom.library:io output[-1].data.CACHE.consumable.data
#       （丢弃链用 …data.CACHE.discard.data —— 本文件与缓存路径无关，只认参数）
# 宏参数：$(slot_cmd) 目标槽位名（hotbar.N / weapon.mainhand / weapon.offhand）、$(id) 物品 id
# 产出：#can dc.temp = 1 能写（槽位是空的 **或** 里面还是同一件）；0 = 被别的东西占了
#
# 为什么要这一层（2026-09-27，玩家报障「频繁切换物品使用会吞物品」）：
#   `item replace entity @s <slot> …` 是**无条件替换**。恢复的落点旧版写死 `weapon.mainhand`
#   （= 当前选中那一格），而消耗到恢复之间隔着 1~2 tick —— 玩家换个槽，恢复就把新槽里的东西抹掉。
#   判定"空或同一件"正好覆盖两种正常情况：
#     · max_stack_size=1 的物品用完槽位是空的 → 判定为"空" → 直接写回
#     · 一叠没用完（原版扣了 1）→ 槽里还是同一件 → 直接写回（把那 1 补回去）
#   其它情况一律交给 restore/put_anywhere，绝不覆盖。
#
# ⚠ 参数缺失（旧缓存 / 手工构造的缓存）时两条 $ 行会失败 ⇒ #can 保持 0 ⇒ 调用方走兜底。
#   这是**刻意**的保守选择：宁可换个地方放，也不能覆盖玩家手里的东西。
scoreboard players set #can dc.temp 0
$execute unless items entity @s $(slot_cmd) * run scoreboard players set #can dc.temp 1
$execute if items entity @s $(slot_cmd) $(id) run scoreboard players set #can dc.temp 1
