# doom.consumable:shot/refund_give [MACRO] —— 箭补回（参数源 ctx.shot.refund，需要 id）
# 已知限制：背包满时 give 静默失败（箭不补回，不报错）——设计文档 §九。
$give @s $(id) 1
