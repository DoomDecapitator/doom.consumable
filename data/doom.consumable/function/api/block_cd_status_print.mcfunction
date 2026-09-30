# doom.consumable:api/block_cd_status_print [MACRO] —— status 的打印体
#
# 调用：function doom.consumable:api/block_cd_status_print with storage doom.consumable:ctx blk
# 参数：blk.key（设备名）· blk.sec（冷却秒数）· blk.left（剩余 tick，负数 = 已就绪）· blk.count（已激活次数）
$tellraw @s [{"text":"[dc] 设备 ","color":"gray"},{"text":"$(key)","color":"white"},{"text":" · 每 $(sec) 秒可用","color":"gray"},{"text":" · 剩余 $(left) tick","color":"yellow"},{"text":" · 已激活 ","color":"gray"},{"text":"$(count)","color":"white"},{"text":" 次","color":"gray"}]
