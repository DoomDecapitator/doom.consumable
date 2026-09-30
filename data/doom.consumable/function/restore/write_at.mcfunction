# doom.consumable:restore/write_at [MACRO] —— 把中转体那件写回目标槽位
#
# 调用：function doom.consumable:restore/write_at with storage doom.library:io output[-1].data.CACHE.consumable.data
# 前置：调用方已经用 restore/guard 判定过 #can = 1（槽位为空 或 还是同一件）——
#       本文件**不做任何判定**，它的唯一职责就是把"槽位名"这个字面量做成宏参数。
$item replace entity @s $(slot_cmd) from entity @e[type=item_display,tag=dc_restore_tmp,limit=1] contents
