# doom.consumable:rod/deny_msg [MACRO] —— 否决提示文本
#
# 调用：function doom.consumable:rod/deny_msg with storage doom.consumable:ctx rod_fb
#       （rod_fb.msg = 要显示的文本，来自物品的 dc.rod_deny_message）
# ⚠ 宏替换会**剥掉 NBT 字符串的引号** ⇒ 模板里的引号必须自己写，参数给裸文本。
$tellraw @s [{"text":"$(msg)","color":"red"}]
