# doom.consumable:api/block_cd_config_clear —— 清空所有「方块类型冷却」配置（已生成的设备不受影响）
data modify storage doom.consumable:block_cd entries set value []
tellraw @s {"text":"[dc] 方块冷却配置已清空","color":"gray"}
