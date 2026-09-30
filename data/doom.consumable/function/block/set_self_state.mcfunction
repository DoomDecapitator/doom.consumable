# doom.consumable:block/set_self_state [MACRO] —— 把「执行位置所在方块」换成 blk.state（供 restore_ready 用）
$setblock ~ ~ ~ $(state)
