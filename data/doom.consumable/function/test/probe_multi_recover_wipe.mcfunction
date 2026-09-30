# doom.consumable:test/probe_multi_recover_wipe —— 清掉 probe_multi_recover 布置的两件
# 用法：/function doom.consumable:test/probe_multi_recover_wipe
tellraw @s [{"text":"[RB] 清掉 hotbar.8 与 inventory.0（探针布置的那两件）","color":"gray"}]
item replace entity @s hotbar.8 with air
item replace entity @s inventory.0 with air
kill @e[type=item_display,tag=dc_rb]
data remove storage doom.consumable:ctx rb.item
data remove storage doom.consumable:ctx args
