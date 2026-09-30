# doom.consumable:test/resync_off —— 关掉"客户端重同步"（默认状态）
scoreboard players set #resync dc.cfg 0
tellraw @s [{"text":"[PLC] 客户端重同步 = 关（恢复出来的与原物品逐字节相同）","color":"gray"}]
