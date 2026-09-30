# doom.consumable:rod/writeback [MACRO] —— 把 storage 里的 rod.item 写回玩家手上
#
# 调用：function doom.consumable:rod/writeback with storage doom.consumable:ctx rod
# 前置：rod.item 已按需改好；rod.slot = 目标槽位（weapon.mainhand / weapon.offhand）
# 注意：本函数要求执行者是**玩家本人**（item replace entity @s …）
#
# 手法：中转体（item_display）＋ `item replace … from entity … contents`
#   —— 玩家背包**不能**用 data modify 写（引擎限制，本项目多处已钉），只能靠 item replace。
#   tag 用本流程专用的 dc_rod_tmp，并先无条件清残留（与 restore/do_restore 同一纪律：
#   上一次若中途失败留下中转体，`limit=1` 是"最近的那个"、可能选中它 ⇒ 写出别人的物品）。
kill @e[type=item_display,tag=dc_rod_tmp]
summon minecraft:item_display ~ ~ ~ {Tags:["dc_item","dc_rod_tmp"],item:{id:"minecraft:stone",count:1}}
data modify entity @e[type=item_display,tag=dc_rod_tmp,limit=1] item set from storage doom.consumable:ctx rod.item
$item replace entity @s $(slot) from entity @e[type=item_display,tag=dc_rod_tmp,limit=1] contents
kill @e[type=item_display,tag=dc_rod_tmp]
data remove storage doom.consumable:ctx rod
