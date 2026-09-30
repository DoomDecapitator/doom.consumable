# doom.consumable:rod/deny_sound [MACRO] —— 否决音效
#
# 调用：function doom.consumable:rod/deny_sound with storage doom.consumable:ctx rod_fb
#       （rod_fb.sound = 音效 id，来自物品的 dc.rod_deny_sound，例 "minecraft:block.note_block.bass"）
$playsound $(sound) master @s ~ ~ ~ 1 1
