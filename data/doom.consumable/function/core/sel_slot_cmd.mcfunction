# doom.consumable:core/sel_slot_cmd [MACRO] —— 把"选中热键槽号"翻成可执行的槽位名
#
# 调用：execute if data storage doom.consumable:ctx sel.n run function doom.consumable:core/sel_slot_cmd with storage doom.consumable:ctx sel
# 前置：storage doom.consumable:ctx sel.n = 槽号（0..8）
# 产物：storage doom.consumable:ctx sel.cmd = "hotbar.N"
#
# 为什么要翻这一步：`item replace entity @s hotbar.N` 里的 N **只能是字面量**，
#   而槽号是运行时读出来的数（SelectedItemSlot / 快照里的 sel）⇒ 只能借宏做文本代换。
#
# ⚠ 槽号越界（不该发生）不要紧：拼出来的 hotbar.9 是非法的槽位名，
#   恢复链的守卫 `execute if items entity @s hotbar.9 …` 会跟着失败 ⇒ 判定降级成"目标槽位不可写"
#   ⇒ 走"找空槽 / 掉脚下"的兜底，物品不会丢。
$data modify storage doom.consumable:ctx sel.cmd set value "hotbar.$(n)"
