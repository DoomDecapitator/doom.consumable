# doom.consumable:recover/slot [MACRO] —— 处理"第 $(i) 槽"那件物品
#
# 调用：由 recover/scan 的每槽守卫行调用
#        function doom.consumable:recover/slot with storage doom.consumable:ctx args
# 宏参数（由 scan 摆平，宏只能读扁平键）：$(i) 槽号 / $(name) 可执行槽位名 / $(slot) 诊断游标编码
#
# 三行各司其职：
#   ① 诊断游标：把"这一 tick 动的是哪一槽"写进 @s dc.rb_slot（探针/套件靠它判读；
#      真正的落点由 $(name) 决定，不再是"按游标翻译槽位"）
#   ② 取件：把那槽那件的 NBT 复制到 storage rb.item（recover/hit 只认这一个数据源）
#   ③ 交给 recover/hit：读 damage/间隔/倒计时 → 该动才动 → 写回 $(name)
#
# ⚠ 用 `Inventory[{Slot:$(i)b}]` 精确取那一槽：玩家背包条目自带 Slot 字段，
#   而 NBT 过滤器能一次取出命中的那件 —— "过滤器可以读/取"是 2026-09-11 用探针 A1–A7
#   证伪旧结论之后钉下的事实（唯一不能做的是"过滤器之后再接 [0] 索引"，这里不需要）。
#   Slot 是 **byte**（`Slot:12b`），所以判据必须带 `b`（lint 规则 C12）。
$scoreboard players set @s dc.rb_slot $(slot)
$data modify storage doom.consumable:ctx rb.item set from entity @s Inventory[{Slot:$(i)b}]
function doom.consumable:recover/hit with storage doom.consumable:ctx args
