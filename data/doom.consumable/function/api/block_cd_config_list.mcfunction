# doom.consumable:api/block_cd_config_list —— 打印当前所有「方块类型冷却」配置
execute unless data storage doom.consumable:block_cd entries[0] run tellraw @s {"text":"[dc] 当前没有方块冷却配置","color":"gray"}
execute if data storage doom.consumable:block_cd entries[0] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[0]
execute if data storage doom.consumable:block_cd entries[1] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[1]
execute if data storage doom.consumable:block_cd entries[2] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[2]
execute if data storage doom.consumable:block_cd entries[3] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[3]
execute if data storage doom.consumable:block_cd entries[4] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[4]
execute if data storage doom.consumable:block_cd entries[5] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[5]
execute if data storage doom.consumable:block_cd entries[6] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[6]
execute if data storage doom.consumable:block_cd entries[7] run function doom.consumable:block/cfg_print with storage doom.consumable:block_cd entries[7]
