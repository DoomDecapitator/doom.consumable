# doom.consumable:block/deny_msg [MACRO] —— 设备自带的否决提示（data.dc.cd_deny_msg）
#
# 调用：function doom.consumable:block/deny_msg with storage doom.consumable:ctx block（block.msg = 文本）
$tellraw @s [{"text":"$(msg)","color":"red"}]
