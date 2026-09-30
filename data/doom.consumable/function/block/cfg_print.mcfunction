# doom.consumable:block/cfg_print [MACRO] —— 单条配置的打印体
$tellraw @s [{"text":"  · ","color":"dark_gray"},{"text":"$(tag)","color":"white"},{"text":" 每 $(seconds) 秒","color":"gray"},{"text":"（key=$(key) · 就绪=$(ready) · 冷却=$(cooling)）","color":"dark_gray"}]
