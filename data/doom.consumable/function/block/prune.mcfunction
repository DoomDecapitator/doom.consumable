# doom.consumable:block/prune —— 清理「长期闲置」的自动设备（显式设备不动）
#
# 判据：自动设备（tag dc.block_cd_auto）且 cd_ready 已过期 600 tick（30 秒）以上 ⇒ 删掉。
# 意义：正常运行里只有「最近用过」的方块位置留一个 marker，不会把世界堆满实体。
# 注意：删掉后该设备的 cd_count（激活次数）会丢 —— 需要长期统计的请用显式设备。
execute as @e[type=minecraft:marker,tag=dc.block_cd_auto] at @s run function doom.consumable:block/prune_one
