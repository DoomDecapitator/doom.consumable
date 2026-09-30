# doom.consumable:test/ghost_wipe —— 把现场恢复到"干净起步"
#
# 幽灵测试每一轮开头都会自动调一次。清三样：
#   · 残留中转体 item_display —— 上一次恢复没走到 kill 会留下它，而恢复用 limit=1 选实体，残留会抢
#   · 双手 —— 夹具紧接着会重新发一件，所以直接清空最干净
#     （⚠ 顺手也会清掉你手里原本拿着的**别的**东西，测之前先把手清空）
#   · 本玩家的诊断计数与三个计时器 —— 跨轮累计会让读数骗人；dc.diag 只在 /reload 归零，所以这里显式清
tellraw @s [{"text":"[PLC] 清场：中转体 + 双手 + 诊断计数","color":"gray"}]
kill @e[type=item_display,tag=dc_restore_tmp]
kill @e[type=item_display,tag=dc_tmp]
item replace entity @s weapon.mainhand with air
item replace entity @s weapon.offhand with air
scoreboard players set @s dc.restore_timer -1
scoreboard players set @s dc.consume_timer -1
scoreboard players set @s dc.discard_timer -1
scoreboard players set @s dc.off_prev -1
scoreboard players set @s dc.off_spike 0
scoreboard players set @s dc.off_spike_n 0
scoreboard players set @s dc.recover 0
function doom.consumable:test/diag_reset
