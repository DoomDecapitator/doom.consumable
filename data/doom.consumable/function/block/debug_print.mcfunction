# doom.consumable:block/debug_print [MACRO] —— 调试摘要（blk.ready / blk.cool / blk.dist）
$tellraw @s [{"text":"[dc] 16 格内设备：","color":"gray"},{"text":"$(ready) 就绪","color":"green"},{"text":" / ","color":"gray"},{"text":"$(cool) 冷却中","color":"red"},{"text":"（绿粒子=就绪，红粒子=冷却中）","color":"dark_gray"}]
