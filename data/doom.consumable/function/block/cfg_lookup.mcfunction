# doom.consumable:block/cfg_lookup —— 按方块类型匹配配置（最多 8 条，逐条尝试，命中即停）
#
# 配置存放：storage doom.consumable:block_cd.entries，每条形如
#   {tag:"<方块标签>",seconds:30,key:"<名字>",ready:"<就绪形态或 ->",cooling:"<冷却形态或 ->"}
# 执行位置必须是「被交互的那个方块」（found_block 之前已 align xyz ⇒ 这里直接用 ~ ~ ~ 判定）。
execute if data storage doom.consumable:block_cd entries[0] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[0]
execute if data storage doom.consumable:block_cd entries[1] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[1]
execute if data storage doom.consumable:block_cd entries[2] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[2]
execute if data storage doom.consumable:block_cd entries[3] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[3]
execute if data storage doom.consumable:block_cd entries[4] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[4]
execute if data storage doom.consumable:block_cd entries[5] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[5]
execute if data storage doom.consumable:block_cd entries[6] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[6]
execute if data storage doom.consumable:block_cd entries[7] run function doom.consumable:block/cfg_try with storage doom.consumable:block_cd entries[7]
